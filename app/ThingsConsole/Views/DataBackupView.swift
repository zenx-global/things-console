import SwiftUI
import UniformTypeIdentifiers

/// 数据与备份：数据概览、自动备份、备份历史与恢复、导出与导入（备份 / CSV / Excel 台账）。
struct DataBackupView: View {
    @ObservedObject var store: ItemStore
    @ObservedObject var companion: CompanionServer
    @ObservedObject var boxStore: BoxStore
    @EnvironmentObject private var categoryStore: CategoryStore

    @State private var photoStats: (count: Int, bytes: Int64) = (0, 0)
    @State private var backups: [BackupEntry] = []
    @State private var restoreTarget: BackupEntry?
    @State private var folderRestoreTarget: FolderRestore?
    @State private var excelPreview: ExcelPreview?
    @State private var feedback: String?

    /// 从任意文件夹恢复前的待确认意图
    struct FolderRestore: Identifiable {
        let url: URL
        let count: Int
        var id: String { url.path }
    }

    /// Excel 导入前的预览与确认意图
    struct ExcelPreview: Identifiable {
        let plan: ImportPlan
        let fileName: String
        var id: String { plan.summary + fileName }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("数据与备份").font(.largeTitle.bold())
                overviewCard
                backupCard
                historyCard
                exportCard
                excelImportCard
                importCard
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            photoStats = ItemStore.photoDiskUsage()
            refreshBackups()
        }
        .confirmationDialog("确认恢复备份",
                            isPresented: Binding(
                                get: { restoreTarget != nil },
                                set: { if !$0 { restoreTarget = nil } }),
                            titleVisibility: .visible,
                            presenting: restoreTarget) { entry in
            Button("用「\(entry.name)」覆盖当前台账", role: .destructive) {
                performRestore(entry)
            }
            Button("取消", role: .cancel) {}
        } message: { entry in
            Text("当前 \(store.items.count) 件物品将被替换为备份中的 \(entry.itemCount) 件；备份含箱台账时一并恢复。替换前会自动创建当前数据的快照。")
        }
        .confirmationDialog("确认从文件夹恢复",
                            isPresented: Binding(
                                get: { folderRestoreTarget != nil },
                                set: { if !$0 { folderRestoreTarget = nil } }),
                            titleVisibility: .visible,
                            presenting: folderRestoreTarget) { target in
            Button("用「\(target.url.lastPathComponent)」覆盖当前台账", role: .destructive) {
                performFolderRestore(target)
            }
            Button("取消", role: .cancel) {}
        } message: { target in
            Text("当前 \(store.items.count) 件物品将被替换为该文件夹中的 \(target.count) 件；备份含箱台账时一并恢复。替换前会自动创建当前数据的快照。")
        }
        .confirmationDialog("确认导入 Excel 台账",
                            isPresented: Binding(
                                get: { excelPreview != nil },
                                set: { if !$0 { excelPreview = nil } }),
                            titleVisibility: .visible,
                            presenting: excelPreview) { preview in
            Button("导入（\(preview.plan.summary)）") {
                performExcelImport(preview)
            }
            Button("取消", role: .cancel) {}
        } message: { preview in
            Text(excelImportMessage(preview))
        }
        .alert(feedback ?? "", isPresented: Binding(
            get: { feedback != nil },
            set: { if !$0 { feedback = nil } })) {
            Button("好", role: .cancel) {}
        }
    }

    // MARK: - 反馈

    private func showFeedback(_ text: String) {
        feedback = text
    }

    private func refreshBackups() {
        DispatchQueue.global(qos: .userInitiated).async {
            let entries = BackupService.listBackups()
            DispatchQueue.main.async { backups = entries }
        }
    }

    // MARK: - 数据概览

    private var overviewCard: some View {
        GroupBox("数据概览") {
            VStack(alignment: .leading, spacing: 10) {
                overviewRow(icon: "externaldrive.fill",
                            title: "数据文件",
                            value: ItemStore.dataFileURL.path) {
                    Button("在 Finder 中显示") {
                        BackupService.revealInFinder(ItemStore.dataFileURL)
                    }
                    .buttonStyle(.borderless)
                }
                overviewRow(icon: "archivebox.fill",
                            title: "物品档案",
                            value: "\(store.items.count) 件（在用 \(store.activeItems.count) · 闲置 \(store.idleItems.count) · 已退役 \(store.retiredItems.count)）")
                overviewRow(icon: "photo.on.rectangle.angled",
                            title: "照片文件",
                            value: "\(photoStats.count) 张 · 约 \(ByteCountFormatter.string(fromByteCount: photoStats.bytes, countStyle: .file))")
                overviewRow(icon: "checkmark.shield.fill",
                            title: "运行方式",
                            value: companion.isRunning
                                  ? "本地存储 · 手机速录已开启（仅限局域网，凭密钥访问）"
                                  : "完全离线 · 本地存储 · 无任何网络请求")
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func overviewRow(icon: String, title: String, value: String,
                             @ViewBuilder trailing: () -> some View = { EmptyView() }) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.tint).frame(width: 20)
            Text(title).font(.subheadline).foregroundStyle(.secondary).frame(width: 72, alignment: .leading)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
    }

    // MARK: - 自动备份

    private var backupCard: some View {
        GroupBox("备份") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { BackupService.autoBackupEnabled },
                    set: { BackupService.autoBackupEnabled = $0 })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("每日自动备份")
                        Text("每天首次打开 App 时自动备份到本地 Backups 文件夹，保留最近 10 份。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Button {
                        if let url = store.backupNow() {
                            refreshBackups()
                            showFeedback("已备份：\(url.lastPathComponent)")
                        } else {
                            showFeedback("备份失败，请检查磁盘权限")
                        }
                    } label: {
                        Label("立即备份", systemImage: "square.and.arrow.down.on.square")
                    }
                    .buttonStyle(.borderedProminent)
                    if let date = store.lastBackupDate {
                        Text("最近备份：\(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("还没有备份").font(.caption).foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 备份历史

    private var historyCard: some View {
        GroupBox("备份历史") {
            if backups.isEmpty {
                Text("暂无备份；点上方「立即备份」创建第一份。")
                    .font(.caption).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(backups, id: \.url) { entry in
                        HStack(spacing: 10) {
                            let isAuto = entry.name.hasPrefix("auto")
                            Image(systemName: isAuto ? "clock.arrow.circlepath" : "archivebox")
                                .foregroundStyle(isAuto ? Color.secondary : Color.accentColor)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(entry.name).font(.subheadline.monospacedDigit())
                                Text("\(entry.itemCount) 件物品 · \(entry.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("恢复") { restoreTarget = entry }
                                .buttonStyle(.borderless)
                            Button("显示") {
                                BackupService.revealInFinder(entry.url)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding(2)
            }
        }
    }

    private func performRestore(_ entry: BackupEntry) {
        do {
            let imported = try BackupService.importItems(from: entry.url)
            store.replaceAll(imported, copyingPhotosFrom: entry.url)
            if let boxes = BackupService.importBoxes(from: entry.url) {
                boxStore.replaceAll(boxes)
            }
            photoStats = ItemStore.photoDiskUsage()
            showFeedback("已恢复 \(imported.count) 件物品")
        } catch {
            showFeedback("恢复失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 导出

    private var exportCard: some View {
        GroupBox("导出") {
            HStack(spacing: 12) {
                Button {
                    exportBundle()
                } label: {
                    Label("导出完整备份…", systemImage: "externaldrive.badge.plus")
                }
                Text("含 items.json + boxes.json + 照片文件夹，可直接拷到 U 盘 / 网盘")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button {
                    exportExcel()
                } label: {
                    Label("导出 Excel 台账…", systemImage: "tablecells.badge.gearshape")
                }
                Text("带 ID 列，可随时补行改行后回导")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button {
                    exportCSV()
                } label: {
                    Label("导出 CSV 表格…", systemImage: "tablecells")
                }
                Text("Excel / Numbers 可直接打开")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func exportExcel() {
        guard let url = BackupService.runSavePanel(suggestedName: "物品台账-\(dateStamp()).xlsx") else { return }
        let snapshot = store.items
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try SpreadsheetService.exportWorkbook(items: snapshot)
                try data.write(to: url, options: .atomic)
                DispatchQueue.main.async {
                    BackupService.revealInFinder(url)
                    showFeedback("已导出 Excel（\(snapshot.count) 行）")
                }
            } catch {
                DispatchQueue.main.async {
                    showFeedback("导出失败：\(error.localizedDescription)")
                }
            }
        }
    }

    private func exportBundle() {
        guard let dir = BackupService.chooseDirectory() else { return }
        do {
            let url = try BackupService.exportBundle(items: store.items, to: dir)
            BackupService.revealInFinder(url)
            showFeedback("已导出完整备份")
        } catch {
            showFeedback("导出失败：\(error.localizedDescription)")
        }
    }

    private func exportCSV() {
        guard let url = BackupService.runSavePanel(suggestedName: "物品台账-\(dateStamp()).csv") else { return }
        let csv = BackupService.exportCSV(items: store.items)
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            showFeedback("已导出 CSV（\(store.items.count) 行）")
        } catch {
            showFeedback("导出失败：\(error.localizedDescription)")
        }
    }

    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    // MARK: - Excel 台账导入

    private var excelImportCard: some View {
        GroupBox("Excel 台账导入") {
            VStack(alignment: .leading, spacing: 8) {
                Text("用「导出 Excel 台账」得到的表格持续维护（Excel / Numbers / WPS 均可），随时导回：按列名匹配、与列顺序无关；ID 相同的行更新，无 ID 的行新增，空名称行跳过。")
                    .font(.caption).foregroundStyle(.secondary)
                Text("空单元格 = 清空该值（数量留空保持原值）；整列删除 = 该字段不变；照片不受影响。导入前自动创建当前台账的快照。")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    importExcel()
                } label: {
                    Label("选择 Excel 文件…", systemImage: "square.and.arrow.down")
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func importExcel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if let type = UTType(filenameExtension: "xlsx") {
            panel.allowedContentTypes = [type]
        }
        panel.prompt = "选择"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let snapshot = store.items
        let knownCategories = Set(categoryStore.categories.map(\.name))
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let rows = try SpreadsheetService.parseWorkbook(at: url)
                let plan = SpreadsheetMerge.plan(rows: rows, existing: snapshot,
                                                 knownCategories: knownCategories)
                DispatchQueue.main.async {
                    if rows.isEmpty {
                        showFeedback("表格中没有数据行")
                    } else {
                        excelPreview = ExcelPreview(plan: plan, fileName: url.lastPathComponent)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    showFeedback("读取失败：\(error.localizedDescription)")
                }
            }
        }
    }

    private func performExcelImport(_ preview: ExcelPreview) {
        let result = store.applySpreadsheetImport(preview.plan)
        var text = "导入完成：\(preview.plan.summary)"
        if !preview.plan.unknownCategories.isEmpty {
            text += "；未注册分类已原样保留：\(preview.plan.unknownCategories.joined(separator: "、"))"
        }
        if !preview.plan.warnings.isEmpty {
            text += "。注意：" + preview.plan.warnings.joined(separator: "；")
        }
        _ = result
        showFeedback(text)
        refreshBackups()
    }

    private func excelImportMessage(_ preview: ExcelPreview) -> String {
        var text = "将把「\(preview.fileName)」应用到当前台账（\(store.items.count) 件）；开始前会自动创建当前数据的快照。"
        if preview.plan.skippedRows > 0 {
            text += "将有 \(preview.plan.skippedRows) 个空名称行被跳过。"
        }
        if !preview.plan.unknownCategories.isEmpty {
            text += "未注册分类：\(preview.plan.unknownCategories.joined(separator: "、"))，将原样保留。"
        }
        return text
    }

    // MARK: - 导入恢复

    private var importCard: some View {
        GroupBox("从备份文件夹恢复") {
            VStack(alignment: .leading, spacing: 8) {
                Text("选择之前导出的备份文件夹（含 items.json 与 Photos），将整体替换当前台账。")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    importFromFolder()
                } label: {
                    Label("选择备份文件夹…", systemImage: "folder.badge.gearshape")
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func importFromFolder() {
        guard let dir = BackupService.chooseDirectory(),
              BackupService.isBackupFolder(dir) else {
            showFeedback("所选文件夹不是有效备份（缺少 items.json）")
            return
        }
        do {
            let imported = try BackupService.importItems(from: dir)
            folderRestoreTarget = FolderRestore(url: dir, count: imported.count)
        } catch {
            showFeedback("读取备份失败：\(error.localizedDescription)")
        }
    }

    private func performFolderRestore(_ target: FolderRestore) {
        do {
            let imported = try BackupService.importItems(from: target.url)
            store.replaceAll(imported, copyingPhotosFrom: target.url)
            if let boxes = BackupService.importBoxes(from: target.url) {
                boxStore.replaceAll(boxes)
            }
            photoStats = ItemStore.photoDiskUsage()
            refreshBackups()
            showFeedback("已从文件夹恢复 \(imported.count) 件物品")
        } catch {
            showFeedback("恢复失败：\(error.localizedDescription)")
        }
    }
}
