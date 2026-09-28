import SwiftUI

/// 物品台账：左列表 + 右详情的工作台主功能区。
struct ItemLedgerView: View {
    @ObservedObject var store: ItemStore
    @EnvironmentObject private var categoryStore: CategoryStore

    @State private var searchText = ""
    @State private var statusFilter: ItemStatus?
    @State private var categoryFilter = "全部分类"
    @State private var selectedId: UUID?
    @State private var editingTarget: AssetItem?
    @State private var deleteTarget: AssetItem?
    @State private var showingNewForm = false
    @State private var showingQuickEntry = false
    @State private var showingCategoryManage = false
    @State private var quickName = ""

    private let allCategoriesSentinel = "全部分类"

    /// 注册表分类 ∪ 物品里实际出现的分类
    private var categories: [String] {
        var names = Set(categoryStore.categories.map(\.name))
        names.formUnion(store.items.map(\.category).filter { !$0.isEmpty })
        return names.sorted()
    }

    private var filteredItems: [AssetItem] {
        var result = store.items
        if let statusFilter { result = result.filter { $0.status == statusFilter } }
        // 分类被删除后，残留的过滤条件自动失效，避免台账"假空"
        if categoryFilter != allCategoriesSentinel, categories.contains(categoryFilter) {
            result = result.filter { $0.category == categoryFilter }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.brand.localizedCaseInsensitiveContains(query)
                    || $0.location.localizedCaseInsensitiveContains(query)
            }
        }
        return result.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        Group {
            if store.items.isEmpty {
                emptyState
            } else {
                HSplitView {
                    listColumn
                        .frame(minWidth: 300, idealWidth: 370, maxWidth: 520, maxHeight: .infinity)
                    detailColumn
                        .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                filterBar
                Menu {
                    Button("管理分类…") {
                        showingCategoryManage = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .help("更多")
                Button {
                    showingQuickEntry = true
                } label: {
                    Label("快速录入", systemImage: "bolt.fill")
                }
                .help("回车保存并继续，收拾房间连录一批")
                Button {
                    showingNewForm = true
                } label: {
                    Label("新增物品", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewForm) {
            ItemFormView(
                prefillCategory: store.quickCategory,
                prefillLocation: store.quickLocation
            ) { item in
                store.add(item)
                selectedId = item.id
            }
            .frame(minWidth: 560, minHeight: 620)
        }
        .sheet(isPresented: $showingQuickEntry) {
            QuickEntryView(store: store)
                .frame(minWidth: 500, minHeight: 520)
        }
        .sheet(isPresented: $showingCategoryManage) {
            CategoryManageView(categoryStore: categoryStore, itemStore: store)
                .frame(minWidth: 460, minHeight: 560)
        }
        .sheet(item: $editingTarget) { item in
            ItemFormView(item: item) { updated in
                store.update(updated)
            }
            .frame(minWidth: 560, minHeight: 620)
        }
        .confirmationDialog("确认删除",
                            isPresented: Binding(
                                get: { deleteTarget != nil },
                                set: { if !$0 { deleteTarget = nil } }),
                            titleVisibility: .visible,
                            presenting: deleteTarget) { item in
            Button("删除「\(item.name)」", role: .destructive) {
                if selectedId == item.id { selectedId = nil }
                store.delete(item)
            }
            Button("取消", role: .cancel) {}
        } message: { item in
            Text("物品档案将从台账移除，关联的照片文件也会一并清理。")
        }
    }

    // MARK: - 工具栏过滤

    @ViewBuilder
    private var filterBar: some View {
        Picker("状态", selection: $statusFilter) {
            Text("全部状态").tag(ItemStatus?.none)
            ForEach(ItemStatus.allCases) { status in
                Text(status.rawValue).tag(ItemStatus?.some(status))
            }
        }
        .pickerStyle(.menu)
        .frame(width: 104)
        .help("按状态过滤")

        Picker("分类", selection: $categoryFilter) {
            Text(allCategoriesSentinel).tag(allCategoriesSentinel)
            ForEach(categories, id: \.self) { Text($0).tag($0) }
        }
        .pickerStyle(.menu)
        .frame(width: 120)
        .help("按分类过滤")

        TextField("搜索名称 / 品牌 / 位置", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .frame(width: 190)
    }

    // MARK: - 空态

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("台账还是空的").font(.title3.weight(.semibold))
            Text("从第一件物品开始，建立你的个人资产台账。")
                .foregroundStyle(.secondary)
            Button {
                showingNewForm = true
            } label: {
                Label("录入第一件物品", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            Button {
                showingQuickEntry = true
            } label: {
                Label("或用「快速录入」连录一批", systemImage: "bolt.fill")
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 左列：物品列表

    private var listColumn: some View {
        VStack(spacing: 0) {
            if filteredItems.isEmpty {
                noMatchHint
            } else {
                List(selection: $selectedId) {
                    ForEach(filteredItems) { item in
                        ItemRow(item: item)
                            .tag(item.id)
                            .contextMenu { rowMenu(item) }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                footerCount
            }
            Divider()
            quickAddBar
        }
    }

    /// 极速录入栏：输名称回车即存，沿用上次分类/位置
    private var quickAddBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.orange)
            TextField("极速录入：输入名称按回车，自动沿用上次分类 / 位置", text: $quickName)
                .textFieldStyle(.plain)
                .onSubmit(performQuickAdd)
        }
        .padding(12)
        .background(.bar)
    }

    private func performQuickAdd() {
        let trimmed = quickName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = store.quickAdd(name: trimmed)
        quickName = ""
        selectedId = item.id
    }

    private var noMatchHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 30)).foregroundStyle(.tertiary)
            Text("没有匹配的物品").font(.subheadline).foregroundStyle(.secondary)
            Button("清除过滤条件") {
                searchText = ""
                statusFilter = nil
                categoryFilter = allCategoriesSentinel
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footerCount: some View {
        HStack {
            Spacer()
            Text("共 \(filteredItems.count) 件（含已退役）")
                .font(.caption).foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.vertical, 6)
        .background(.bar)
    }

    @ViewBuilder
    private func rowMenu(_ item: AssetItem) -> some View {
        Button("编辑档案") { editingTarget = item }
        Divider()
        ForEach(ItemStatus.allCases) { status in
            Button("标记为「\(status.rawValue)」") {
                store.setStatus(status, for: item.id)
            }
            .disabled(item.status == status)
        }
        Divider()
        Button("删除", role: .destructive) { deleteTarget = item }
    }

    // MARK: - 右栏：详情

    private var detailColumn: some View {
        Group {
            if let selectedId, let item = store.item(id: selectedId) {
                ItemDetailView(
                    item: item,
                    store: store,
                    onEdit: { editingTarget = item },
                    onDelete: { deleteTarget = item }
                )
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "sidebar.left").font(.system(size: 40)).foregroundStyle(.tertiary)
                    Text("在左侧选择一件物品查看档案").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - 列表行

struct ItemRow: View {
    let item: AssetItem
    @EnvironmentObject private var categoryStore: CategoryStore

    var body: some View {
        HStack(spacing: 10) {
            if let photo = item.photos.first {
                PhotoThumbView(photo: photo, width: 46, height: 34, maxPixel: 92)
            } else {
                PhotoPlaceholderView(width: 46, height: 34)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            StatusBadge(status: item.status)
        }
        .padding(.vertical, 2)
    }

    private var secondaryText: String {
        var parts: [String] = []
        if !item.category.isEmpty {
            parts.append("\(categoryStore.emoji(for: item.category)) \(item.category)")
        }
        if !item.brand.isEmpty { parts.append(item.brand) }
        if parts.isEmpty { parts.append("未填写分类") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - 状态徽章

struct StatusBadge: View {
    let status: ItemStatus

    private var tint: Color {
        switch status {
        case .inUse:   return .blue
        case .idle:    return .orange
        case .retired: return .gray
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundStyle(tint)
    }
}

// MARK: - 物品详情

struct ItemDetailView: View {
    let item: AssetItem
    @ObservedObject var store: ItemStore
    @EnvironmentObject private var categoryStore: CategoryStore
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var mainPhotoId: UUID?

    /// 从 store 实时读取，状态切换立即刷新
    private var live: AssetItem { store.item(id: item.id) ?? item }
    private var photos: [ItemPhoto] { live.photos }
    private var mainPhoto: ItemPhoto? {
        photos.first { $0.id == mainPhotoId } ?? photos.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if !photos.isEmpty {
                    photoGallery
                }
                statusPicker
                infoCard("基础信息") {
                    fieldRow("tag.fill", "分类", categoryDisplay)
                    fieldRow("mappin.and.ellipse", "存放位置", live.location)
                    fieldRow("wrench.and.screwdriver", "品牌型号", live.brand)
                    fieldRow("clock", "录入时间", live.createdAt.formatted(date: .abbreviated, time: .omitted))
                }
                infoCard("价值与购入") {
                    fieldRow("yensign.circle", "购入单价", live.purchasePrice > 0 ? MoneyFormat.yuan(live.purchasePrice) : "")
                    if live.quantity > 1 {
                        fieldRow("sum", "小计", MoneyFormat.yuan(live.totalValue))
                    }
                    fieldRow("calendar.badge.clock", "购入日期", dateText(live.purchaseDate))
                    fieldRow("cart", "购买渠道", live.purchaseChannel)
                    warrantyRow
                }
                infoCard("数量与到期") {
                    fieldRow("number.square", "数量", "×\(live.quantity)")
                    expiryRow
                }
                if !live.notes.isEmpty {
                    infoCard("备注") {
                        Text(live.notes)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Text("最近更新：\(live.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: item.id) {
            mainPhotoId = nil
        }
    }

    // MARK: 头部

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(live.name).font(.title2.bold())
            StatusBadge(status: live.status)
            Spacer()
            if let onEdit {
                Button("编辑档案") { onEdit() }
            }
            if let onDelete {
                Menu {
                    Button("删除物品档案", role: .destructive) { onDelete() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }

    // MARK: 照片

    private var photoGallery: some View {
        VStack(spacing: 8) {
            PhotoMainView(photo: mainPhoto!)
            if photos.count > 1 {
                HStack(spacing: 8) {
                    ForEach(photos) { photo in
                        PhotoThumbView(photo: photo, width: 64, height: 48, maxPixel: 128)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.accentColor,
                                                  lineWidth: photo.id == mainPhoto?.id ? 2 : 0)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { mainPhotoId = photo.id }
                    }
                }
            }
        }
    }

    // MARK: 状态与字段

    private var statusPicker: some View {
        Picker("状态", selection: Binding(
            get: { live.status },
            set: { store.setStatus($0, for: live.id) })) {
            ForEach(ItemStatus.allCases) { status in
                Text(status.rawValue).tag(status)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var warrantyRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "seal").foregroundStyle(.tint).frame(width: 18)
            Text("质保到期").font(.subheadline).foregroundStyle(.secondary).frame(width: 88, alignment: .leading)
            if let days = live.daysUntilWarrantyEnd, let until = live.warrantyUntil {
                Text(until.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                if (0...30).contains(days) {
                    Text("剩余 \(days) 天").font(.caption).foregroundStyle(.orange)
                } else if days < 0 {
                    Text("已过保").font(.caption).foregroundStyle(.tertiary)
                }
            } else {
                Text("—").font(.subheadline).foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    private var expiryRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "hourglass").foregroundStyle(.tint).frame(width: 18)
            Text("到期日").font(.subheadline).foregroundStyle(.secondary).frame(width: 88, alignment: .leading)
            if let days = live.daysUntilExpiry, let expiresAt = live.expiresAt {
                Text(expiresAt.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                ExpiryBadge(days: days)
            } else {
                Text("—").font(.subheadline).foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    private func infoCard(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        GroupBox(title) {
            VStack(alignment: .leading, spacing: 9) {
                content()
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fieldRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.tint).frame(width: 18)
            Text(label).font(.subheadline).foregroundStyle(.secondary).frame(width: 88, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(.subheadline)
                .foregroundStyle(value.isEmpty ? Color(nsColor: .tertiaryLabelColor) : .primary)
            Spacer()
        }
    }

    private var categoryDisplay: String {
        live.category.isEmpty ? "" : "\(categoryStore.emoji(for: live.category)) \(live.category)"
    }

    private func dateText(_ date: Date?) -> String {
        date?.formatted(date: .abbreviated, time: .omitted) ?? ""
    }
}

// MARK: - 到期徽章

struct ExpiryBadge: View {
    let days: Int

    private var text: String {
        if days < 0 { return "已过期 \(-days) 天" }
        if days == 0 { return "今天到期" }
        return "剩 \(days) 天"
    }

    private var tint: Color {
        switch days {
        case ..<8:  return .red
        case 8...30: return .orange
        default:    return .yellow
        }
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}

// MARK: - 详情大图

private struct PhotoMainView: View {
    let photo: ItemPhoto
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: 380)
        .frame(height: 210)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary, lineWidth: 0.5))
        .onAppear {
            if image == nil {
                image = PhotoStore.load(photo)
            }
        }
    }
}
