import SwiftUI

// MARK: - 资产看板（CEO 驾驶舱）
struct DashboardView: View {
    @ObservedObject var store: ItemStore
    @EnvironmentObject private var categoryStore: CategoryStore

    private var alertCount: Int {
        store.expiringSoon.count + store.warrantyExpiringSoon.count + store.idleItems.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("资产看板").font(.largeTitle.bold())

                // KPI 卡：数字是主角——数值居首，图标与标签退为次级行
                HStack(spacing: 16) {
                    statCard(title: "物品总数", value: "\(store.activeItems.count)", icon: "shippingbox")
                    statCard(title: "资产总值", value: MoneyFormat.yuan(store.totalActiveValue), icon: "yensign.circle")
                    statCard(title: "待处理提醒", value: "\(alertCount)", icon: "bell")
                    statCard(title: "已退役", value: "\(store.retiredItems.count)", icon: "archivebox")
                }

                // 风险预警三栏
                GroupBox("风险预警") {
                    HStack(alignment: .top, spacing: 24) {
                        alertColumn(title: "即将到期", icon: "hourglass", tint: .red,
                                    items: store.expiringSoon) { item in
                            alertRow(item) {
                                if let days = item.daysUntilExpiry { ExpiryBadge(days: days) }
                            }
                        }
                        alertColumn(title: "质保将过期", icon: "seal", tint: .orange,
                                    items: store.warrantyExpiringSoon) { item in
                            alertRow(item) {
                                if let days = item.daysUntilWarrantyEnd {
                                    Text("剩 \(days) 天")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        alertColumn(title: "闲置物品", icon: "moon.zzz", tint: .blue,
                                    items: store.idleItems) { item in
                            alertRow(item) {
                                Text("闲置").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 分类价值分布
                GroupBox("分类价值分布") {
                    if store.valueByCategory.isEmpty {
                        Text("录入物品后，这里会展示各分类的资产占比。")
                            .font(.caption).foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 14)
                    } else {
                        categoryBreakdown
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 最近录入
                GroupBox("最近录入") {
                    if store.recentItems.isEmpty {
                        Text("台账还是空的，去「物品台账」录入第一件物品。")
                            .font(.caption).foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 14)
                    } else {
                        recentList
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - KPI 卡（沿用卡片骨架：hairline + 极浅投影；数字居首，无彩色图标位）

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 0.5))
    }

    // MARK: - 风险预警列

    private func alertColumn(title: String, icon: String, tint: Color,
                             items: [AssetItem],
                             @ViewBuilder trailing: @escaping (AssetItem) -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                HStack(spacing: 6) {
                    Text(title).font(.subheadline.weight(.semibold))
                    if !items.isEmpty {
                        Text("\(items.count)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(tint.opacity(0.14), in: Capsule())
                            .foregroundStyle(tint)
                    }
                }
            } icon: {
                Image(systemName: icon).foregroundStyle(tint)
            }
            if items.isEmpty {
                Text("暂无")
                    .font(.caption).foregroundStyle(.tertiary)
                    .padding(.vertical, 2)
            } else {
                ForEach(items.prefix(5)) { item in
                    trailing(item)
                }
                if items.count > 5 {
                    Text("… 还有 \(items.count - 5) 项")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func alertRow(_ item: AssetItem,
                          @ViewBuilder trailing: @escaping () -> some View) -> some View {
        HStack(spacing: 8) {
            if let photo = item.photos.first {
                PhotoThumbView(photo: photo, width: 32, height: 24, maxPixel: 64)
            } else {
                PhotoPlaceholderView(width: 32, height: 24)
            }
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            trailing()
        }
    }

    // MARK: - 分类价值分布

    private var categoryBreakdown: some View {
        let rows = store.valueByCategory
        let maxValue = rows.first?.value ?? 1
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(rows, id: \.category) { row in
                HStack(spacing: 10) {
                    Text("\(categoryStore.emoji(for: row.category)) \(row.category)")
                        .font(.subheadline)
                        .frame(width: 104, alignment: .leading)
                        .lineLimit(1)
                    ProgressView(value: row.value, total: maxValue)
                        .tint(.accentColor)
                        .frame(height: 6)
                    Text(MoneyFormat.yuan(row.value))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 110, alignment: .trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }

    // MARK: - 最近录入

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(store.recentItems.prefix(5)) { item in
                HStack(spacing: 10) {
                    if let photo = item.photos.first {
                        PhotoThumbView(photo: photo, width: 40, height: 30, maxPixel: 80)
                    } else {
                        PhotoPlaceholderView(width: 40, height: 30)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.name).font(.subheadline.weight(.medium)).lineLimit(1)
                        Text([item.category, item.location].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    StatusBadge(status: item.status)
                    Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
    }
}
