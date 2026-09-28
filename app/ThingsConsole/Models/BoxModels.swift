import Foundation

// MARK: - 箱子状态

enum BoxStatus: String, Codable, CaseIterable, Identifiable {
    case sealed = "未开封"
    case inProgress = "清理中"
    case sorted = "已归类"
    case done = "已完成"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .sealed:     return "shippingbox"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .sorted:     return "checklist.checked"
        case .done:       return "checkmark.seal.fill"
        }
    }
}

// MARK: - 物品处置

enum ItemDisposition: String, Codable, CaseIterable, Identifiable {
    case keep = "留"
    case donate = "捐"
    case sell = "卖"
    case trash = "扔"
    case relocate = "挪"
    case pending = "待定"

    var id: String { rawValue }
}

// MARK: - 清理箱

struct CleanupBox: Codable, Identifiable, Hashable {
    var id: UUID
    var label: String
    var status: BoxStatus
    var dominantCategory: String
    var priority: Int
    var method: String
    var notes: String
    var startedAt: Date?
    var completedAt: Date?
    var timeSpentSeconds: Int
    var beforePhoto: ItemPhoto?
    var afterPhoto: ItemPhoto?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         label: String,
         status: BoxStatus = .sealed,
         dominantCategory: String = "",
         priority: Int = 3,
         method: String = "",
         notes: String = "",
         startedAt: Date? = nil,
         completedAt: Date? = nil,
         timeSpentSeconds: Int = 0,
         beforePhoto: ItemPhoto? = nil,
         afterPhoto: ItemPhoto? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.label = label
        self.status = status
        self.dominantCategory = dominantCategory
        self.priority = priority
        self.method = method
        self.notes = notes
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.timeSpentSeconds = timeSpentSeconds
        self.beforePhoto = beforePhoto
        self.afterPhoto = afterPhoto
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var timeSpentText: String {
        let m = timeSpentSeconds / 60
        let s = timeSpentSeconds % 60
        return m > 0 ? "\(m)分\(s)秒" : "\(s)秒"
    }
}

// MARK: - 方法论选项

enum CleanupMethod {
    static let all: [String] = ["断舍离", "KonMari", "FlyLady", "5S", "自由清理"]
}
