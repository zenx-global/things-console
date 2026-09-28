import Foundation

/// 断舍离与整理方法论的数据模型。
/// 这里用纯 struct + UserDefaults(JSON) 持久化，避免依赖 SwiftData（CLT 环境兼容性更好）。

// MARK: - 辅助

/// 将 UUID 包装为 Identifiable，用于驱动 sheet(item:)
struct IDBox: Identifiable, Hashable {
    let id: UUID
}

// MARK: - 方法论（内置静态数据）

/// 一条方法论准则 / 法则
struct MethodologyPrinciple: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

/// 方法论
struct Methodology: Codable, Identifiable, Hashable {
    let id: String
    let name: String            // 断舍离
    let subtitle: String        // 通过整理物品来整理内心
    let author: String          // 山下英子
    let emoji: String           // 🧘
    let criterion: String       // 判断标准
    let audience: String        // 适合人群
    let philosophy: String      // 核心理念
    let principles: [MethodologyPrinciple]
    let templateTitle: String   // 该方法论生成的模板名称
    let sources: [String]
}

// MARK: - 用户数据（计划 / 任务）

/// 计划模板任务（方法论内置，用于生成计划）
struct TemplateTask: Codable, Identifiable, Hashable {
    let id: String
    let group: String           // 分组，例如「玄关」「衣服」「Day 1」「1S 整理」
    let title: String
    let hint: String            // 提示，例如「需要·合适·舒服 三问」
}

/// 用户任务（持久化）
struct AppTask: Codable, Identifiable, Hashable {
    var id: UUID
    var group: String
    var title: String
    var hint: String
    var note: String
    var isDone: Bool
    var order: Int

    init(id: UUID = UUID(),
         group: String,
         title: String,
         hint: String,
         note: String = "",
         isDone: Bool = false,
         order: Int) {
        self.id = id
        self.group = group
        self.title = title
        self.hint = hint
        self.note = note
        self.isDone = isDone
        self.order = order
    }

    /// 从模板任务构造
    init(from template: TemplateTask, order: Int) {
        self.init(id: UUID(),
                  group: template.group,
                  title: template.title,
                  hint: template.hint,
                  order: order)
    }
}

/// 用户计划（持久化）
struct AppPlan: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var methodologyId: String
    var methodologyName: String
    var createdAt: Date
    var tasks: [AppTask]

    init(id: UUID = UUID(),
         title: String,
         methodologyId: String,
         methodologyName: String,
         createdAt: Date = Date(),
         tasks: [AppTask]) {
        self.id = id
        self.title = title
        self.methodologyId = methodologyId
        self.methodologyName = methodologyName
        self.createdAt = createdAt
        self.tasks = tasks
    }

    /// 完成进度（0...1）
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter(\.isDone).count
        return Double(done) / Double(tasks.count)
    }

    var doneCount: Int { tasks.filter(\.isDone).count }
}
