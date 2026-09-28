import SwiftUI
import UniformTypeIdentifiers

/// 物品档案表单：新建 / 编辑共用。onSave 回调交由调用方决定 add 还是 update。
struct ItemFormView: View {

    private let onSave: (AssetItem) -> Void
    private let original: AssetItem?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryStore: CategoryStore

    @State private var name = ""
    @State private var categorySelection = CategoryStore.fallbackName
    @State private var location = ""
    @State private var brand = ""
    @State private var status: ItemStatus = .inUse
    @State private var priceText = ""
    @State private var purchaseDate: Date?
    @State private var purchaseChannel = ""
    @State private var warrantyUntil: Date?
    @State private var quantity = 1
    @State private var expiresAt: Date?
    @State private var notes = ""
    @State private var photos: [ItemPhoto] = []
    @State private var showImporter = false
    @State private var showImportFailure = false

    init(item: AssetItem? = nil,
         prefillCategory: String? = nil,
         prefillLocation: String? = nil,
         onSave: @escaping (AssetItem) -> Void) {
        self.onSave = onSave
        self.original = item
        if let item {
            _name = State(initialValue: item.name)
            _categorySelection = State(initialValue:
                item.category.isEmpty ? CategoryStore.fallbackName : item.category)
            _location = State(initialValue: item.location)
            _brand = State(initialValue: item.brand)
            _status = State(initialValue: item.status)
            _priceText = State(initialValue: item.purchasePrice > 0 ? String(item.purchasePrice) : "")
            _purchaseDate = State(initialValue: item.purchaseDate)
            _purchaseChannel = State(initialValue: item.purchaseChannel)
            _warrantyUntil = State(initialValue: item.warrantyUntil)
            _quantity = State(initialValue: item.quantity)
            _expiresAt = State(initialValue: item.expiresAt)
            _notes = State(initialValue: item.notes)
            _photos = State(initialValue: item.photos)
        } else if let prefillCategory, !prefillCategory.isEmpty {
            _categorySelection = State(initialValue: prefillCategory)
            _location = State(initialValue: prefillLocation ?? "")
        }
    }

    // MARK: - 校验

    private var parsedPrice: Double? {
        let text = priceText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return 0 }
        return Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && parsedPrice != nil
    }

    private var saveTitle: String { original == nil ? "添加物品" : "保存修改" }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Form {
                basicSection
                purchaseSection
                quantitySection
                photoSection
                notesSection
            }
            .formStyle(.grouped)
            Divider()
            footerBar
        }
        .frame(minWidth: 560, minHeight: 620)
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.image],
                      allowsMultipleSelection: true,
                      onCompletion: handleImport)
        .alert("所选文件无法导入为图片", isPresented: $showImportFailure) {
            Button("好", role: .cancel) {}
        }
    }

    // MARK: - 表单分区

    private var basicSection: some View {
        Section("基础信息") {
            TextField("名称 *", text: $name)
            CategoryPicker(selection: $categorySelection)
            TextField("存放位置（如：客厅电视柜第二层）", text: $location)
            TextField("品牌 / 型号", text: $brand)
            Picker("状态", selection: $status) {
                ForEach(ItemStatus.allCases) { status in
                    Label(status.rawValue, systemImage: status.symbolName).tag(status)
                }
            }
        }
    }

    private var purchaseSection: some View {
        Section("价值与购入") {
            HStack {
                TextField("购入单价", text: $priceText)
                    .multilineTextAlignment(.trailing)
                Text("元").foregroundStyle(.secondary)
            }
            if parsedPrice == nil {
                Text("价格格式不正确").font(.caption).foregroundStyle(.red)
            }
            ClearableDateField(label: "购入日期", date: $purchaseDate)
            TextField("购买渠道（如：京东 / 山姆 / 线下）", text: $purchaseChannel)
            ClearableDateField(label: "质保到期", date: $warrantyUntil)
        }
    }

    private var quantitySection: some View {
        Section("数量与到期") {
            Stepper(value: $quantity, in: 1...9999) {
                HStack {
                    Text("数量")
                    Spacer()
                    Text("×\(quantity)").monospacedDigit()
                }
            }
            ClearableDateField(label: "到期日（食品 / 药品 / 耗材）", date: $expiresAt)
        }
    }

    private var photoSection: some View {
        Section("照片") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)],
                      alignment: .leading, spacing: 10) {
                addPhotoButton
                ForEach(photos) { photo in
                    PhotoThumbView(photo: photo, width: 92, height: 68, maxPixel: 184)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var addPhotoButton: some View {
        Button {
            showImporter = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.secondary)
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.plus")
                    Text("导入照片").font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .frame(width: 92, height: 68)
        }
        .buttonStyle(.plain)
    }

    private var notesSection: some View {
        Section("备注") {
            TextEditor(text: $notes)
                .frame(minHeight: 64)
                .scrollContentBackground(.hidden)
        }
    }

    private var footerBar: some View {
        HStack {
            if let original {
                Text("更新时间：\(original.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            Spacer()
            Button("取消", role: .cancel) { dismiss() }
            Button(saveTitle, action: save)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(!canSave)
        }
        .padding(16)
    }

    // MARK: - 动作

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        var anyImported = false
        for url in urls {
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url),
                  let photo = PhotoStore.save(data: data) else { continue }
            photos.append(photo)
            anyImported = true
        }
        if !anyImported {
            showImportFailure = true
        }
    }

    private func save() {
        guard let price = parsedPrice, canSave else { return }
        var item = original ?? AssetItem(name: "")
        item.name = name.trimmingCharacters(in: .whitespaces)
        item.category = categorySelection
        item.location = location.trimmingCharacters(in: .whitespaces)
        item.brand = brand.trimmingCharacters(in: .whitespaces)
        item.status = status
        item.notes = notes
        item.purchasePrice = price
        item.purchaseDate = purchaseDate
        item.purchaseChannel = purchaseChannel.trimmingCharacters(in: .whitespaces)
        item.warrantyUntil = warrantyUntil
        item.quantity = quantity
        item.expiresAt = expiresAt
        item.photos = photos
        item.updatedAt = Date()
        if original != nil {
            item.retiredAt = status == .retired ? (original?.retiredAt ?? Date()) : nil
        }
        onSave(item)
        dismiss()
    }
}

// MARK: - 可清除日期选择器

struct ClearableDateField: View {
    let label: String
    @Binding var date: Date?

    var body: some View {
        HStack {
            if let date {
                DatePicker(label,
                           selection: Binding(get: { date }, set: { self.date = $0 }),
                           displayedComponents: .date)
                Button {
                    self.date = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("清除该日期")
            } else {
                Text(label).foregroundStyle(.secondary)
                Spacer()
                Button {
                    date = Date()
                } label: {
                    Label("未设置", systemImage: "calendar.badge.plus")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
