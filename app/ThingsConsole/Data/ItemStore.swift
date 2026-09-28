import Foundation
import SwiftUI

/// 物品台账的持久化与状态管理。
/// v2 起数据落盘 Application Support/ThingsConsole/items.json（原子写入，便于备份/迁移），
/// v1 的 UserDefaults 数据首次启动自动迁移；照片文件仍由 PhotoStore 管。
@MainActor
final class ItemStore: ObservableObject {

    @Published private(set) var items: [AssetItem] = []
    @Published private(set) var lastBackupDate: Date?

    /// 数据文件存在但无法解析。此时禁止 GC / 覆盖写 / 自动备份，等待用户从备份恢复。
    @Published private(set) var dataCorruptionDetected = false
    @Published private(set) var quarantinedFileURL: URL?

    /// 快速录入记忆：上次使用的分类与位置，回车连录时自动带上
    @Published var quickCategory: String = CategoryStore.fallbackName {
        didSet { persistQuickPrefs() }
    }
    @Published var quickLocation: String = "" {
        didSet { persistQuickPrefs() }
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let legacyKey = "things-console.items.v1"       // v1：UserDefaults
    private let quickPrefsKey = "things-console.quickentry.v1"

    /// 主数据文件（v2）
    nonisolated static let dataFileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ThingsConsole", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("items.json")
    }()

