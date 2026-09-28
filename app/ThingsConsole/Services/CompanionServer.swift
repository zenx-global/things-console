import AppKit
import CoreImage
import Foundation
import Network

// MARK: - HTTP 请求 / 响应

struct HTTPRequest {
    let method: String
    let path: String
    let query: [String: String]
    let body: Data

    enum Outcome {
        case incomplete
        case invalid(Int)
        case done(HTTPRequest)
    }

    /// 手机端 fetch 与 curl 都使用 Content-Length；分块编码直接拒绝
    static func parse(_ data: Data, maxBody: Int) -> Outcome {
        guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) else {
            return data.count > 32 * 1024 ? .invalid(400) : .incomplete
        }
        guard let headerText = String(data: data[data.startIndex ..< headerEnd.lowerBound], encoding: .utf8) else {
            return .invalid(400)
        }
        var lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return .invalid(400) }
        lines.removeFirst()
        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard parts.count >= 2 else { return .invalid(400) }
        let method = parts[0].uppercased()
        let target = parts[1]

        var headers: [String: String] = [:]
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }
        if let transfer = headers["transfer-encoding"], transfer.lowercased().contains("chunked") {
            return .invalid(501)
        }

        let (rawPath, rawQuery) = splitTarget(target)
        let path = rawPath.removingPercentEncoding ?? rawPath
        let query = parseQuery(rawQuery)

        switch method {
        case "GET", "HEAD":
            return .done(HTTPRequest(method: method, path: path, query: query, body: Data()))
        default:
            guard let lengthText = headers["content-length"], let length = Int(lengthText), length >= 0 else {
                return .invalid(411)
            }
            if length > maxBody { return .invalid(413) }
            let bodyStart = headerEnd.upperBound
            guard data.count - bodyStart >= length else { return .incomplete }
            let body = data.subdata(in: bodyStart ..< (bodyStart + length))
            return .done(HTTPRequest(method: method, path: path, query: query, body: body))
        }
    }

    private static func splitTarget(_ target: String) -> (String, String) {
        guard let mark = target.firstIndex(of: "?") else { return (target, "") }
        return (String(target[..<mark]), String(target[target.index(after: mark)...]))
    }

    private static func parseQuery(_ raw: String) -> [String: String] {
        guard !raw.isEmpty else { return [:] }
        var result: [String: String] = [:]
        for pair in raw.split(separator: "&") {
            let keyValue = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = String(keyValue[0]).replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String(keyValue[0])
            guard !key.isEmpty else { continue }
            let rawValue = keyValue.count > 1 ? String(keyValue[1]) : ""
            let value = rawValue.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? rawValue
            result[key] = value
        }
        return result
    }
}

struct HTTPResponse {
    var status: Int
    var contentType: String
    var body: Data

    static func html(_ text: String) -> HTTPResponse {
        HTTPResponse(status: 200, contentType: "text/html; charset=utf-8", body: Data(text.utf8))
    }

    static func text(_ status: Int, _ text: String) -> HTTPResponse {
        HTTPResponse(status: status, contentType: "text/plain; charset=utf-8", body: Data(text.utf8))
    }

    static func data(_ status: Int, _ type: String, _ data: Data) -> HTTPResponse {
        HTTPResponse(status: status, contentType: type, body: data)
    }

    static func json(_ status: Int, object: Any) -> HTTPResponse {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            return .text(500, "json encode failed")
        }
        return HTTPResponse(status: status, contentType: "application/json; charset=utf-8", body: data)
    }

    static func json<T: Encodable>(_ status: Int, encodable: T) -> HTTPResponse {
        guard let data = try? JSONEncoder().encode(encodable) else {
            return .text(500, "json encode failed")
        }
        return HTTPResponse(status: status, contentType: "application/json; charset=utf-8", body: data)
    }

    func serialized() -> Data {
        let head = "HTTP/1.1 \(status) \(Self.phrase(for: status))\r\n"
            + "Content-Type: \(contentType)\r\n"
            + "Content-Length: \(body.count)\r\n"
            + "Connection: close\r\n"
            + "Cache-Control: no-store\r\n\r\n"
        var data = Data(head.utf8)
        data.append(body)
        return data
    }

    private static func phrase(for status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 411: return "Length Required"
        case 413: return "Payload Too Large"
        case 500: return "Internal Server Error"
        case 501: return "Not Implemented"
        default: return "OK"
        }
    }
}

