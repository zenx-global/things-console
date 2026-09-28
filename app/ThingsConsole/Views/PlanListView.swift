import SwiftUI

// MARK: - 我的计划 列表
struct PlanListView: View {
    @ObservedObject var store: PlanStore
    @State private var showingNewPlan = false
    @State private var selectedPlanId: UUID?
    @State private var deleteTarget: AppPlan?

    var body: some View {
        Group {
            if store.plans.isEmpty {
                emptyState
            } else {
                planList
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewPlan = true
                } label: {
                    Label("新建计划", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewPlan) {
            NewPlanView(store: store)
                .frame(minWidth: 520, minHeight: 560)
        }
        .confirmationDialog("删除整理计划",
                            isPresented: Binding(
                                get: { deleteTarget != nil },
                                set: { if !$0 { deleteTarget = nil } }),
                            titleVisibility: .visible,
                            presenting: deleteTarget) { plan in
            Button("删除「\(plan.title)」及全部 \(plan.tasks.count) 项任务", role: .destructive) {
                if selectedPlanId == plan.id { selectedPlanId = nil }
                store.deletePlan(plan)
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(item: Binding(
            get: { selectedPlanId.map(IDBox.init) },
            set: { selectedPlanId = $0?.id }
        )) { wrapper in
            if let plan = store.plans.first(where: { $0.id == wrapper.id }) {
                PlanDetailView(planId: plan.id, store: store)
                    .frame(minWidth: 760, minHeight: 640)
            } else {
                Text("该计划已不存在").padding()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("还没有整理计划").font(.title3.weight(.semibold))
            Text("选择一种方法论，生成断舍离处置行动清单。")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button {
                showingNewPlan = true
            } label: {
                Label("新建计划", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var planList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("整理计划").font(.largeTitle.bold())
                LazyVStack(spacing: 12) {
                    ForEach(store.plans) { plan in
                        PlanRow(plan: plan)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedPlanId = plan.id }
                            .contextMenu {
                                Button("删除计划", role: .destructive) {
                                    deleteTarget = plan
                                }
                            }
                    }
                }
            }
            .padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 计划卡片行
struct PlanRow: View {
    let plan: AppPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title).font(.headline)
                    Text("基于「\(plan.methodologyName)」")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(plan.doneCount)/\(plan.tasks.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: plan.progress)
                .tint(progressTint)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 0.5))
    }

    private var progressTint: Color {
        switch plan.progress {
        case 1.0:             return .green
        case 0.6..<1.0:       return .blue
        case 0.0001..<0.6:    return .orange
        default:              return .gray
        }
    }
}

// MARK: - 新建计划
struct NewPlanView: View {
    @ObservedObject var store: PlanStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedMethodology: Methodology = MethodologyData.danshari

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("新建计划").font(.title.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("计划标题").font(.subheadline.weight(.medium))
                TextField("例如：客厅断舍离计划", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("选择方法论").font(.subheadline.weight(.medium))
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(MethodologyData.all) { m in
                            methodologyOption(m)
                        }
                    }
                }
            }

            templatePreview

            Spacer()
            HStack {
                Spacer()
                Button("取消", role: .cancel) { dismiss() }
                Button("生成计划") { create() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
            }
        }
        .padding(24)
    }

    private func methodologyOption(_ m: Methodology) -> some View {
        let isSelected = m.id == selectedMethodology.id
        return HStack(spacing: 12) {
            Text(m.emoji).font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(m.name).font(.subheadline.weight(.semibold))
                Text(m.templateTitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.quaternary, lineWidth: 0.5)
                .opacity(isSelected ? 0 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.accentColor, lineWidth: 1.5)
                .opacity(isSelected ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture { selectedMethodology = m }
    }

    private var templatePreview: some View {
        let tasks = TemplateGenerator.tasks(for: selectedMethodology.id)
        return GroupBox("模板预览 · \(selectedMethodology.templateTitle)（\(tasks.count) 项任务）") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tasks.prefix(5)) { t in
                    Text("• \(t.title)").font(.caption).foregroundStyle(.secondary)
                }
                if tasks.count > 5 {
                    Text("… 还有 \(tasks.count - 5) 项").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        }
    }

    private func create() {
        store.createPlan(title: title, methodologyId: selectedMethodology.id)
        dismiss()
    }
}
