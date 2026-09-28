import SwiftUI

// MARK: - 方法论列表
struct MethodologyListView: View {
    @State private var selected: Methodology?

    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("方法论")
                    .font(.largeTitle.bold())
                Text("选择一种最契合当下状态的方法论，套用它生成你的断舍离计划模板。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(MethodologyData.all) { m in
                        MethodologyCard(methodology: m)
                            .contentShape(Rectangle())
                            .onTapGesture { selected = m }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(item: $selected) { m in
            MethodologyDetailView(methodology: m)
                .frame(minWidth: 560, minHeight: 560)
        }
    }
}

// MARK: - 方法论卡片
struct MethodologyCard: View {
    let methodology: Methodology

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(methodology.emoji).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(methodology.name).font(.headline)
                    Text(methodology.author).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Text(methodology.subtitle)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
            Divider()
            Label(methodology.criterion, systemImage: "ruler")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}

// MARK: - 方法论详情
struct MethodologyDetailView: View {
    let methodology: Methodology

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                GroupBox("核心理念") {
                    Text(methodology.philosophy)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                }
                GroupBox("关键法则") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(methodology.principles) { p in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.tint)
                                    .padding(.top, 6)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.title).font(.subheadline.weight(.semibold))
                                    Text(p.detail).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                infoGrid
                sourcesView
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Text(methodology.emoji).font(.system(size: 44))
            VStack(alignment: .leading, spacing: 4) {
                Text(methodology.name).font(.title2.bold())
                Text(methodology.subtitle).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var infoGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow(icon: "ruler", title: "判断标准", value: methodology.criterion)
            infoRow(icon: "person.2", title: "适合人群", value: methodology.audience)
            infoRow(icon: "doc.text", title: "计划模板", value: methodology.templateTitle)
        }
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.tint).frame(width: 20)
            Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Text(value).font(.subheadline)
            Spacer()
        }
    }

    private var sourcesView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("参考来源").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(methodology.sources, id: \.self) { s in
                Text("· \(s)").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