// MARK: - 手机端 DTO

struct ItemSummary: Encodable {
    let id: String
    let name: String
    let category: String
    let location: String
    let status: String
    let quantity: Int
    let createdAt: String
    let photos: [String]

    init(_ item: AssetItem) {
        let formatter = ISO8601DateFormatter()
        self.id = item.id.uuidString
        self.name = item.name
        self.category = item.category
        self.location = item.location
        self.status = item.status.rawValue
        self.quantity = item.quantity
        self.createdAt = formatter.string(from: item.createdAt)
        self.photos = item.photos.map(\.fileName)
    }
}

// MARK: - 连接处理器（非隔离，独立队列）

final class ConnectionHandler {
    private let connection: NWConnection
    private let api: CompanionAPI
    private let queue = DispatchQueue(label: "companion.connection", qos: .userInitiated)
    private var idleWork: DispatchWorkItem?
    private let maxBody = 10 * 1024 * 1024

    var onFinish: (() -> Void)?

    init(connection: NWConnection, api: CompanionAPI) {
        self.connection = connection
        self.api = api
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.finish() }
        }
        connection.start(queue: queue)
        armIdleTimer()
        receive(Data())
    }

    func cancel() {
        finish()
    }

    private func receive(_ buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            self.armIdleTimer()
            var buffer = buffer
            if let data { buffer.append(data) }
            if buffer.count > self.maxBody {
                return self.send(.text(413, "payload too large"))
            }
            switch HTTPRequest.parse(buffer, maxBody: self.maxBody) {
            case .done(let request):
                self.send(self.api.respond(to: request))
            case .incomplete where error == nil && !isComplete:
                self.receive(buffer)
            case .incomplete:
                self.finish()
            case .invalid(let status):
                self.send(.text(status, "bad request"))
            }
        }
    }

    private func send(_ response: HTTPResponse) {
        connection.send(content: response.serialized(), completion: .contentProcessed { [weak self] _ in
            self?.finish()
        })
    }

    /// 半开连接兜底：60s 无数据即断开
    private func armIdleTimer() {
        idleWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.finish() }
        idleWork = work
        queue.asyncAfter(deadline: .now() + 60, execute: work)
    }

    private func finish() {
        idleWork?.cancel()
        connection.cancel()
        onFinish?()
    }
}

// MARK: - API 路由（连接队列执行；台账读写跳主线程）

final class CompanionAPI {
    private weak var itemStore: ItemStore?
    private weak var categoryStore: CategoryStore?
    private weak var boxStore: BoxStore?
    private let onServed: () -> Void

    init(itemStore: ItemStore, categoryStore: CategoryStore, boxStore: BoxStore, onServed: @escaping () -> Void) {
        self.itemStore = itemStore
        self.categoryStore = categoryStore
        self.boxStore = boxStore
        self.onServed = onServed
    }

    func respond(to request: HTTPRequest) -> HTTPResponse {
        defer { onServed() }
        guard request.query["k"] == CompanionServer.token else { return .text(404, "not found") }
        switch (request.method, request.path) {
        case ("GET", "/"), ("HEAD", "/"):
            return .html(CompanionPage.html)
        case ("GET", "/api/bootstrap"):
            return bootstrap()
        case ("POST", "/api/items"):
            return addItem(request)
        case ("GET", "/api/recent"):
            return recent()
        case ("GET", let path) where path.hasPrefix("/api/photo/"):
            return photo(String(path.dropFirst("/api/photo/".count)))
        case ("GET", "/boxes"):
            return .html(CompanionBoxesPage.html)
        case ("GET", "/api/boxes"):
            return boxesList()
        case ("POST", let path) where path.hasPrefix("/api/boxes/") && path.hasSuffix("/time"):
            return addTime(idString: Self.boxID(from: path, suffix: "/time"), request)
        case ("POST", let path) where path.hasPrefix("/api/boxes/") && path.hasSuffix("/items"):
            return addBoxItem(idString: Self.boxID(from: path, suffix: "/items"), request)
        case ("GET", let path) where path.hasPrefix("/api/boxes/") && path.hasSuffix("/items"):
            return boxItems(idString: Self.boxID(from: path, suffix: "/items"))
        case ("PATCH", let path) where path.hasPrefix("/api/boxes/"):
            return patchBox(idString: Self.boxID(from: path, suffix: ""), request)
        case ("PATCH", let path) where path.hasPrefix("/api/items/"):
            return patchItem(idString: String(path.dropFirst("/api/items/".count)), request)
        case ("GET", "/api/staging"):
            return stagingList()
        case ("GET", "/api/exit"):
            return exitList()
        case ("POST", "/api/exit/execute"):
            return exitExecute(request)
        default:
            return .text(404, "not found")
        }
    }

