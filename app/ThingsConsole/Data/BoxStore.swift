import Foundation
import SwiftUI

/// 清理箱的持久化与状态管理。模式与 ItemStore 一致：
/// @MainActor + ObservableObject + Application Support/ThingsConsole/boxes.json 原子写入。
@MainActor
final class BoxStore: ObservableObject {

    @Published private(set) var boxes: [CleanupBox] = []

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    nonisolated static let dataFileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ThingsConsole", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("boxes.json")
    }()

    private let fileURL: URL

    init(fileURL: URL = BoxStore.dataFileURL) {
        self.fileURL = fileURL
        load()
    }

    // MARK: - 读取 / 持久化

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else { return }
        boxes = (try? decoder.decode([CleanupBox].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? encoder.encode(boxes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - CRUD

    func add(_ box: CleanupBox) {
        boxes.append(box)
        persist()
    }

    func update(_ box: CleanupBox) {
        guard let idx = boxes.firstIndex(where: { $0.id == box.id }) else { return }
        var updated = box
        updated.updatedAt = Date()
        boxes[idx] = updated
        persist()
    }

    func delete(_ box: CleanupBox) {
        boxes.removeAll { $0.id == box.id }
        persist()
    }

    /// 用备份内容整体替换箱台账（恢复链路用）
    func replaceAll(_ newBoxes: [CleanupBox]) {
        boxes = newBoxes
        persist()
    }

    func box(id: UUID) -> CleanupBox? {
        boxes.first { $0.id == id }
    }

    /// 批量创建：「第1箱」「第2箱」…，已有同前缀时从最大编号续排
    func batchCreate(count: Int, prefix: String = "第", category: String = "", priority: Int = 3) {
        let existingNumbers = boxes.compactMap { box -> Int? in
            guard box.label.hasPrefix(prefix) else { return nil }
            let rest = box.label.dropFirst(prefix.count).prefix(while: \.isNumber)
            guard !rest.isEmpty else { return nil }
            return Int(rest)
        }
        var next = (existingNumbers.max() ?? 0) + 1
        for _ in 0..<max(1, count) {
            boxes.append(CleanupBox(label: "\(prefix)\(next)箱",
                                    dominantCategory: category,
                                    priority: priority))
            next += 1
        }
        persist()
    }

    // MARK: - 状态流转

    func setStatus(_ status: BoxStatus, for id: UUID) {
        guard let idx = boxes.firstIndex(where: { $0.id == id }) else { return }
        boxes[idx].status = status
        let now = Date()
        switch status {
        case .inProgress:
            if boxes[idx].startedAt == nil { boxes[idx].startedAt = now }
        case .done:
            boxes[idx].completedAt = now
        default:
            break
        }
        boxes[idx].updatedAt = now
        persist()
    }

    func addTimeSpent(_ seconds: Int, to id: UUID) {
        guard let idx = boxes.firstIndex(where: { $0.id == id }), seconds > 0 else { return }
        boxes[idx].timeSpentSeconds += seconds
        boxes[idx].updatedAt = Date()
        persist()
    }

    enum PhotoSlot { case before, after }

    func setPhoto(_ photo: ItemPhoto?, slot: PhotoSlot, for id: UUID) {
        guard let idx = boxes.firstIndex(where: { $0.id == id }) else { return }
        switch slot {
        case .before: boxes[idx].beforePhoto = photo
        case .after:  boxes[idx].afterPhoto = photo
        }
        boxes[idx].updatedAt = Date()
        persist()
    }

    // MARK: - 派生数据

    var completedCount: Int { boxes.filter { $0.status == .done }.count }

    var totalTimeSpentSeconds: Int { boxes.reduce(0) { $0 + $1.timeSpentSeconds } }

    var totalTimeText: String {
        let total = totalTimeSpentSeconds
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)小时\(m)分" }
        if m > 0 { return "\(m)分" }
        return "\(total)秒"
    }

    func items(inBox boxId: UUID, from items: [AssetItem]) -> [AssetItem] {
        items.filter { $0.sourceBoxId == boxId }
    }

    /// 处置分布（基于全部物品的 disposition 字段）
    static func dispositionSummary(of items: [AssetItem]) -> [(ItemDisposition, Int)] {
        ItemDisposition.allCases.compactMap { disposition in
            let count = items.filter { $0.disposition == disposition }.count
            return count > 0 ? (disposition, count) : nil
        }
    }
}
