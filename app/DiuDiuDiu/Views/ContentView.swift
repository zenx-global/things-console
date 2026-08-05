import SwiftUI

/// 主窗口：侧边栏三区导航（仪表盘 / 方法论 / 我的计划）
struct ContentView: View {
    @StateObject private var store = PlanStore()
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            // MARK: 侧边栏
            List(selection: $selection) {
                Section("diu-diu-diu · 断舍离计划助手") {
                    Label("仪表盘", systemImage: "chart.pie.fill")
                        .tag(SidebarItem.dashboard)
                    Label("方法论", systemImage: "books.vertical.fill")
                        .tag(SidebarItem.methodologies)
                    Label("我的计划", systemImage: "checklist")
                        .tag(SidebarItem.plans)
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210)
            .listStyle(.sidebar)
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView(store: store)
            case .methodologies:
                MethodologyListView()
            case .plans:
                PlanListView(store: store)
            case .none:
                Text("请从侧边栏选择").foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .environmentObject(store)
    }
}

enum SidebarItem: Hashable {
    case dashboard, methodologies, plans
}
