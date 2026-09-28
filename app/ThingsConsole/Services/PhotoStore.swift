import AppKit
import Foundation

/// 照片文件存取。图片实体只存文件名，数据落盘到 Application Support/ThingsConsole/Photos。
enum PhotoStore {

    static let directory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ThingsConsole/Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// 保存图片数据：重绘压缩为 JPEG（最长边 1600px，控制体积），返回照片记录
    static func save(data: Data) -> ItemPhoto? {
        guard let source = NSImage(data: data) else { return nil }
        let jpeg = jpegData(from: source, maxDimension: 1600, quality: 0.82)
        let photo = ItemPhoto(fileName: "\(UUID().uuidString).jpg")
        let url = directory.appendingPathComponent(photo.fileName)
        do {
            try jpeg.write(to: url)
            return photo
        } catch {
            return nil
        }
    }

    static func load(_ photo: ItemPhoto) -> NSImage? {
        NSImage(contentsOf: directory.appendingPathComponent(photo.fileName))
    }

    static func delete(_ photos: [ItemPhoto]) {
        for photo in photos {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(photo.fileName))
        }
    }

    /// 回收不再被任何物品引用的孤儿文件（表单取消、移除照片后遗留），启动时调用
    static func collectGarbage(referencedFileNames: Set<String>) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for url in files where !referencedFileNames.contains(url.lastPathComponent) {
            try? fm.removeItem(at: url)
        }
    }

    /// 缩略图（等比缩放到指定像素），列表行使用，避免全尺寸解码
    static func thumbnail(_ photo: ItemPhoto, maxPixel: CGFloat) -> NSImage? {
        guard let image = load(photo) else { return nil }
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxPixel, longest > 0 else { return image }
        let scale = maxPixel / longest
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        guard let rep = render(image, to: newSize, background: nil) else { return image }
        let result = NSImage(size: newSize)
        result.addRepresentation(rep)
        return result
    }

    // MARK: - 绘制辅助

    /// 把 NSImage 重绘进一张指定尺寸的位图，返回可编码的 rep
    private static func render(_ image: NSImage, to size: NSSize, background: NSColor?) -> NSBitmapImageRep? {
        guard size.width > 0, size.height > 0 else { return nil }
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(size.width),
                                         pixelsHigh: Int(size.height),
                                         bitsPerSample: 8,
                                         samplesPerPixel: 4,
                                         hasAlpha: true,
                                         isPlanar: false,
                                         colorSpaceName: .calibratedRGB,
                                         bytesPerRow: 0,
                                         bitsPerPixel: 0) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState()
            return nil
        }
        NSGraphicsContext.current = context
        let rect = NSRect(origin: .zero, size: size)
        if let background {
            background.setFill()
            rect.fill()
        }
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    private static func jpegData(from image: NSImage, maxDimension: CGFloat, quality: CGFloat) -> Data {
        var size = image.size
        let longest = max(size.width, size.height)
        if longest > maxDimension, longest > 0 {
            let scale = maxDimension / longest
            size = NSSize(width: size.width * scale, height: size.height * scale)
        }
        return render(image, to: size, background: .white)?
            .representation(using: .jpeg, properties: [.compressionFactor: quality]) ?? Data()
    }
}
