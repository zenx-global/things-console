import SwiftUI
import UniformTypeIdentifiers

/// 单箱工作台：箱头（标签 / 状态 / 方法论 / 计时 / 前后照）+ 物品流（逐件处置）+ 完成动作。
struct BoxWorkbenchView: View {
    let boxId: UUID
    @ObservedObject var boxStore: BoxStore
    @ObservedObject var itemStore: ItemStore

    @State private var labelDraft = ""
    @State private var sessionStart: Date?
    @State private var nowTick = Date()
    @State private var quickName = ""
    @State private var showCompleteConfirm = false

    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(box: CleanupBox, boxStore: BoxStore, itemStore: ItemStore) {
        self.boxId = box.id
        self.boxStore = boxStore
        self.itemStore = itemStore
        self._labelDraft = State(initialValue: box.label)
    }

    private var box: CleanupBox? { boxStore.box(id: boxId) }

    private var boxItems: [AssetItem] { itemStore.items(inBox: boxId) }

    /// 已提交耗时 + 当前运行中的增量
    private var totalSeconds: Int {
        let base = box?.timeSpentSeconds ?? 0
        guard let sessionStart else { return base }
        return base + max(0, Int(nowTick.timeIntervalSince(sessionStart)))
    }

    var body: some View {
        ScrollView {
            if let box {
                VStack(alignment: .leading, spacing: 22) {
                    headerCard(box)
                    itemsCard(box)
                    completeCard(box)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("箱子已被删除").foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .navigationTitle(box?.label ?? "箱子")
        .onReceive(tickTimer) { nowTick = $0 }
        .onDisappear { commitRunningTime() }
        .confirmationDialog("完成这个箱子？",
                            isPresented: $showCompleteConfirm,
                            titleVisibility: .visible) {
            Button("完成箱子") { completeBox() }
            Button("取消", role: .cancel) {}
        } message: {
            let undecided = boxItems.filter { $0.disposition == nil }.count
            Text(undecided > 0
                 ? "还有 \(undecided) 件物品未标处置，完成后仍可回来补标。本次计时 \(timerText(totalSeconds)) 将写入箱子。"
                 : "本次计时 \(timerText(totalSeconds)) 将写入箱子。")
        }
    }

    // MARK: - 箱头

    private func headerCard(_ box: CleanupBox) -> some View {
        GroupBox("箱子") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    TextField("箱子标签", text: $labelDraft)
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)
                        .frame(maxWidth: 260)
                        .onSubmit { commitLabel(box) }
                    statusBadge(box.status)
                    Spacer()
                    timerBlock(box)
                }
                HStack(spacing: 16) {
                    Picker("方法论", selection: Binding(
                        get: { box.method },
                        set: { updated in
                            var draft = box
                            draft.method = updated
                            boxStore.update(draft)
                        })) {
                        Text("未选择").tag("")
                        ForEach(CleanupMethod.all, id: \.self) { Text($0).tag($0) }
                    }
                    .frame(width: 200)
                    photoSlot(box: box, slot: .before, title: "清理前")
                    photoSlot(box: box, slot: .after, title: "清理后")
                    Spacer()
                }
                if !box.notes.isEmpty {
                    Text(box.notes).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statusBadge(_ status: BoxStatus) -> some View {
        Text(status.rawValue)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(BoxCardView.statusColor(status).opacity(0.14), in: Capsule())
            .foregroundStyle(BoxCardView.statusColor(status))
    }

    private func timerBlock(_ box: CleanupBox) -> some View {
        HStack(spacing: 10) {
            Text(timerText(totalSeconds))
                .font(.title2.bold().monospacedDigit())
            Button {
                if sessionStart == nil { startTimer(box) } else { commitRunningTime() }
            } label: {
                Label(sessionStart == nil ? "开始计时" : "暂停",
                      systemImage: sessionStart == nil ? "play.fill" : "pause.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    private func startTimer(_ box: CleanupBox) {
        if box.status == .sealed {
            boxStore.setStatus(.inProgress, for: box.id)
        }
        sessionStart = Date()
        nowTick = Date()
    }

    /// 把运行中的时间提交进箱子（暂停 / 离开页面 / 完成时调用）
    private func commitRunningTime() {
        guard let sessionStart else { return }
        let seconds = max(0, Int(Date().timeIntervalSince(sessionStart)))
        self.sessionStart = nil
        if seconds > 0 { boxStore.addTimeSpent(seconds, to: boxId) }
    }

    private func commitLabel(_ box: CleanupBox) {
        let trimmed = labelDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != box.label else {
            labelDraft = box.label
            return
        }
        var draft = box
        draft.label = trimmed
        boxStore.update(draft)
    }

    private func timerText(_ seconds: Int) -> String {
        String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    // MARK: - 前后照片

    private func photoSlot(box: CleanupBox, slot: BoxStore.PhotoSlot, title: String) -> some View {
        let photo = slot == .before ? box.beforePhoto : box.afterPhoto
        return Button {
            pickPhoto(slot: slot)
        } label: {
            HStack(spacing: 6) {
                if let photo, let image = PhotoStore.load(photo) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 34, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "camera")
                        .frame(width: 34, height: 34)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func pickPhoto(slot: BoxStore.PhotoSlot) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.prompt = "选择照片"
        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? Data(contentsOf: url),
              let photo = PhotoStore.save(data: data) else { return }
        boxStore.setPhoto(photo, slot: slot, for: boxId)
    }

    // MARK: - 物品流

    private func itemsCard(_ box: CleanupBox) -> some View {
        GroupBox("箱内物品（\(boxItems.count)）") {
            VStack(alignment: .leading, spacing: 10) {
                if boxItems.isEmpty {
                    Text("还没有物品。从箱子往外拿，边拿边录：")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(boxItems) { item in
                        itemRow(item)
                        if item.id != boxItems.last?.id {
                            Divider()
                        }
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.tint)
                    TextField("物品名称，回车录入本箱", text: $quickName)
                        .textFieldStyle(.plain)
                        .onSubmit { quickAdd() }
                }
                .padding(.top, 4)
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func itemRow(_ item: AssetItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.body)
                Text([item.category, item.location]
                    .filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
            }
            .frame(minWidth: 130, alignment: .leading)
            Spacer()
            dispositionButtons(for: item)
        }
        .padding(.vertical, 2)
    }

    private func dispositionButtons(for item: AssetItem) -> some View {
        HStack(spacing: 5) {
            ForEach(ItemDisposition.allCases) { disposition in
                let selected = item.disposition == disposition
                let color = Self.dispositionColor(disposition)
                Button {
                    itemStore.setDisposition(selected ? nil : disposition, for: item.id)
                } label: {
                    Text(disposition.rawValue)
                        .font(.caption.weight(selected ? .semibold : .regular))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selected ? color : color.opacity(0.1), in: Capsule())
                        .foregroundStyle(selected ? Color.white : color)
                }
                .buttonStyle(.plain)
            }
        }
    }

    static func dispositionColor(_ disposition: ItemDisposition) -> Color {
        switch disposition {
        case .keep:     return .green
        case .donate:   return .blue
        case .sell:     return .orange
        case .trash:    return .red
        case .relocate: return .purple
        case .pending:  return .gray
        }
    }

    private func quickAdd() {
        let name = quickName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        itemStore.quickAddInBox(name: name, boxId: boxId)
        quickName = ""
    }

    // MARK: - 完成动作

    private func completeCard(_ box: CleanupBox) -> some View {
        GroupBox("收尾") {
            HStack(spacing: 12) {
                if box.status != .sorted && box.status != .done {
                    Button {
                        commitRunningTime()
                        boxStore.setStatus(.sorted, for: box.id)
                    } label: {
                        Label("标记已归类", systemImage: "checklist.checked")
                    }
                }
                if box.status != .done {
                    Button {
                        showCompleteConfirm = true
                    } label: {
                        Label("完成箱子", systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Label("已完成", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    if let completedAt = box.completedAt {
                        Text("完成于 \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                let undecided = boxItems.filter { $0.disposition == nil }.count
                if undecided > 0 {
                    Text("\(undecided) 件未标处置")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func completeBox() {
        commitRunningTime()
        boxStore.setStatus(.done, for: boxId)
    }
}
