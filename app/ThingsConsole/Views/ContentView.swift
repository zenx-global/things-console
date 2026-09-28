import SwiftUI

/// 主窗口：左侧菜单 + 右侧功能区的个人物品管理工作台。
/// 「工作台」区管资产（看板 / 台账 / 库存），「整理行动」区管处置（整理计划 / 方法论库）。
struct ContentView: View {
    @StateObject private var itemStore = ItemStore()
    @StateObject private var planStore = PlanStore()
    @StateObject private var categoryStore = CategoryStore()
    @StateObject private var companion = CompanionServer()
    @StateObject private var boxStore = BoxStore()
    @State private var selection: SidebarItem? = .dashboard
    @State private var corruptionAlertHandled = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("工作台 · Things Console") {
                    Label("资产看板", systemImage: "gauge.with.dots.needle.bottom.50percent")
                        .tag(SidebarItem.dashboard)
                    Label("物品台账", systemImage: "archivebox.fill")
                        .tag(SidebarItem.ledger)
                    Label("库存与到期", systemImage: "clock.badge.exclamationmark")
                        .tag(SidebarItem.inventory)
                    Label("手机速录", systemImage: "iphone.gen3")
                        .tag(SidebarItem.companion)
                    Label("数据与备份", systemImage: "externaldrive.fill")
                        .tag(SidebarItem.dataBackup)
                }
                Section("整理行动") {
                    Label("箱子清理", systemImage: "shippingbox.fill")
                        .tag(SidebarItem.boxes)
                    Label("整理计划", systemImage: "checklist")
                        .tag(SidebarItem.plans)
                    Label("方法论库", systemImage: "books.vertical.fill")
                        .tag(SidebarItem.methodologies)
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 215)
            .listStyle(.sidebar)
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView(store: itemStore)
            case .ledger:
                ItemLedgerView(store: itemStore)
            case .inventory:
                InventoryView(store: itemStore)
            case .companion:
                CompanionView(server: companion, store: itemStore, boxStore: boxStore)
            case .dataBackup:
                DataBackupView(store: itemStore, companion: companion, boxStore: boxStore)
            case .boxes:
                BoxDashboardView(boxStore: boxStore, itemStore: itemStore)
            case .plans:
                PlanListView(store: planStore)
            case .methodologies:
                MethodologyListView()
            case .none:
                Text("请从侧边栏选择").foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 980, minHeight: 620)
        .environmentObject(categoryStore)
        .alert("数据文件无法解析",
               isPresented: Binding(
                   get: { itemStore.dataCorruptionDetected && !corruptionAlertHandled },
                   set: { if !$0 { corruptionAlertHandled = true } })) {
            if let newest = BackupService.listBackups().first {
                Button("从最近备份恢复（\(newest.name)）") {
                    if let restored = try? BackupService.importItems(from: newest.url) {
                        itemStore.replaceAll(restored, copyingPhotosFrom: newest.url)
                    }
                    corruptionAlertHandled = true
                }
            }
            Button("前往数据与备份") {
                corruptionAlertHandled = true
                selection = .dataBackup
            }
            Button("暂不处理", role: .cancel) {
                corruptionAlertHandled = true
            }
        } message: {
            Text(corruptionMessage)
        }
    }

    private var corruptionMessage: String {
        var text = "台账文件损坏或内容异常，已进入保护状态：照片不会被清理，新数据不会覆盖原件。"
        if let url = itemStore.quarantinedFileURL {
            text += "损坏原件已隔离为 \(url.lastPathComponent)。"
        }
        text += "建议从最近备份恢复。"
        return text
    }
}

enum SidebarItem: Hashable {
    case dashboard, ledger, inventory, companion, boxes, dataBackup, plans, methodologies
}
