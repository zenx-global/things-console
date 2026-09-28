import SwiftUI

/// 手机速录：开启局域网服务、扫码或复制链接，手机上打开速录页直接写入台账。
struct CompanionView: View {
    @ObservedObject var server: CompanionServer
    @ObservedObject var store: ItemStore
    @ObservedObject var boxStore: BoxStore
    @EnvironmentObject private var categoryStore: CategoryStore

    @State private var selectedURLIndex = 0
    @State private var entryBoxes = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("手机速录").font(.largeTitle.bold())
                serviceCard
                if server.isRunning {
                    qrCard
                }
                tipsCard
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: 服务开关

    private var serviceCard: some View {
        GroupBox("服务") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Button {
                        if server.isRunning {
                            server.stop()
                        } else {
                            server.start(itemStore: store, categoryStore: categoryStore, boxStore: boxStore)
                        }
                    } label: {
                        Label(server.isRunning ? "关闭服务" : "开启服务",
                              systemImage: server.isRunning ? "stop.circle.fill" : "play.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(server.isRunning ? .secondary : .accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        if server.isRunning {
                            Text("服务运行中 · 端口 \(server.port.map(String.init) ?? "—") · 已响应 \(server.servedCount) 次")
                                .font(.subheadline.monospacedDigit())
                            Text("手机与 Mac 连接同一 Wi-Fi 即可使用")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("服务未开启")
                                .font(.subheadline)
                            Text("开启后 Mac 会在局域网内提供一个速录页面，凭密钥访问")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                if let error = server.lastError {
                    Text(error)
                        .font(.caption).foregroundStyle(.red)
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: 扫码连接

    private var qrCard: some View {
        GroupBox("扫码连接") {
            VStack(spacing: 14) {
                Picker("入口", selection: $entryBoxes) {
                    Text("速录页").tag(false)
                    Text("箱子作业页").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                HStack(alignment: .top, spacing: 24) {
                if let url = currentURL, let image = CompanionServer.qrCodeImage(for: url.absoluteString) {
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 168, height: 168)
                        .padding(6)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.secondary.opacity(0.3)))
                }
                VStack(alignment: .leading, spacing: 10) {
                    if server.urls.count > 1 {
                        Picker("访问地址", selection: $selectedURLIndex) {
                            ForEach(Array(server.urls.enumerated()), id: \.offset) { index, url in
                                Text(url.host ?? url.absoluteString).tag(index)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.radioGroup)
                    }
                    if let url = currentURL {
                        Text(url.absoluteString)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                        HStack(spacing: 10) {
                            Button("复制链接") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(url.absoluteString, forType: .string)
                            }
                            .buttonStyle(.borderless)
                            Text("手机浏览器打开后，可「添加到主屏幕」随时进入")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                    Spacer()
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var currentURL: URL? {
        guard server.urls.indices.contains(selectedURLIndex) else { return server.urls.first }
        let base = server.urls[selectedURLIndex]
        guard entryBoxes, var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }
        components.path = "/boxes"
        return components.url ?? base
    }

    // MARK: 使用提示

    private var tipsCard: some View {
        GroupBox("使用提示") {
            VStack(alignment: .leading, spacing: 6) {
                tipRow("手机与这台 Mac 连接同一个 Wi-Fi。")
                tipRow("用相机扫码，或直接输入链接；页面可「添加到主屏幕」。")
                tipRow("首次开启时，系统可能询问是否允许接受局域网连接，选择允许。")
                tipRow("页面仅在本机局域网内可用，访问需配对密钥，数据不经过云端。")
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.tint)
                .font(.caption)
                .padding(.top, 2)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
