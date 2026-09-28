import AppKit
import SwiftUI

/// 照片缩略图组件：各页共用。onAppear 时按需加载并缩放一次，避免每帧全尺寸解码。
struct PhotoThumbView: View {
    let photo: ItemPhoto
    var width: CGFloat = 48
    var height: CGFloat = 36
    var maxPixel: CGFloat = 96

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: width, height: height)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary, lineWidth: 0.5))
        .onAppear {
            if image == nil {
                image = PhotoStore.thumbnail(photo, maxPixel: maxPixel)
            }
        }
    }
}

/// 无照片时的占位块
struct PhotoPlaceholderView: View {
    var width: CGFloat = 48
    var height: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
            Image(systemName: "photo")
                .foregroundStyle(.tertiary)
        }
        .frame(width: width, height: height)
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary, lineWidth: 0.5))
    }
}
