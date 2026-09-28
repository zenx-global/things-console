import Foundation

/// 物品台账的数据模型。
/// 与计划模块相同：纯 struct + UserDefaults(JSON) 持久化；照片文件存 Application Support。

// MARK: - 物品状态

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case inUse = "在用"
    case idle = "闲置"
    case retired = "已退役"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .inUse:   return "circle.circle.fill"
        case .idle:    return "moon.zzz.fill"
        case .retired: return "archivebox.fill"
        }
    }
}

// MARK: - 照片

/// 一张物品照片。文件存于 Application Support/ThingsConsole/Photos，实体里只记文件名。
struct ItemPhoto: Codable, Identifiable, Hashable {
    var id: UUID
    var fileName: String
    var createdAt: Date

    init(id: UUID = UUID(), fileName: String, createdAt: Date = Date()) {
        self.id = id
        self.fileName = fileName
        self.createdAt = createdAt
    }
}

// MARK: - 物品档案

struct AssetItem: Codable, Identifiable, Hashable {
    var id: UUID
    // 基础字段
    var name: String
    var category: String
    var location: String
    var brand: String
    var status: ItemStatus
    var notes: String
    // 价值与购入信息
    var purchasePrice: Double
    var purchaseDate: Date?
    var purchaseChannel: String
    var warrantyUntil: Date?
    // 数量与到期日
    var quantity: Int
    var expiresAt: Date?
    // 照片
    var photos: [ItemPhoto]
    // 箱子清理关联（P0：可选字段，旧数据解码为 nil）
    var sourceBoxId: UUID?
    var disposition: ItemDisposition?
    // 元数据
    var createdAt: Date
    var updatedAt: Date
    var retiredAt: Date?

    init(id: UUID = UUID(),
         name: String,
         category: String = "",
         location: String = "",
         brand: String = "",
         status: ItemStatus = .inUse,
         notes: String = "",
         purchasePrice: Double = 0,
         purchaseDate: Date? = nil,
         purchaseChannel: String = "",
         warrantyUntil: Date? = nil,
         quantity: Int = 1,
         expiresAt: Date? = nil,
         photos: [ItemPhoto] = [],
         sourceBoxId: UUID? = nil,
         disposition: ItemDisposition? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         retiredAt: Date? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.location = location
        self.brand = brand
        self.status = status
        self.notes = notes
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.purchaseChannel = purchaseChannel
        self.warrantyUntil = warrantyUntil
        self.quantity = quantity
        self.expiresAt = expiresAt
        self.photos = photos
        self.sourceBoxId = sourceBoxId
        self.disposition = disposition
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.retiredAt = retiredAt
    }

    /// 台账口径：小计 = 单价 × 数量
    var totalValue: Double { purchasePrice * Double(quantity) }

    /// 到期日距今的天数（负数 = 已过期）
    var daysUntilExpiry: Int? {
        guard let expiresAt else { return nil }
        return Calendar.current.dateComponents([.day],
                                               from: Calendar.current.startOfDay(for: Date()),
                                               to: Calendar.current.startOfDay(for: expiresAt)).day
    }

    var isExpired: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days < 0
    }

    /// 质保距今的天数（负数 = 已过保）
    var daysUntilWarrantyEnd: Int? {
        guard let warrantyUntil else { return nil }
        return Calendar.current.dateComponents([.day],
                                               from: Calendar.current.startOfDay(for: Date()),
                                               to: Calendar.current.startOfDay(for: warrantyUntil)).day
    }
}

// MARK: - 分类

/// 分类（注册表条目）。物品档案仍存分类名字符串，emoji 与顺序由分类注册表管理。
struct ItemCategory: Codable, Identifiable, Hashable {
    var name: String
    var emoji: String

    var id: String { name }
}

// MARK: - 格式化辅助

enum MoneyFormat {
    static func yuan(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "zh_CN"))) + " 元"
    }
}
