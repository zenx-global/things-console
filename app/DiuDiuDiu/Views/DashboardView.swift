import SwiftUI

// MARK: - 仪表盘
struct DashboardView: View {
    @ObservedObject var store: PlanStore

    private var totalTasks: Int { store.plans.flatMap(\.tasks).count }
    private var doneTasks: Int { store.plans.flatMap(\.tasks).filter(\.isDone).count }
    private var overallProgress: Double {
        totalTasks == 0 ? 0 : Double(doneTasks) / Double(totalTasks)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("仪表盘").font(.largeTitle.bold())

                // 顶部统计卡片
                HStack(spacing: 16) {
                    statCard(title: "进行中的计划", value: "\(store.plans.count)", icon: "list.bullet.rectangle", tint: .blue)
                    statCard(title: "总任务", value: "\(totalTasks)", icon: "checklist", tint: .purple)
                    statCard(title: "已完成", value: "\(doneTasks)", icon: "checkmark.seal.fill", tint: .green)
                    statCard(title: "完成率", value: percent(overallProgress), icon: "chart.pie.fill", tint: .orange)
                }

                // 总进度
                GroupBox("整体进度") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: overallProgress).tint(overallProgress >= 1 && totalTasks > 0 ? .green : .accentColor)
                        Text("\(doneTasks) / \(totalTasks) 任务完成")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(4)
                }

                // 各计划进度
                if store.plans.isEmpty {
                    emptyHint
                } else {
                    GroupBox("各计划进度") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(store.plans) { p in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(p.title).font(.subheadline.weight(.medium))
                                        Spacer()
                                        Text("\(p.doneCount)/\(p.tasks.count)")
                                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                    }
                                    ProgressView(value: p.progress)
                                        .tint(p.progress >= 1 ? .green : .accentColor)
                                }
                            }
                        }
                        .padding(4).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 方法论使用分布
                if !store.plans.isEmpty {
                    GroupBox("方法论使用分布") {
                        methodologyBreakdown
                            .padding(4).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray").font(.system(size: 36)).foregroundStyle(.tertiary)
            Text("还没有计划，去「我的计划」创建第一个吧。")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 30)
    }

    private func statCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(tint)
            Text(value).font(.title.bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 0.5))
    }

    private var methodologyBreakdown: some View {
        let counts = Dictionary(grouping: store.plans, by: \.methodologyId)
            .mapValues { $0.count }
        let maxCount = counts.values.max() ?? 1
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(counts.sorted(by: { $0.value > $1.value }), id: \.key) { id, count in
                if let m = MethodologyData.find(id) {
                    HStack(spacing: 10) {
                        Text(m.emoji)
                        Text(m.name).font(.subheadline)
                        Spacer()
                        Text("\(count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    .padding(.leading, 2)
                    ProgressView(value: Double(count), total: Double(maxCount))
                        .tint(.accentColor).frame(height: 6)
                }
            }
        }
    }

    private func percent(_ v: Double) -> String {
        let p = Int((v * 100).rounded())
        return "\(p)%"
    }
}