    init(fileURL: URL = ItemStore.dataFileURL) {
        self.fileURL = fileURL
        load()
        migrateLegacyIfNeeded()
        loadQuickPrefs()
        lastBackupDate = BackupService.lastAutoBackupDate()
        if !dataCorruptionDetected {
            PhotoStore.collectGarbage(
                referencedFileNames: Set(items.flatMap { item in item.photos.map(\.fileName) })
            )
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                persist()
            }
            scheduleAutoBackup()
        }
    }

    private let fileURL: URL

    // MARK: - 读取 / 持久化（原子写入）

    private func load() {
        // 文件不存在 = 正常首次启动；存在但解析失败 = 损坏，进入保护态
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            items = try decoder.decode([AssetItem].self, from: data)
        } catch {
            quarantineCorruptFile()
        }
    }

    /// 把损坏文件复制一份带时间戳的隔离副本，原文件保持原样等待人工检查
    private func quarantineCorruptFile() {
        dataCorruptionDetected = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let target = fileURL.appendingPathExtension("corrupt-\(formatter.string(from: Date()))")
        if (try? FileManager.default.copyItem(at: fileURL, to: target)) != nil {
            quarantinedFileURL = target
        }
    }

    /// 从备份成功恢复后解除保护态
    func resolveCorruption() {
        dataCorruptionDetected = false
        quarantinedFileURL = nil
    }

    private func persist() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// v1 UserDefaults 数据 → v2 文件，迁移后清除旧 key
    private func migrateLegacyIfNeeded() {
        guard !dataCorruptionDetected, items.isEmpty,
              let data = UserDefaults.standard.data(forKey: legacyKey),
              let legacy = try? decoder.decode([AssetItem].self, from: data) else { return }
        items = legacy
        persist()
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    // MARK: - 快速录入偏好

    private func persistQuickPrefs() {
        let prefs: [String: String] = ["category": quickCategory, "location": quickLocation]
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: quickPrefsKey)
        }
    }

    private func loadQuickPrefs() {
        guard let data = UserDefaults.standard.data(forKey: quickPrefsKey),
              let prefs = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        if let category = prefs["category"], !category.isEmpty { quickCategory = category }
        if let location = prefs["location"] { quickLocation = location }
    }

    // MARK: - CRUD

    func add(_ item: AssetItem) {
        rememberQuickPrefs(from: item)
        items.insert(item, at: 0)
        persist()
    }

    func update(_ item: AssetItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.updatedAt = Date()
        items[idx] = updated
        rememberQuickPrefs(from: updated)
        persist()
    }

    func delete(_ item: AssetItem) {
        items.removeAll { $0.id == item.id }
        PhotoStore.delete(item.photos)
        persist()
    }

    /// 极速录入：只用名称，其余字段取快速录入记忆
    @discardableResult
    func quickAdd(name: String) -> AssetItem {
        let item = AssetItem(name: name,
                             category: quickCategory,
                             location: quickLocation,
                             status: .inUse)
        add(item)
        return item
    }

    private func rememberQuickPrefs(from item: AssetItem) {
        if !item.category.isEmpty { quickCategory = item.category }
        quickLocation = item.location
    }

    // MARK: - 状态流转 / 数量快调

    func setStatus(_ status: ItemStatus, for id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].status = status
        items[idx].retiredAt = status == .retired ? Date() : nil
        items[idx].updatedAt = Date()
        persist()
    }

    func adjustQuantity(_ delta: Int, for id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].quantity = max(1, items[idx].quantity + delta)
        persist()
    }

    // MARK: - 箱子清理（P0）

    func items(inBox boxId: UUID) -> [AssetItem] {
        items.filter { $0.sourceBoxId == boxId }
    }

    func setDisposition(_ disposition: ItemDisposition?, for itemId: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].disposition = disposition
        items[idx].updatedAt = Date()
        persist()
    }

    func setCategory(_ category: String, for itemId: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].category = category
        items[idx].updatedAt = Date()
        persist()
    }

    func setLocation(_ location: String, for itemId: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].location = location
        items[idx].updatedAt = Date()
        persist()
    }

    func assignToBox(_ boxId: UUID?, itemId: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].sourceBoxId = boxId
        items[idx].updatedAt = Date()
        persist()
    }

    func batchSetDisposition(_ disposition: ItemDisposition?, for itemIds: [UUID]) {
        let idSet = Set(itemIds)
        var changed = false
        for idx in items.indices where idSet.contains(items[idx].id) {
            items[idx].disposition = disposition
            items[idx].updatedAt = Date()
            changed = true
        }
        if changed { persist() }
    }

    /// 箱内极速录入：名称 + 处置，自动带上箱 ID 与快速录入记忆
    @discardableResult
    func quickAddInBox(name: String, boxId: UUID, disposition: ItemDisposition? = nil) -> AssetItem {
        let item = AssetItem(name: name,
                             category: quickCategory,
                             location: quickLocation,
                             status: .inUse,
                             sourceBoxId: boxId,
                             disposition: disposition)
        add(item)
        return item
    }

    // MARK: - 分类维护（分类管理面板用）

    func usageCount(ofCategory name: String) -> Int {
        items.lazy.filter { $0.category == name }.count
    }

    /// 分类改名 / 删除迁移时，批量更新物品档案
    func migrateCategory(_ from: String, to target: String) {
        guard from != target else { return }
        var changed = false
        for idx in items.indices where items[idx].category == from {
            items[idx].category = target
            items[idx].updatedAt = Date()
            changed = true
        }
        if changed {
            if quickCategory == from { quickCategory = target }
            persist()
        }
    }

    // MARK: - 导入恢复

    /// 用备份整体替换台账，并从备份文件夹补齐缺失的照片文件。
    /// 替换前自动为当前数据做一份快照——「先备份再恢复」由代码保证，不靠用户记得。
    @discardableResult
    func replaceAll(_ newItems: [AssetItem], copyingPhotosFrom backupDir: URL?) -> Int {
        if !dataCorruptionDetected, !items.isEmpty {
            BackupService.makeBackup(items: items, isAuto: false)
        }
        let fm = FileManager.default
        for item in newItems {
            for photo in item.photos {
                let dest = PhotoStore.directory.appendingPathComponent(photo.fileName)
                guard !fm.fileExists(atPath: dest.path) else { continue }
                if let backupDir {
                    let src = backupDir.appendingPathComponent("Photos", isDirectory: true)
                        .appendingPathComponent(photo.fileName)
                    try? fm.copyItem(at: src, to: dest)
                }
            }
        }
        items = newItems
        persist()
        resolveCorruption()
        PhotoStore.collectGarbage(
            referencedFileNames: Set(items.flatMap { item in item.photos.map(\.fileName) })
        )
        return items.count
    }

    // MARK: - Excel 导入

    /// 应用 Excel 导入计划：有变更时先自动快照（「先备份再变更」约定），再批量更新 / 新增。
    @discardableResult
    func applySpreadsheetImport(_ plan: ImportPlan) -> (updated: Int, inserted: Int) {
        if !plan.isEmpty, !items.isEmpty {
            BackupService.makeBackup(items: items, isAuto: false)
        }
        for update in plan.updates {
            guard let index = items.firstIndex(where: { $0.id == update.existing.id }) else { continue }
            items[index] = update.newValue
        }
        if !plan.inserts.isEmpty {
            items.insert(contentsOf: plan.inserts, at: 0)
        }
        persist()
        return (plan.updates.count, plan.inserts.count)
    }

    // MARK: - 备份联动

    private func scheduleAutoBackup() {
        guard BackupService.autoBackupEnabled else { return }
        let snapshot = items
        DispatchQueue.global(qos: .utility).async {
            BackupService.autoBackupIfNeeded(items: snapshot)
            DispatchQueue.main.async {
                self.lastBackupDate = BackupService.lastAutoBackupDate()
            }
        }
    }

    /// 手动立即备份（主线程调用，返回备份文件夹）
    @discardableResult
    func backupNow() -> URL? {
        let url = BackupService.makeBackup(items: items, isAuto: false)
        lastBackupDate = BackupService.lastAutoBackupDate()
        return url
    }

    // MARK: - 派生数据（看板 / 库存页口径）

    /// 在用 + 闲置（资产口径）
    var activeItems: [AssetItem] {
        items.filter { $0.status != .retired }
    }

    var retiredItems: [AssetItem] {
        items.filter { $0.status == .retired }
    }

    var totalActiveValue: Double {
        activeItems.reduce(0) { $0 + $1.totalValue }
    }

    /// 到期预警：≤30 天或已过期，按日期升序
    var expiringSoon: [AssetItem] {
        activeItems
            .filter { item in
                guard let days = item.daysUntilExpiry else { return false }
                return days <= 30
            }
            .sorted { ($0.expiresAt ?? .distantFuture) < ($1.expiresAt ?? .distantFuture) }
    }

    /// 质保将过期：0...30 天（已过保不再提醒）
    var warrantyExpiringSoon: [AssetItem] {
        activeItems
            .filter { item in
                guard let days = item.daysUntilWarrantyEnd else { return false }
                return (0...30).contains(days)
            }
            .sorted { ($0.warrantyUntil ?? .distantFuture) < ($1.warrantyUntil ?? .distantFuture) }
    }

    var idleItems: [AssetItem] {
        items.filter { $0.status == .idle }
    }

    var recentItems: [AssetItem] {
        items.sorted { $0.createdAt > $1.createdAt }
    }

    /// 按 category 聚合的资产价值（降序）
    var valueByCategory: [(category: String, value: Double)] {
        Dictionary(grouping: activeItems, by: \.category)
            .map { (category: $0.key.isEmpty ? "未分类" : $0.key, value: $0.value.reduce(0) { $0 + $1.totalValue }) }
            .sorted { $0.value > $1.value }
    }

    func item(id: UUID) -> AssetItem? {
        items.first { $0.id == id }
    }

    // MARK: - 数据概览

    static func photoDiskUsage() -> (count: Int, bytes: Int64) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: PhotoStore.directory, includingPropertiesForKeys: [.fileSizeKey]) else { return (0, 0) }
        var total: Int64 = 0
        for url in files {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        return (files.count, total)
    }
}
