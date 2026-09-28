import SwiftUI

/// 库存与到期：预警中心。到期、质保、数量三区。
struct InventoryView: View {
    @ObservedObject var store: ItemStore
    @EnvironmentObject private var categoryStore: CategoryStore

    @State private var detailTarget: AssetItem?

    private var multiQuantityItems: [AssetItem] {
        store.activeItems.filter { $0.quantity > 1 }
            .sorted { $0.totalValue > $1.totalValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("库存与到期").font(.largeTitle.bold())
                summaryChips
                expiringCard
                warrantyCard
                quantityCard
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(item: $detailTarget) { target in
            if let live = store.item(id: target.id) {
                ItemDetailView(item: live, store: store)
                    .frame(minWidth: 620, minHeight: 660)
            } else {
                Text("该物品已不存在").padding()
            }
        }
    }

    // MARK: - 概览条

    private var summaryChips: some View {
        HStack(spacing: 12) {
            chip(icon: "hourglass", count: store.expiringSoon.count, label: "到期预警", tint: .red)
            chip(icon: "seal", count: store.warrantyExpiringSoon.count, label: "质保将过期", tint: .orange)
            chip(icon: "moon.zzz", count: store.idleItems.count, label: "闲置物品", tint: .blue)
            chip(icon: "shippingbox", count: multiQuantityItems.count, label: "多数量物品", tint: .purple)
        }
    }

    private func chip(icon: String, count: Int, label: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint)
            Text("\(count)").font(.headline.monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.background, in: Capsule())
        .overlay(Capsule().strokeBorder(.quaternary, lineWidth: 0.5))
    }

    // MARK: - 即将到期

    @ViewBuilder
    private var expiringCard: some View {
        GroupBox("即将到期（30 天内，含已过期）") {
            if store.expiringSoon.isEmpty {
                emptyHint("没有即将到期的物品")
            } else {
                VStack(spacing: 0) {
                    ForEach(store.expiringSoon) { item in
                        rowButton(item) {
                            HStack(spacing: 10) {
                                rowThumbnail(item)
                                rowTitle(item)
                                Spacer()
                                if let days = item.daysUntilExpiry {
                                    ExpiryBadge(days: days)
                                }
                            }
                        }
                    }
                }
                .padding(2)
            }
        }
    }

    // MARK: - 质保将过期

    @ViewBuilder
    private var warrantyCard: some View {
        GroupBox("质保将过期（30 天内）") {
            if store.warrantyExpiringSoon.isEmpty {
                emptyHint("暂无临期质保")
            } else {
                VStack(spacing: 0) {
                    ForEach(store.warrantyExpiringSoon) { item in
                        rowButton(item) {
                            HStack(spacing: 10) {
                                rowThumbnail(item)
                                rowTitle(item)
                                Spacer()
                                if let days = item.daysUntilWarrantyEnd {
                                    Text("剩余 \(days) 天")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
                .padding(2)
            }
        }
    }

    // MARK: - 数量管理

    @ViewBuilder
    private var quantityCard: some View {
        GroupBox("数量管理") {
            if multiQuantityItems.isEmpty {
                emptyHint("没有多数量物品；在档案中把数量设为大于 1 即可在此快速增减")
            } else {
                VStack(spacing: 0) {
                    ForEach(multiQuantityItems) { item in
                        HStack(spacing: 10) {
                            rowThumbnail(item)
                            rowTitle(item)
                            Spacer()
                            Text(MoneyFormat.yuan(item.totalValue))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            quantityStepper(item)
                        }
                        .padding(.vertical, 7)
                    }
                }
                .padding(2)
            }
        }
    }

    private func quantityStepper(_ item: AssetItem) -> some View {
        HStack(spacing: 4) {
            Button {
                store.adjustQuantity(-1, for: item.id)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .disabled(item.quantity <= 1)
            .help("减一")

            Text("×\(item.quantity)")
                .font(.body.monospacedDigit())
                .frame(minWidth: 30)

            Button {
                store.adjustQuantity(1, for: item.id)
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.borderless)
            .help("加一")
        }
    }

    // MARK: - 行组件

    private func rowThumbnail(_ item: AssetItem) -> some View {
        Group {
            if let photo = item.photos.first {
                PhotoThumbView(photo: photo, width: 40, height: 30, maxPixel: 80)
            } else {
                PhotoPlaceholderView(width: 40, height: 30)
            }
        }
    }

    private func rowTitle(_ item: AssetItem) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(item.name).font(.subheadline.weight(.medium)).lineLimit(1)
            Text(secondaryText(item))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func secondaryText(_ item: AssetItem) -> String {
        var parts: [String] = []
        if !item.category.isEmpty {
            parts.append("\(categoryStore.emoji(for: item.category)) \(item.category)")
        }
        if !item.location.isEmpty { parts.append(item.location) }
        return parts.joined(separator: " · ")
    }

    private func rowButton<Content: View>(_ item: AssetItem, @ViewBuilder content: () -> Content) -> some View {
        Button {
            detailTarget = item
        } label: {
            content()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6).fill(Color.clear)
        )
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 14)
    }
}
