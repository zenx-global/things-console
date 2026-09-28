import Foundation
import SwiftUI

/// 用户数据的持久化与状态管理。
/// 使用 UserDefaults + JSON 编码，轻量、无外部依赖。
@MainActor
final class PlanStore: ObservableObject {

    @Published private(set) var plans: [AppPlan] = []

    private let key = "diu-diu-diu.plans.v1"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    // MARK: - 读取 / 持久化

    private func load() {
        guard let data = defaults.data(forKey: key) else { return }
        if let decoded = try? decoder.decode([AppPlan].self, from: data) {
            plans = decoded
        }
    }

    private func persist() {
        if let data = try? encoder.encode(plans) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - 计划操作

    /// 根据方法论创建新计划，自动生成对应模板任务
    @discardableResult
    func createPlan(title: String, methodologyId: String) -> AppPlan? {
        guard let m = MethodologyData.find(methodologyId) else { return nil }
        let templates = TemplateGenerator.tasks(for: methodologyId)
        let tasks = templates.enumerated().map { idx, tpl in
            AppTask(from: tpl, order: idx)
        }
        let plan = AppPlan(title: title.isEmpty ? "我的\(m.name)计划" : title,
                           methodologyId: methodologyId,
                           methodologyName: m.name,
                           tasks: tasks)
        plans.insert(plan, at: 0)
        persist()
        return plan
    }

    func deletePlan(_ plan: AppPlan) {
        plans.removeAll { $0.id == plan.id }
        persist()
    }

    func updatePlan(_ plan: AppPlan) {
        if let idx = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[idx] = plan
            persist()
        }
    }

    // MARK: - 任务操作

    func toggleTask(_ taskId: UUID, in planId: UUID) {
        guard let pIdx = plans.firstIndex(where: { $0.id == planId }),
              let tIdx = plans[pIdx].tasks.firstIndex(where: { $0.id == taskId }) else { return }
        plans[pIdx].tasks[tIdx].isDone.toggle()
        persist()
    }

    func updateTaskNote(_ note: String, taskId: UUID, in planId: UUID) {
        guard let pIdx = plans.firstIndex(where: { $0.id == planId }),
              let tIdx = plans[pIdx].tasks.firstIndex(where: { $0.id == taskId }) else { return }
        plans[pIdx].tasks[tIdx].note = note
        persist()
    }

    func addTask(group: String, title: String, hint: String, in planId: UUID) {
        guard let pIdx = plans.firstIndex(where: { $0.id == planId }) else { return }
        let order = (plans[pIdx].tasks.map(\.order).max() ?? -1) + 1
        let task = AppTask(group: group.isEmpty ? "自定义" : group,
                           title: title, hint: hint, order: order)
        plans[pIdx].tasks.append(task)
        persist()
    }

    func deleteTask(_ taskId: UUID, in planId: UUID) {
        guard let pIdx = plans.firstIndex(where: { $0.id == planId }) else { return }
        plans[pIdx].tasks.removeAll { $0.id == taskId }
        persist()
    }
}
