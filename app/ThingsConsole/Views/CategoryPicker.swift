import SwiftUI

/// 分类选择器：下拉列出注册表全部分类（带 emoji），底部「＋ 新建分类…」内联即建即选。
struct CategoryPicker: View {
    var label: String = "分类"
    @Binding var selection: String
    @EnvironmentObject private var categoryStore: CategoryStore

    @State private var isAdding = false
    @State private var newName = ""
    @State private var newEmoji = "🏷️"
    @State private var errorMessage: String?

    private static let addSentinel = "__add_category__"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(label, selection: $selection) {
                ForEach(categoryStore.categories) { category in
                    Text("\(category.emoji) \(category.name)").tag(category.name)
                }
                Divider()
                Text("＋ 新建分类…").tag(Self.addSentinel)
            }
            .onChange(of: selection) {
                if selection == Self.addSentinel {
                    beginAdding()
                }
            }

            if isAdding {
                addRow
            }
        }
    }

    private func beginAdding() {
        // 从「＋ 新建分类…」弹回当前有效选项，再展开内联输入
        if !categoryStore.contains(name: selection) {
            selection = categoryStore.contains(name: "其他") ? CategoryStore.fallbackName
                : (categoryStore.categories.first?.name ?? CategoryStore.fallbackName)
        }
        newName = ""
        newEmoji = "🏷️"
        errorMessage = nil
        isAdding = true
    }

    @ViewBuilder
    private var addRow: some View {
        HStack(spacing: 8) {
            TextField("图标", text: $newEmoji)
                .frame(width: 44)
                .multilineTextAlignment(.center)
            TextField("分类名称", text: $newName)
                .onSubmit(commit)
            Button("添加") { commit() }
                .buttonStyle(.borderless)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button {
                isAdding = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("取消")
        }
        if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func commit() {
        if categoryStore.add(name: newName, emoji: newEmoji) {
            selection = newName.trimmingCharacters(in: .whitespaces)
            isAdding = false
        } else {
            errorMessage = "添加失败：分类名为空或已存在"
        }
    }
}
