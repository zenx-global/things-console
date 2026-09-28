import SwiftUI

/// 分类管理：新增 / 重命名 / 换图标 / 删除（删除时该分类下的物品迁入「其他」）。
struct CategoryManageView: View {
    @ObservedObject var categoryStore: CategoryStore
    @ObservedObject var itemStore: ItemStore

    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""
    @State private var newEmoji = "🏷️"
    @State private var addError: String?

    @State private var editingName: String?
    @State private var editName = ""
    @State private var editEmoji = ""
    @State private var renameError: String?

    @State private var deleteTarget: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(categoryStore.categories) { category in
                        row(category)
                        Divider().padding(.leading, 52)
                    }
                    addRow
                }
                .padding(.vertical, 6)
            }
            Divider()
            footer
        }
        .frame(minWidth: 460, minHeight: 560)
        .confirmationDialog("删除分类",
                            isPresented: Binding(
                                get: { deleteTarget != nil },
                                set: { if !$0 { deleteTarget = nil } }),
                            titleVisibility: .visible,
                            presenting: deleteTarget) { name in
            let count = itemStore.usageCount(ofCategory: name)
            Button(count > 0 ? "删除并把 \(count) 件物品归入「其他」" : "删除「\(name)」", role: .destructive) {
                performDelete(name)
            }
            Button("取消", role: .cancel) {}
        } message: { name in
            Text("「\(name)」将从分类注册表移除；物品档案不会被删除。")
        }
    }

    // MARK: - 头尾

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("分类管理").font(.title3.bold())
            Text("按个人物品整理最佳实践预设；可随时补充自己的分类。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }

    private var footer: some View {
        HStack {
            Text("共 \(categoryStore.categories.count) 个分类")
                .font(.caption).foregroundStyle(.tertiary)
            Spacer()
            Button("完成") { dismiss() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    // MARK: - 分类行

    private func row(_ category: ItemCategory) -> some View {
        Group {
            if editingName == category.name {
                editRow(category)
            } else {
                HStack(spacing: 10) {
                    Text(category.emoji).font(.title3)
                    Text(category.name).font(.body.weight(.medium))
                    if CategoryStore.builtIn.contains(where: { $0.name == category.name }) {
                        Text("预设")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }
                    Spacer()
                    Text("\(itemStore.usageCount(ofCategory: category.name)) 件")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button("重命名") {
                        editingName = category.name
                        editName = category.name
                        editEmoji = category.emoji
                        renameError = nil
                    }
                    .buttonStyle(.borderless)
                    Button("删除", role: .destructive) {
                        deleteTarget = category.name
                    }
                    .buttonStyle(.borderless)
                    .disabled(category.name == CategoryStore.fallbackName)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
    }

    private func editRow(_ category: ItemCategory) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField("图标", text: $editEmoji)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                TextField("分类名称", text: $editName)
                    .onSubmit(commitRename)
                Button("保存") { commitRename() }
                    .buttonStyle(.borderless)
                    .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("取消") {
                    editingName = nil
                }
                .buttonStyle(.borderless)
            }
            if let renameError {
                Text(renameError).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func commitRename() {
        guard let original = editingName else { return }
        if categoryStore.rename(name: original, to: editName, emoji: editEmoji) {
            itemStore.migrateCategory(original, to: editName.trimmingCharacters(in: .whitespaces))
            editingName = nil
        } else {
            renameError = "保存失败：分类名为空或与现有分类重名"
        }
    }

    // MARK: - 新增行

    private var addRow: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField("图标", text: $newEmoji)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                TextField("新分类名称", text: $newName)
                    .onSubmit(addCategory)
                Button {
                    addCategory()
                } label: {
                    Label("添加", systemImage: "plus")
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let addError {
                Text(addError).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func addCategory() {
        if categoryStore.add(name: newName, emoji: newEmoji) {
            newName = ""
            newEmoji = "🏷️"
            addError = nil
        } else {
            addError = "添加失败：分类名为空或已存在"
        }
    }

    // MARK: - 删除

    private func performDelete(_ name: String) {
        itemStore.migrateCategory(name, to: CategoryStore.fallbackName)
        categoryStore.remove(name: name)
    }
}
