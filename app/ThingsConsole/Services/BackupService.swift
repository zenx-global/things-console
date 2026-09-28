import AppKit
import Foundation

/// 一份备份的元信息
struct BackupEntry {
    let url: URL
    let name: String
    let date: Date
    let itemCount: Int
}

/// 备份 / 导出 / 恢复。
/// 备份格式：文件夹内 items.json（与 PhotoStore 相同的 Codable 结构）+ Photos/ 照片副本，
/// 可整体拷走、可从任意机器恢复——完全离线、无格式私锁。
enum BackupService {

    private static let defaults = UserDefaults.standard
    private static let autoDateKey = "things-console.autobackup.date.v1"
    private static let autoEnabledKey = "things-console.autobackup.enabled.v1"
    private static let retention = 10

    static var backupRoot: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("ThingsConsole/Backups", isDirectory: true)
    }()

    // MARK: - 自动备份

    static var autoBackupEnabled: Bool {
        get { defaults.object(forKey: autoEnabledKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: autoEnabledKey) }
    }

    static func lastAutoBackupDate() -> Date? {
        defaults.object(forKey: autoDateKey) as? Date
    }

    /// 每个自然日首次启动时备份一次（后台队列调用）
    @discardableResult
    static func autoBackupIfNeeded(items: [AssetItem]) -> URL? {
        let cal = Calendar.current
        if let last = lastAutoBackupDate(), cal.isDate(last, inSameDayAs: Date()) {
            return nil
        }
        guard let url = makeBackup(items: items, isAuto: true) else { return nil }
        defaults.set(Date(), forKey: autoDateKey)
        pruneOldBackups()
        return url
    }

    // MARK: - 创建备份

    /// 写出一份完整备份（items.json + Photos/）。线程安全：纯文件操作。
    @discardableResult
    static func makeBackup(items: [AssetItem], isAuto: Bool, boxesFile: URL = BoxStore.dataFileURL) -> URL? {
        let fm = FileManager.default
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let prefix = isAuto ? "auto" : "backup"
        let dir = backupRoot.appendingPathComponent("\(prefix)-\(formatter.string(from: Date()))", isDirectory: true)
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(items)
            try data.write(to: dir.appendingPathComponent("items.json"), options: .atomic)
            let photoDir = dir.appendingPathComponent("Photos", isDirectory: true)
            try fm.createDirectory(at: photoDir, withIntermediateDirectories: true)
            for item in items {
                for photo in item.photos {
                    let src = PhotoStore.directory.appendingPathComponent(photo.fileName)
                    let dest = photoDir.appendingPathComponent(photo.fileName)
                    if fm.fileExists(atPath: src.path), !fm.fileExists(atPath: dest.path) {
                        try fm.copyItem(at: src, to: dest)
                    }
                }
            }
            if fm.fileExists(atPath: boxesFile.path) {
                try? fm.copyItem(at: boxesFile, to: dir.appendingPathComponent("boxes.json"))
            }
            return dir
        } catch {
            return nil
        }
    }

    /// 保留最近 N 份
    private static func pruneOldBackups() {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(at: backupRoot, includingPropertiesForKeys: nil) else { return }
        let sorted = dirs.sorted { $0.lastPathComponent > $1.lastPathComponent }
        for url in sorted.dropFirst(retention) {
            try? fm.removeItem(at: url)
        }
    }

    // MARK: - 备份历史

    static func listBackups() -> [BackupEntry] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(at: backupRoot, includingPropertiesForKeys: [.contentModificationDateKey]) else { return [] }
        return dirs.compactMap { url in
            guard isBackupFolder(url) else { return nil }
            let count = (try? importItems(from: url))?.count ?? 0
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            return BackupEntry(url: url, name: url.lastPathComponent, date: date, itemCount: count)
        }
        .sorted { $0.date > $1.date }
    }

    static func isBackupFolder(_ url: URL) -> Bool {
        fmFileExists(url.appendingPathComponent("items.json"))
    }

    private static func fmFileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: - 导入恢复

    /// 从备份文件夹读回物品档案（照片文件由调用方 replaceAll 复制）
    static func importItems(from backupDir: URL) throws -> [AssetItem] {
        let data = try Data(contentsOf: backupDir.appendingPathComponent("items.json"))
        return try JSONDecoder().decode([AssetItem].self, from: data)
    }

    /// 读回箱台账；旧备份没有 boxes.json 时返回 nil（调用方保留现有箱子，不清空）
    static func importBoxes(from backupDir: URL) -> [CleanupBox]? {
        let url = backupDir.appendingPathComponent("boxes.json")
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([CleanupBox].self, from: data)
    }

    // MARK: - 导出

    /// 导出完整备份到用户指定文件夹
    static func exportBundle(items: [AssetItem], to directory: URL, boxesFile: URL = BoxStore.dataFileURL) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let dir = directory.appendingPathComponent("things-backup-\(formatter.string(from: Date()))", isDirectory: true)
        let fm = FileManager.default
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(items)
        try data.write(to: dir.appendingPathComponent("items.json"), options: .atomic)
        let photoDir = dir.appendingPathComponent("Photos", isDirectory: true)
        try fm.createDirectory(at: photoDir, withIntermediateDirectories: true)
        for item in items {
            for photo in item.photos {
                let src = PhotoStore.directory.appendingPathComponent(photo.fileName)
                if fmFileExists(src) {
                    try? fm.copyItem(at: src, to: photoDir.appendingPathComponent(photo.fileName))
                }
            }
        }
        if fm.fileExists(atPath: boxesFile.path) {
            try? fm.copyItem(at: boxesFile, to: dir.appendingPathComponent("boxes.json"))
        }
        return dir
    }

    // MARK: - CSV 导出

    static func exportCSV(items: [AssetItem]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        func dateText(_ date: Date?) -> String {
            date.map(formatter.string(from:)) ?? ""
        }

        var rows: [[String]] = [[
            "名称", "分类", "品牌/型号", "存放位置", "状态", "数量",
            "单价", "小计", "购入日期", "购买渠道", "质保到期", "到期日", "备注", "录入时间",
        ]]
        for item in items.sorted(by: { $0.createdAt < $1.createdAt }) {
            rows.append([
                item.name, item.category, item.brand, item.location, item.status.rawValue,
                String(item.quantity),
                String(item.purchasePrice), String(item.totalValue),
                dateText(item.purchaseDate), item.purchaseChannel,
                dateText(item.warrantyUntil), dateText(item.expiresAt),
                item.notes, dateText(item.createdAt),
            ])
        }
        var csv = rows.map { row in
            row.map { field in
                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                return (escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n"))
                    ? "\"\(escaped)\"" : escaped
            }
            .joined(separator: ",")
        }
        .joined(separator: "\n")
        // BOM：让 Excel 正确识别 UTF-8 中文
        csv = "\u{FEFF}" + csv
        return csv
    }

    // MARK: - 系统面板（主线程调用）

    @MainActor
    static func chooseDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "选择文件夹"
        return panel.runModal() == .OK ? panel.url : nil
    }

    @MainActor
    static func runSavePanel(suggestedName: String) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