    // MARK: 路由实现

    private func bootstrap() -> HTTPResponse {
        let payload: [String: Any] = onMain {
            var locations: [String] = []
            for item in self.itemStore?.recentItems ?? [] {
                let location = item.location.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !location.isEmpty, !locations.contains(location) else { continue }
                locations.append(location)
                if locations.count >= 8 { break }
            }
            return [
                "categories": (self.categoryStore?.categories ?? []).map { ["name": $0.name, "emoji": $0.emoji] },
                "quickCategory": self.itemStore?.quickCategory ?? "",
                "quickLocation": self.itemStore?.quickLocation ?? "",
                "locations": locations,
            ]
        }
        return .json(200, object: payload)
    }

    private struct NewItemPayload: Decodable {
        let name: String
        let category: String?
        let location: String?
        let quantity: Int?
        let photos: [String]?
    }

    private struct SaveReply: Encodable {
        let ok: Bool
        let item: ItemSummary
    }

    private func addItem(_ request: HTTPRequest) -> HTTPResponse {
        guard let payload = try? JSONDecoder().decode(NewItemPayload.self, from: request.body) else {
            return .text(400, "bad json")
        }
        let name = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .text(400, "empty name") }

        // 照片解码落盘留在连接队列（AppKit 图像解码不涉窗口服务，线程安全；文件名 UUID 不冲突）
        let photos = (payload.photos ?? []).prefix(4).compactMap { dataURL -> ItemPhoto? in
            let parts = dataURL.split(separator: ",", maxSplits: 1)
            let base64 = parts.count == 2 ? String(parts[1]) : dataURL
            guard let data = Data(base64Encoded: String(base64), options: .ignoreUnknownCharacters) else { return nil }
            return PhotoStore.save(data: data)
        }

