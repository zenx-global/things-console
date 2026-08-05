import SwiftUI

// MARK: - 计划详情（任务清单）
// 通过 planId 从 store 实时读取，避免值类型快照导致的数据不同步。
struct PlanDetailView: View {
    let planId: UUID
    @ObservedObject var store: PlanStore
    @Environment(\.dismiss) private var dismiss

    @State private var newTaskTitle = ""
    @State private var newTaskGroup = ""
    @State private var editingTaskId: UUID?

    /// 实时计划（store 变化即刷新）
    private var plan: AppPlan? { store.plans.first { $0.id == planId } }

    /// 按分组聚合任务（按 order 排序，自动过滤空分组）
    private var grouped: [(String, [AppTask])] {
        guard let plan else { return [] }
        let sorted = plan.tasks.sorted { $0.order < $1.order }
        let groups = NSOrderedSet(array: sorted.map(\.group)).array as! [String]
        return groups.compactMap { g in
            let items = sorted.filter { $0.group == g }
            return items.isEmpty ? nil : (g, items)
        }
    }

    var body: some View {
        Group {
            if let plan {
                VStack(spacing: 0) {
                    header(plan)
                    Divider()
                    if plan.tasks.isEmpty {
                        emptyTasks
                    } else {
                        taskList
                    }
                    Divider()
                    addBar
                }
            } else {
                ContentUnavailableView("计划不存在", systemImage: "questionmark.circle",
                                       description: Text("它可能已被删除"))
            }
        }
        .padding(.top, 12)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }
        .sheet(item: Binding(
            get: { editingTaskId.map(IDBox.init) },
            set: { editingTaskId = $0?.id }
        )) { box in
            if let task = plan?.tasks.first(where: { $0.id == box.id }) {
                NoteEditorSheet(initialText: task.note) { note in
                    store.updateTaskNote(note, taskId: box.id, in: planId)
                }
                .frame(minWidth: 380, minHeight: 220)
            }
        }
    }

    // MARK: 头部
    private func header(_ plan: AppPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.title).font(.title.bold())
                Spacer()
                Text("\(plan.doneCount) / \(plan.tasks.count) 完成")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: plan.progress)
                .tint(progressTint(plan.progress))
            HStack(spacing: 6) {
                Image(systemName: "tag.fill").font(.caption2)
                Text("基于「\(plan.methodologyName)」方法论")
                Text("·").foregroundStyle(.tertiary)
                Text(plan.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24).padding(.bottom, 14)
    }

    // MARK: 任务列表
    private var taskList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(grouped, id: \.0) { group, tasks in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(group)
                                .font(.headline)
                                .foregroundStyle(.tint)
                            Spacer()
                            Text("\(tasks.filter(\.isDone).count)/\(tasks.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                        ForEach(tasks) { task in
                            TaskRow(
                                task: task,
                                onToggle: { store.toggleTask(task.id, in: planId) },
                                onNote: { editingTaskId = task.id },
                                onDelete: { store.deleteTask(task.id, in: planId) }
                            )
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyTasks: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray").font(.system(size: 40)).foregroundStyle(.tertiary)
            Text("这个计划还没有任务").foregroundStyle(.secondary)
            Text("在下方添加你的第一个任务").font(.caption).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, 40)
    }

    // MARK: 添加任务栏
    private var addBar: some View {
        HStack(spacing: 8) {
            TextField("分组（可选）", text: $newTaskGroup)
                .textFieldStyle(.roundedBorder).frame(width: 140)
            TextField("添加新任务…", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addTask)
            Button(action: addTask) {
                Image(systemName: "plus.circle.fill").font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
    }

    private func addTask() {
        let t = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        store.addTask(group: newTaskGroup.trimmingCharacters(in: .whitespaces),
                      title: t, hint: "", in: planId)
        newTaskTitle = ""
        newTaskGroup = ""
    }

    // MARK: 辅助
    private func progressTint(_ p: Double) -> Color {
        if p >= 1 { return .green }
        if p >= 0.6 { return .blue }
        if p > 0 { return .orange }
        return .gray
    }
}

// MARK: - 任务行
struct TaskRow: View {
    let task: AppTask
    let onToggle: () -> Void
    let onNote: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: onToggle) {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(task.isDone ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("标记完成 / 取消")

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .strikethrough(task.isDone, color: .secondary)
                        .foregroundStyle(task.isDone ? .secondary : .primary)
                    if !task.hint.isEmpty {
                        Text(task.hint).font(.caption).foregroundStyle(.secondary)
                    }
                    if !task.note.isEmpty {
                        Label(task.note, systemImage: "note.text")
                            .font(.caption).foregroundStyle(.indigo)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Menu {
                    Button(task.note.isEmpty ? "添加备注" : "编辑备注") { onNote() }
                    Button("删除任务", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary).padding(6)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - 备注编辑
struct NoteEditorSheet: View {
    let initialText: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("任务备注").font(.headline)
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            HStack {
                if !text.isEmpty {
                    Button("清除备注", role: .destructive) {
                        onSave(""); dismiss()
                    }
                }
                Spacer()
                Button("取消", role: .cancel) { dismiss() }
                Button("保存") { onSave(text); dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .onAppear { text = initialText }
    }
}
