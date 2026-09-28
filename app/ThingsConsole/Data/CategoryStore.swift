import Foundation

/// 分类注册表：预设 + 用户自建，持久化到 Application Support/ThingsConsole/categories.json。
/// 内置预设只增不删（向前兼容）；用户删除的内置分类记入墓碑，重启不会复活。
@MainActor
final class CategoryStore: ObservableObject {

    /// 预设分类：参照 KonMari 五大类的「文件 / 纪念品」维度与资产管理视角整理。
    /// 顺序即推荐整理顺序：贴身 → 空间 → 电子 → 饮食 → 知识证件 → 活动 → 其他。
    static let builtIn: [ItemCategory] = [
        .init(name: "服饰鞋包", emoji: "👕"),
        .init(name: "美妆个护", emoji: "💄"),
        .init(name: "清洁用品", emoji: "🧴"),
        .init(name: "家具家居", emoji: "🛋️"),
        .init(name: "家用电器", emoji: "📺"),
        .init(name: "数码电子", emoji: "💻"),
        .init(name: "数码配件", emoji: "🔌"),
        .init(name: "厨房餐饮", emoji: "🍳"),
        .init(name: "食品药品", emoji: "💊"),
        .init(name: "图书文具", emoji: "📚"),
        .init(name: "文件证件", emoji: "📄"),
        .init(name: "运动户外", emoji: "🏀"),
        .init(name: "工具设备", emoji: "🔧"),
        .init(name: "母婴玩具", emoji: "🧸"),
        .init(name: "宠物用品", emoji: "🐾"),
        .init(name: "出行收纳", emoji: "🧳"),
        .init(name: "纪念收藏", emoji: "🎁"),
        .init(name: "其他", emoji: "📦"),
    ]

    static let fallbackName = "其他"
    static let defaultEmoji = "📦"

    @Published private(set) var categories: [ItemCategory]

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private struct Envelope: Codable {
        var categories: [ItemCategory]
        var removedBuiltIns: [String]
    }

    nonisolated static var defaultFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ThingsConsole", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("categories.json")
    }

    init(fileURL: URL = CategoryStore.defaultFileURL) {
        self.fileURL = fileURL
        var saved: [ItemCategory] = []
        var removed: [String] = []
        if let data = try? Data(contentsOf: fileURL),
           let envelope = try? decoder.decode(Envelope.self, from: data) {
            saved = envelope.categories
            removed = envelope.removedBuiltIns
        }
        if saved.isEmpty {
            saved = Self.builtIn
        } else {
            // 新版本补充的内置预设自动并入（已被用户删除的除外）
            for preset in Self.builtIn
            where !removed.contains(preset.name) && !saved.contains(where: { $0.name == preset.name }) {
                saved.append(preset)
            }
        }
        categories = saved
        persist(removedBuiltIns: removed)
    }

    // MARK: - 查询

    func contains(name: String) -> Bool {
        categories.contains { $0.name == name }
    }

    func emoji(for name: String) -> String {
        categories.first { $0.name == name }?.emoji ?? Self.defaultEmoji
    }

    // MARK: - 增删改

    /// 新增分类；重名或空名返回 false
    @discardableResult
    func add(name: String, emoji: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !contains(name: trimmed) else { return false }
        categories.append(ItemCategory(name: trimmed, emoji: trimmedEmoji.isEmpty ? Self.defaultEmoji : trimmedEmoji))
        persist(removedBuiltIns: nil)
        return true
    }

    /// 重命名 / 换图标；重名或空名返回 false
    @discardableResult
    func rename(name: String, to newName: String, emoji: String) -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let idx = categories.firstIndex(where: { $0.name == name }),
              trimmed == name || !contains(name: trimmed) else { return false }
        categories[idx] = ItemCategory(name: trimmed,
                                       emoji: trimmedEmoji.isEmpty ? categories[idx].emoji : trimmedEmoji)
        persist(removedBuiltIns: nil)
        return true
    }

    /// 删除分类（调用方负责把该分类下的物品迁走）
    func remove(name: String) {
        categories.removeAll { $0.name == name }
        if Self.builtIn.contains(where: { $0.name == name }) {
            persist(removedBuiltIns: [name])
        } else {
            persist(removedBuiltIns: nil)
        }
    }

    // MARK: - 持久化

    private var tombstones: Set<String> = []

    private func persist(removedBuiltIns: [String]?) {
        if let removedBuiltIns {
            tombstones.formUnion(removedBuiltIns)
        }
        let envelope = Envelope(categories: categories, removedBuiltIns: Array(tombstones))
        if let data = try? encoder.encode(envelope) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