        let created: ItemSummary = onMain {
            let store = self.itemStore
            let category = (payload.category?.isEmpty == false) ? payload.category! : (store?.quickCategory ?? "")
            let location = (payload.location?.isEmpty == false) ? payload.location! : (store?.quickLocation ?? "")
            let item = AssetItem(name: name,
                                 category: category,
                                 location: location,
                                 quantity: max(1, payload.quantity ?? 1),
                                 photos: photos)
            store?.add(item) // add 自带记住最近分类 / 位置
            return ItemSummary(item)
        }
        return .json(200, encodable: SaveReply(ok: true, item: created))
    }

    private func recent() -> HTTPResponse {
        let summaries: [ItemSummary] = onMain {
            (self.itemStore?.recentItems ?? []).prefix(20).map { ItemSummary($0) }
        }
        return .json(200, encodable: RecentReply(items: summaries))
    }

    private struct RecentReply: Encodable {
        let items: [ItemSummary]
    }

    private func photo(_ fileName: String) -> HTTPResponse {
        // 严格校验 UUID.jpg，杜绝路径穿越
        let pattern = "^[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}\\.jpg$"
        guard fileName.range(of: pattern, options: .regularExpression) != nil,
              let data = try? Data(contentsOf: PhotoStore.directory.appendingPathComponent(fileName)) else {
            return .text(404, "not found")
        }
        return .data(200, "image/jpeg", data)
    }

    // MARK: - 箱子清理（P1 Web 作业页）

    private static func boxID(from path: String, suffix: String) -> String {
        var trimmed = String(path.dropFirst("/api/boxes/".count))
        if !suffix.isEmpty, trimmed.hasSuffix(suffix) {
            trimmed = String(trimmed.dropLast(suffix.count))
        }
        return trimmed
    }

    private static let exitDispositions: [ItemDisposition] = [.trash, .donate, .sell]

    @MainActor
    private func pendingExitItems() -> [AssetItem] {
        (itemStore?.items ?? []).filter { item in
            item.status != .retired && (item.disposition.map { Self.exitDispositions.contains($0) } ?? false)
        }
    }

    private func boxesList() -> HTTPResponse {
        let payload: [String: Any] = onMain {
            let allItems = self.itemStore?.items ?? []
            let allBoxes = self.boxStore?.boxes ?? []
            let boxes = allBoxes.map { box -> [String: Any] in
                let boxItems = allItems.filter { $0.sourceBoxId == box.id }
                return [
                    "id": box.id.uuidString,
                    "label": box.label,
                    "status": box.status.rawValue,
                    "method": box.method,
                    "priority": box.priority,
                    "dominantCategory": box.dominantCategory,
                    "timeSpentSeconds": box.timeSpentSeconds,
                    "itemCount": boxItems.count,
                    "undecidedCount": boxItems.filter { $0.disposition == nil }.count,
                ] as [String: Any]
            }
            let staging = allItems.filter { item in
                item.status != .retired && item.disposition == .keep && item.location.hasPrefix("暂存")
            }.count
            return [
                "boxes": boxes,
                "stats": [
                    "total": allBoxes.count,
                    "completed": self.boxStore?.completedCount ?? 0,
                    "timeSpentSeconds": self.boxStore?.totalTimeSpentSeconds ?? 0,
                    "pendingExit": self.pendingExitItems().count,
                    "staging": staging,
                ],
            ]
        }
        return .json(200, object: payload)
    }

    private struct PatchBoxPayload: Decodable {
        let label: String?
        let status: String?
        let method: String?
    }

    private func patchBox(idString: String, _ request: HTTPRequest) -> HTTPResponse {
        guard let boxId = UUID(uuidString: idString),
              let payload = try? JSONDecoder().decode(PatchBoxPayload.self, from: request.body) else {
            return .text(400, "bad request")
        }
        let ok: Bool = onMain {
            guard let boxStore = self.boxStore, let box = boxStore.box(id: boxId) else { return false }
            var draft = box
            var changed = false
            if let label = payload.label, !label.isEmpty, label != draft.label {
                draft.label = label
                changed = true
            }
            if let method = payload.method, method != draft.method {
                draft.method = method
                changed = true
            }
            if changed { boxStore.update(draft) }
            if let status = payload.status.flatMap(BoxStatus.init(rawValue:)), status != box.status {
                boxStore.setStatus(status, for: boxId)
            }
            return true
        }
        return ok ? .json(200, object: ["ok": true]) : .text(404, "box not found")
    }

    private struct TimePayload: Decodable {
        let seconds: Int
    }

    private func addTime(idString: String, _ request: HTTPRequest) -> HTTPResponse {
        guard let boxId = UUID(uuidString: idString),
              let payload = try? JSONDecoder().decode(TimePayload.self, from: request.body),
              payload.seconds > 0, payload.seconds < 86_400 else {
            return .text(400, "bad seconds")
        }
        let ok: Bool = onMain {
            guard self.boxStore?.box(id: boxId) != nil else { return false }
            self.boxStore?.addTimeSpent(payload.seconds, to: boxId)
            return true
        }
        return ok ? .json(200, object: ["ok": true]) : .text(404, "box not found")
    }

    private func boxItems(idString: String) -> HTTPResponse {
        guard let boxId = UUID(uuidString: idString) else { return .text(404, "not found") }
        let payload: [String: Any] = onMain {
            let dtos = (self.itemStore?.items(inBox: boxId) ?? []).map { item -> [String: Any] in
                [
                    "id": item.id.uuidString,
                    "name": item.name,
                    "category": item.category,
                    "location": item.location,
                    "disposition": item.disposition?.rawValue ?? NSNull(),
                ]
            }
            return ["items": dtos]
        }
        return .json(200, object: payload)
    }

    private struct NewBoxItemPayload: Decodable {
        let name: String
        let disposition: String?
        let location: String?
    }

    private func addBoxItem(idString: String, _ request: HTTPRequest) -> HTTPResponse {
        guard let boxId = UUID(uuidString: idString),
              let payload = try? JSONDecoder().decode(NewBoxItemPayload.self, from: request.body) else {
            return .text(400, "bad request")
        }
        let name = payload.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .text(400, "empty name") }
        let dto: [String: Any] = onMain {
            let store = self.itemStore
            let location = (payload.location?.isEmpty == false) ? payload.location! : (store?.quickLocation ?? "")
            let item = AssetItem(name: name,
                                 category: store?.quickCategory ?? "",
                                 location: location,
                                 sourceBoxId: boxId,
                                 disposition: ItemDisposition(rawValue: payload.disposition ?? ""))
            store?.add(item)
            return [
                "id": item.id.uuidString,
                "name": item.name,
                "location": item.location,
                "disposition": item.disposition?.rawValue ?? NSNull(),
            ]
        }
        return .json(200, object: dto)
    }

    /// PATCH 语义：disposition 字段缺失 = 不动，显式 null = 清空；location 同理
    private struct PatchItemPayload: Decodable {
        let disposition: ItemDisposition??
        let location: String??
        let category: String?

        enum CodingKeys: String, CodingKey { case disposition, location, category }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            disposition = container.contains(.disposition)
                ? .some(try container.decodeIfPresent(ItemDisposition.self, forKey: .disposition))
                : .none
            location = container.contains(.location)
                ? .some(try container.decodeIfPresent(String.self, forKey: .location))
                : .none
            category = try container.decodeIfPresent(String.self, forKey: .category)
        }
    }

    private func patchItem(idString: String, _ request: HTTPRequest) -> HTTPResponse {
        guard let itemId = UUID(uuidString: idString),
              let payload = try? JSONDecoder().decode(PatchItemPayload.self, from: request.body) else {
            return .text(400, "bad request")
        }
        let ok: Bool = onMain {
            guard let store = self.itemStore, store.item(id: itemId) != nil else { return false }
            if let dispositionChange = payload.disposition {
                store.setDisposition(dispositionChange, for: itemId)
            }
            if let locationChange = payload.location {
                store.setLocation(locationChange ?? "", for: itemId)
            }
            if let category = payload.category {
                store.setCategory(category, for: itemId)
            }
            return true
        }
        return ok ? .json(200, object: ["ok": true]) : .text(404, "item not found")
    }

    private func stagingList() -> HTTPResponse {
        let payload: [String: Any] = onMain {
            let items = (self.itemStore?.items ?? []).filter { item in
                item.status != .retired && item.location.hasPrefix("暂存")
            }
            let names = Array(Set(items.map(\.location))).sorted()
            let groups = names.map { name -> [String: Any] in
                let groupItems = items.filter { $0.location == name }
                return [
                    "location": name,
                    "count": groupItems.count,
                    "items": groupItems.map { item -> [String: Any] in
                        [
                            "id": item.id.uuidString,
                            "name": item.name,
                            "category": item.category,
                            "disposition": item.disposition?.rawValue ?? NSNull(),
                        ]
                    },
                ]
            }
            return ["groups": groups, "total": items.count]
        }
        return .json(200, object: payload)
    }

    private func exitList() -> HTTPResponse {
        let payload: [String: Any] = onMain {
            let candidates = self.pendingExitItems()
            let groups = Self.exitDispositions.map { disposition -> [String: Any] in
                let groupItems = candidates.filter { $0.disposition == disposition }
                return [
                    "disposition": disposition.rawValue,
                    "count": groupItems.count,
                    "items": groupItems.map { item -> [String: Any] in
                        ["id": item.id.uuidString, "name": item.name, "location": item.location]
                    },
                ]
            }
            return ["groups": groups, "total": candidates.count]
        }
        return .json(200, object: payload)
    }

    private struct ExitExecutePayload: Decodable {
        let ids: [String]?
    }

    private func exitExecute(_ request: HTTPRequest) -> HTTPResponse {
        let payload = (try? JSONDecoder().decode(ExitExecutePayload.self, from: request.body))
            ?? ExitExecutePayload(ids: nil)
        let count: Int = onMain {
            guard let store = self.itemStore else { return 0 }
            let targets: [UUID]
            if let ids = payload.ids {
                targets = ids.compactMap { UUID(uuidString: $0) }
            } else {
                targets = self.pendingExitItems().map(\.id)
            }
            for id in targets { store.setStatus(.retired, for: id) }
            return targets.count
        }
        return .json(200, object: ["ok": true, "count": count])
    }

    // MARK: 主线程跳转

    private func onMain<T>(_ body: @MainActor () -> T) -> T {
        if Thread.isMainThread {
            return MainActor.assumeIsolated(body)
        }
        return DispatchQueue.main.sync {
            MainActor.assumeIsolated(body)
        }
    }
}

