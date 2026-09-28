import SwiftUI

/// 快速录入（收拾房间模式）：回车保存并继续，分类/位置自动记住上次的值，
/// 录完一批后点「完成」。全程键盘操作。
struct QuickEntryView: View {
    @ObservedObject var store: ItemStore
    @Environment(\.dismiss) private var dismiss

    @FocusState private var nameFocused: Bool
    @State private var name = ""
    @State private var priceText = ""
    @State private var quantity = 1
    @State private var status: ItemStatus = .inUse
    @State private var batchCount = 0
    @State private var lastSavedName = ""

    private var parsedPrice: Double? {
        let text = priceText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return 0 }
        return Double(text.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Form {
                Section {
                    TextField("物品名称", text: $name)
                        .focused($nameFocused)
                        .onSubmit(saveAndContinue)
                    HStack {
                        TextField("价格（可选）", text: $priceText)
                            .multilineTextAlignment(.trailing)
                        Text("元").foregroundStyle(.secondary)
                    }
                    if parsedPrice == nil {
                        Text("价格格式不正确").font(.caption).foregroundStyle(.red)
                    }
                    Stepper(value: $quantity, in: 1...9999) {
                        HStack {
                            Text("数量")
                            Spacer()
                            Text("×\(quantity)").monospacedDigit()
                        }
                    }
                } header: {
                    Text("本次录入")
                }

                Section {
                    CategoryPicker(selection: $store.quickCategory)
                    TextField("存放位置", text: $store.quickLocation)
                    Picker("状态", selection: $status) {
                        ForEach(ItemStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                } header: {
                    Text("默认值（自动记住，下批沿用）")
                }
            }
            .formStyle(.grouped)
            Divider()
            footer
        }
        .frame(minWidth: 480, minHeight: 480)
        .onAppear {
            nameFocused = true
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("快速录入").font(.title3.bold())
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill").font(.caption).foregroundStyle(.orange)
                Text("输入名称按回车即保存并继续，适合收拾房间时连录一批。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if batchCount > 0 {
                Text("本批已录入 \(batchCount) 件，最近：「\(lastSavedName)」")
                    .font(.caption).foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("完成 (Esc)") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button("保存并继续 (⏎)", action: saveAndContinue)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || parsedPrice == nil)
        }
        .padding(16)
    }

    private func saveAndContinue() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let price = parsedPrice else { return }
        let item = AssetItem(name: trimmed,
                             category: store.quickCategory,
                             location: store.quickLocation,
                             status: status,
                             purchasePrice: price,
                             quantity: quantity)
        store.add(item)
        batchCount += 1
        lastSavedName = trimmed
        name = ""
        priceText = ""
        quantity = 1
        nameFocused = true
    }
}
