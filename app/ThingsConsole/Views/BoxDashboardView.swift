import SwiftUI

/// 箱子看板：清理战役总览——进度、耗时、处置分布、50 箱网格与筛选。
struct BoxDashboardView: View {
    @ObservedObject var boxStore: BoxStore
    @ObservedObject var itemStore: ItemStore
    @EnvironmentObject private var categoryStore: CategoryStore

    @State private var statusFilter: BoxStatus?
    @State private var showBatchCreate = false
    @State private var batchCount = 50
    @State private var batchPrefix = "第"
    @State private var batchCategory = ""
    @State private var batchPriority = 3
    @State private var boxToDelete: CleanupBox?

    private let columns = [GridItem(.adaptive(minimum: 172), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("箱子清理").font(.largeTitle.bold())
                progressCard
                filterBar
                if filteredBoxes.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredBoxes) { box in
                            NavigationLink {
                                BoxWorkbenchView(box: box, boxStore: boxStore, itemStore: itemStore)
                            } label: {
                                BoxCardView(box: box, itemCount: boxStore.items(inBox: box.id, from: itemStore.items).count)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("删除箱子", role: .destructive) { boxToDelete = box }
                            }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showBatchCreate) { batchCreateSheet }
        .confirmationDialog("确认删除箱子",
                            isPresented: Binding(
                                get: { boxToDelete != nil },
                                set: { if !$0 { boxToDelete = nil } }),
                            titleVisibility: .visible,
                            presenting: boxToDelete) { box in
            Button("删除「\(box.label)」", role: .destructive) { performDelete(box) }
            Button("取消", role: .cancel) {}
        } message: { box in
            let count = boxStore.items(inBox: box.id, from: itemStore.items).count
            Text(count > 0 ? "箱内 \(count) 件物品将保留在台账，仅解除与本箱的关联。" : "箱子将被删除，物品台账不受影响。")
        }
    }

    // MARK: - 进度

    private var progressCard: some View {
        GroupBox("清理进度") {
            HStack(spacing: 26) {
                stat(value: "\(boxStore.completedCount)/\(boxStore.boxes.count)", label: "完成箱子")
                stat(value: boxStore.totalTimeText, label: "总耗时")
                Divider().frame(height: 30)
                ForEach(BoxStore.dispositionSummary(of: itemStore.items), id: \.0) { entry in
                    stat(value: "\(entry.1)", label: entry.0.rawValue)
                }
                Spacer()
                Button {
                    showBatchCreate = true
                } label: {
                    Label("批量创建箱子…", systemImage: "plus.square.on.square")
                }
                .buttonStyle(.borderedProminent)
                Button {
                    boxStore.batchCreate(count: 1)
                } label: {
                    Label("新建箱子", systemImage: "plus")
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - 筛选

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip(nil, label: "全部 \(boxStore.boxes.count)")
            ForEach(BoxStatus.allCases) { status in
                let count = boxStore.boxes.filter { $0.status == status }.count
                filterChip(status, label: "\(status.rawValue) \(count)")
            }
            Spacer()
        }
    }

    private func filterChip(_ status: BoxStatus?, label: String) -> some View {
        Button {
            statusFilter = status
        } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusFilter == status ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08),
                            in: Capsule())
                .foregroundStyle(statusFilter == status ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private var filteredBoxes: [CleanupBox] {
        guard let statusFilter else { return boxStore.boxes }
        return boxStore.boxes.filter { $0.status == statusFilter }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(boxStore.boxes.isEmpty ? "还没有箱子" : "该状态下没有箱子")
                .font(.headline)
            if boxStore.boxes.isEmpty {
                Text("点「批量创建箱子」一次生成 50 个，开始清理战役。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - 批量创建

    private var batchCreateSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("批量创建箱子").font(.headline)
            HStack {
                Text("数量").frame(width: 64, alignment: .leading)
                TextField("", value: $batchCount, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                Stepper("", value: $batchCount, in: 1...500).labelsHidden()
            }
            HStack {
                Text("编号前缀").frame(width: 64, alignment: .leading)
                TextField("第", text: $batchPrefix)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)
                Text("生成「\(batchPrefix)1箱」「\(batchPrefix)2箱」…，自动续接已有编号")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Text("主导分类").frame(width: 64, alignment: .leading)
                Picker("", selection: $batchCategory) {
                    Text("未指定").tag("")
                    ForEach(categoryStore.categories) { category in
                        Text("\(category.emoji) \(category.name)").tag(category.name)
                    }
                }
                .labelsHidden()
                .frame(width: 170)
            }
            HStack {
                Text("优先级").frame(width: 64, alignment: .leading)
                Picker("", selection: $batchPriority) {
                    ForEach(1...5, id: \.self) { level in
                        Text(String(repeating: "★", count: level)).tag(level)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
            }
            HStack {
                Spacer()
                Button("取消") { showBatchCreate = false }
                    .keyboardShortcut(.cancelAction)
                Button("创建 \(batchCount) 个箱子") {
                    boxStore.batchCreate(count: batchCount,
                                         prefix: batchPrefix,
                                         category: batchCategory,
                                         priority: batchPriority)
                    showBatchCreate = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    // MARK: - 删除

    private func performDelete(_ box: CleanupBox) {
        for item in boxStore.items(inBox: box.id, from: itemStore.items) {
            itemStore.assignToBox(nil, itemId: item.id)
        }
        boxStore.delete(box)
        boxToDelete = nil
    }
}

// MARK: - 箱卡片

struct BoxCardView: View {
    let box: CleanupBox
    let itemCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: box.status.symbolName)
                    .foregroundStyle(Self.statusColor(box.status))
                Text(box.label)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(String(repeating: "★", count: box.priority))
                    .font(.caption2)
                    .foregroundStyle(.orange.opacity(0.8))
            }
            HStack(spacing: 8) {
                Text(box.dominantCategory.isEmpty ? "未指定分类" : box.dominantCategory)
                Text("·")
                Text("\(itemCount) 件")
                if box.timeSpentSeconds > 0 {
                    Text("·")
                    Text(box.timeSpentText)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            Text(box.status.rawValue)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Self.statusColor(box.status).opacity(0.14), in: Capsule())
                .foregroundStyle(Self.statusColor(box.status))
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Self.statusColor(box.status).opacity(0.35), lineWidth: 1)
        )
    }

    static func statusColor(_ status: BoxStatus) -> Color {
        switch status {
        case .sealed:     return .secondary
        case .inProgress: return .accentColor
        case .sorted:     return .orange
        case .done:       return .green
        }
    }
}