// MARK: - 服务主体

@MainActor
final class CompanionServer: ObservableObject {

    static let preferredPort: UInt16 = 8787
    private static let tokenKey = "things-console.companion.token.v1"

    @Published private(set) var isRunning = false
    @Published private(set) var port: UInt16?
    @Published private(set) var urls: [URL] = []
    @Published private(set) var servedCount = 0
    @Published private(set) var lastError: String?

    private var listener: NWListener?
    private var handlers: [ConnectionHandler] = []
    private var api: CompanionAPI?

    func start(itemStore: ItemStore, categoryStore: CategoryStore, boxStore: BoxStore) {
        guard !isRunning else { return }
        lastError = nil
        let api = CompanionAPI(itemStore: itemStore, categoryStore: categoryStore, boxStore: boxStore) { [weak self] in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.servedCount += 1
                }
            }
        }
        self.api = api
        tryPort(Self.preferredPort, attempt: 0)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        api = nil
        for handler in handlers { handler.cancel() }
        handlers.removeAll()
        isRunning = false
        port = nil
        urls = []
    }

    private func tryPort(_ portNumber: UInt16, attempt: Int) {
        guard let endpoint = NWEndpoint.Port(rawValue: portNumber) else {
            lastError = "没有可用端口"
            return
        }
        let listener: NWListener
        do {
            listener = try NWListener(using: .tcp, on: endpoint)
        } catch {
            lastError = "端口 \(portNumber) 不可用：\(error.localizedDescription)"
            return
        }
        // 监听器回调统一走主队列，方便在 MainActor 上下文里维护状态
        listener.newConnectionHandler = { [weak self] connection in
            MainActor.assumeIsolated {
                self?.accept(connection)
            }
        }
        listener.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.handle(state, portNumber: portNumber, attempt: attempt)
                }
            }
        }
        self.listener = listener
        listener.start(queue: .main)
    }

    private func handle(_ state: NWListener.State, portNumber: UInt16, attempt: Int) {
        switch state {
        case .ready:
            isRunning = true
            port = portNumber
            urls = Self.localIPv4Addresses().map {
                URL(string: "http://\($0.ip):\(portNumber)/?k=\(Self.token)")
                    ?? URL(string: "http://127.0.0.1:\(portNumber)/?k=\(Self.token)")!
            }
        case .failed(let error):
            listener?.cancel()
            listener = nil
            if case .posix(.EADDRINUSE) = error, attempt < 10 {
                tryPort(portNumber + 1, attempt: attempt + 1)
            } else {
                isRunning = false
                lastError = "启动失败：\(error)"
            }
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        guard let api else {
            connection.cancel()
            return
        }
        let handler = ConnectionHandler(connection: connection, api: api)
        handler.onFinish = { [weak self, weak handler] in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self, let handler else { return }
                    self.handlers.removeAll { $0 === handler }
                }
            }
        }
        handlers.append(handler)
        handler.start()
    }

    // MARK: 配对密钥

    nonisolated static var token: String {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey: tokenKey), !saved.isEmpty { return saved }
        let generated = String(UUID().uuidString.prefix(8)).lowercased()
        defaults.set(generated, forKey: tokenKey)
        return generated
    }

    // MARK: 局域网地址

    static func localIPv4Addresses() -> [(interface: String, ip: String)] {
        var results: [(interface: String, ip: String)] = []
        var addressList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addressList) == 0, let first = addressList else { return results }
        defer { freeifaddrs(addressList) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let entry = cursor {
            defer { cursor = entry.pointee.ifa_next }
            guard let socketAddress = entry.pointee.ifa_addr,
                  socketAddress.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: entry.pointee.ifa_name)
            guard name != "lo0" else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(socketAddress, socklen_t(socketAddress.pointee.sa_len),
                              &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let ip = String(cString: host)
            if !ip.isEmpty { results.append((name, ip)) }
        }

        func rank(_ entry: (interface: String, ip: String)) -> Int {
            if entry.interface == "en0" { return 0 }
            if entry.interface.hasPrefix("en") { return 1 }
            return 2
        }
        return results.sorted { lhs, rhs in
            let (leftRank, rightRank) = (rank(lhs), rank(rhs))
            return leftRank != rightRank ? leftRank < rightRank : lhs.interface < rhs.interface
        }
    }

    // MARK: 二维码

    static func qrCodeImage(for text: String) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
