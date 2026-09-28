import Foundation

// MARK: - 数据结构

/// 一行解析后的表格数据。cells 为「表头文本 → 单元格文本」（均已 trim）。
struct SpreadsheetRow {
    var id: String
    var cells: [String: String]
}

/// Excel 导入执行计划：SpreadsheetMerge.plan 生成，ItemStore.applySpreadsheetImport 应用。
struct ImportPlan {
    struct Update {
        let existing: AssetItem
        let newValue: AssetItem
    }

    var updates: [Update] = []
    var inserts: [AssetItem] = []
    var skippedRows = 0
    var duplicateIDs = 0
    var unknownCategories: [String] = []
    var warnings: [String] = []

    var isEmpty: Bool { updates.isEmpty && inserts.isEmpty }

    var summary: String {
        var text = "更新 \(updates.count) · 新增 \(inserts.count)"
        if skippedRows > 0 { text += " · 跳过 \(skippedRows)" }
        return text
    }
}

// MARK: - 工作簿读写

/// .xlsx（Open XML）往返：导出可再次导入的台账工作簿，解析按表头文本匹配（与列顺序无关）。
/// 仅依赖 Foundation + /usr/bin/ditto（.xlsx 即 zip 包），可独立编译测试。
enum SpreadsheetService {

    /// 与 CSV 列一致，首位插入 ID 列用于往返更新；小计 / 录入时间仅展示，导入时忽略。
    static let headers = [
        "ID", "名称", "分类", "品牌/型号", "存放位置", "状态", "数量", "单价", "小计",
        "购入日期", "购买渠道", "质保到期", "到期日", "备注", "录入时间",
    ]

    private static let textFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: 导出

    static func exportWorkbook(items: [AssetItem]) throws -> Data {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("ThingsExport-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: dir) }

        try fm.createDirectory(at: dir.appendingPathComponent("_rels", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: dir.appendingPathComponent("xl/_rels", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: dir.appendingPathComponent("xl/worksheets", isDirectory: true), withIntermediateDirectories: true)

        try Self.contentTypesXML.write(to: dir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        try Self.rootRelsXML.write(to: dir.appendingPathComponent("_rels/.rels"), atomically: true, encoding: .utf8)
        try Self.workbookXML.write(to: dir.appendingPathComponent("xl/workbook.xml"), atomically: true, encoding: .utf8)
        try Self.workbookRelsXML.write(to: dir.appendingPathComponent("xl/_rels/workbook.xml.rels"), atomically: true, encoding: .utf8)
        try sheetXML(items).write(to: dir.appendingPathComponent("xl/worksheets/sheet1.xml"), atomically: true, encoding: .utf8)

        // 注意：zip 产物不能放在被压缩目录内
        let zipURL = fm.temporaryDirectory.appendingPathComponent("ThingsExport-\(UUID().uuidString).xlsx")
        defer { try? fm.removeItem(at: zipURL) }
        try runTool("/usr/bin/ditto", ["-c", "-k", dir.path, zipURL.path])
        return try Data(contentsOf: zipURL)
    }

    private static func sheetXML(_ items: [AssetItem]) -> String {
        var rows = [headerRowXML()]
        for (offset, item) in items.sorted(by: { $0.createdAt < $1.createdAt }).enumerated() {
            rows.append(dataRowXML(item, rowNumber: offset + 2))
        }
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>\(rows.joined())</sheetData></worksheet>
        """
    }

    private static func headerRowXML() -> String {
        let cells = headers.enumerated().map { offset, header in
            textCellXML(ref: columnLetter(offset) + "1", header)
        }
        return "<row r=\"1\">" + cells.joined() + "</row>"
    }

    private static func dataRowXML(_ item: AssetItem, rowNumber: Int) -> String {
        var cells: [String] = []
        func appendText(_ value: String) {
            let ref = columnLetter(cells.count) + String(rowNumber)
            cells.append(textCellXML(ref: ref, value))
        }
        func appendCount(_ value: Int) {
            let ref = columnLetter(cells.count) + String(rowNumber)
            cells.append(countCellXML(ref: ref, value: value))
        }
        func appendMoney(_ value: Double) {
            let ref = columnLetter(cells.count) + String(rowNumber)
            cells.append(moneyCellXML(ref: ref, value: value))
        }
        appendText(item.id.uuidString.uppercased())
        appendText(item.name)
        appendText(item.category)
        appendText(item.brand)
        appendText(item.location)
        appendText(item.status.rawValue)
        appendCount(item.quantity)
        appendMoney(item.purchasePrice)
        appendMoney(item.totalValue)
        appendText(item.purchaseDate.map(textFormatter.string(from:)) ?? "")
        appendText(item.purchaseChannel)
        appendText(item.warrantyUntil.map(textFormatter.string(from:)) ?? "")
        appendText(item.expiresAt.map(textFormatter.string(from:)) ?? "")
        appendText(item.notes)
        appendText(textFormatter.string(from: item.createdAt))
        return "<row r=\"\(rowNumber)\">" + cells.filter { !$0.isEmpty }.joined() + "</row>"
    }

    private static func textCellXML(ref: String, _ text: String) -> String {
        guard !text.isEmpty else { return "" }
        return "<c r=\"\(ref)\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\(escapeXML(text))</t></is></c>"
    }

    /// 数量等计数字段：整数文本
    private static func countCellXML(ref: String, value: Int) -> String {
        "<c r=\"\(ref)\"><v>\(value)</v></c>"
    }

    /// 金额字段：固定两位小数，Excel 中可直接求和
    private static func moneyCellXML(ref: String, value: Double) -> String {
        "<c r=\"\(ref)\"><v>\(String(format: "%.2f", value))</v></c>"
    }

    private static func columnLetter(_ index: Int) -> String {
        var n = index + 1
        var text = ""
        while n > 0 {
            let remainder = (n - 1) % 26
            text = String(UnicodeScalar(65 + remainder)!) + text
            n = (n - 1) / 26
        }
        return text
    }

    static func escapeXML(_ source: String) -> String {
        var out = ""
        out.reserveCapacity(source.count)
        for scalar in source.unicodeScalars {
            switch scalar {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            default:
                // 过滤 XML 非法控制字符（保留 \t \n \r）
                if scalar.value < 0x20, scalar != "\t", scalar != "\n", scalar != "\r" { continue }
                out.unicodeScalars.append(scalar)
            }
        }
        return out
    }

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>
    """

    private static let rootRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>
    """

    private static let workbookXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="物品台账" sheetId="1" r:id="rId1"/></sheets></workbook>
    """

    private static let workbookRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>
    """

    // MARK: 解析

    static func parseWorkbook(at xlsxURL: URL) throws -> [SpreadsheetRow] {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("ThingsImport-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: dir) }
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        try runTool("/usr/bin/ditto", ["-x", "-k", xlsxURL.path, dir.path])

        let shared = loadSharedStrings(dir: dir)
        let sheetURL = locateSheet(dir: dir)
        let rawRows = parseSheet(url: sheetURL, shared: shared)
        guard let headerRaw = rawRows.first else { return [] }

        var fieldByColumn: [Int: String] = [:]
        for (column, raw) in headerRaw {
            let header = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let canonical = canonicalHeader(header) else { continue }
            fieldByColumn[column] = canonical
        }

        return rawRows.dropFirst().map { cellsByColumn in
            var cells: [String: String] = [:]
            for (column, raw) in cellsByColumn {
                guard let field = fieldByColumn[column] else { continue }
                cells[field] = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return SpreadsheetRow(id: cells["ID"] ?? "", cells: cells)
        }
    }

    /// 表头精确匹配，大小写不敏感兜底；未知表头丢弃
    private static func canonicalHeader(_ header: String) -> String? {
        if headers.contains(header) { return header }
        let lowered = header.lowercased()
        return headers.first { $0.lowercased() == lowered }
    }

    /// workbook.xml → r:id → workbook.xml.rels → sheet 路径；失败兜底 sheet1.xml
    private static func locateSheet(dir: URL) -> URL {
        let fallback = dir.appendingPathComponent("xl/worksheets/sheet1.xml")
        guard let workbookData = try? Data(contentsOf: dir.appendingPathComponent("xl/workbook.xml")),
              let workbookText = String(data: workbookData, encoding: .utf8),
              let sheetID = firstMatch(#"r:id="([^"]+)""#, in: workbookText),
              let relsData = try? Data(contentsOf: dir.appendingPathComponent("xl/_rels/workbook.xml.rels")),
              let relsText = String(data: relsData, encoding: .utf8) else { return fallback }

        var target: String?
        for element in allMatches(of: #"<Relationship\b[^>]*>"#, in: relsText) {
            if firstMatch(#"Id="([^"]+)""#, in: element) == sheetID {
                target = firstMatch(#"Target="([^"]+)""#, in: element)
                break
            }
        }
        guard let target else { return fallback }
        // Target 可能是包内绝对路径（/xl/…）或相对 xl/ 的路径
        if target.hasPrefix("/") {
            return dir.appendingPathComponent(String(target.dropFirst()))
        }
        return dir.appendingPathComponent("xl/" + target)
    }

    private static func loadSharedStrings(dir: URL) -> [String] {
        guard let data = try? Data(contentsOf: dir.appendingPathComponent("xl/sharedStrings.xml")) else { return [] }
        let delegate = SharedStringsParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false
        parser.parse()
        return delegate.strings
    }

    private static func parseSheet(url: URL, shared: [String]) -> [[Int: String]] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let delegate = SheetParser(shared: shared)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false
        parser.parse()
        return delegate.rows
    }

    /// sharedStrings：每个 <si> 拼接全部文本节点（兼容富文本 run），跳过注音 <rPh>
    private final class SharedStringsParser: NSObject, XMLParserDelegate {
        fileprivate var strings: [String] = []
        private var buffer = ""
        private var inItem = false
        private var inPhonetic = false

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            if elementName == "si" { inItem = true; buffer = "" }
            if elementName == "rPh" { inPhonetic = true }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if inItem, !inPhonetic { buffer += string }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "si" { strings.append(buffer); inItem = false }
            if elementName == "rPh" { inPhonetic = false }
        }
    }

    /// 工作表：按 <c> 的 r 属性定位列（缺失时按位置推进），解析共享 / 内联 / 常规单元格
    private final class SheetParser: NSObject, XMLParserDelegate {
        private let shared: [String]
        fileprivate private(set) var rows: [[Int: String]] = []

        private var currentRow: [Int: String] = [:]
        private var runningColumn = 0
        private var cellColumn = 0
        private var cellType = ""
        private var valueBuffer = ""
        private var inlineBuffer = ""
        private var inValue = false
        private var inInline = false

        init(shared: [String]) { self.shared = shared }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            switch elementName {
            case "row":
                currentRow = [:]
                runningColumn = 0
            case "c":
                cellType = attributeDict["t"] ?? ""
                if let ref = attributeDict["r"] {
                    cellColumn = columnIndex(fromRef: ref)
                } else {
                    runningColumn += 1
                    cellColumn = runningColumn
                }
                valueBuffer = ""
                inlineBuffer = ""
            case "v":
                inValue = true
                valueBuffer = ""
            case "is":
                inInline = true
                inlineBuffer = ""
            default: break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if inValue { valueBuffer += string }
            if inInline { inlineBuffer += string }
        }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            guard let text = String(data: CDATABlock, encoding: .utf8) else { return }
            if inValue { valueBuffer += text }
            if inInline { inlineBuffer += text }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            switch elementName {
            case "v": inValue = false
            case "is": inInline = false
            case "c":
                currentRow[cellColumn] = resolveCellText()
                runningColumn = max(runningColumn, cellColumn)
            case "row":
                rows.append(currentRow)
            default: break
            }
        }

        private func resolveCellText() -> String {
            switch cellType {
            case "s":
                guard let index = Int(valueBuffer.trimmingCharacters(in: .whitespaces)),
                      shared.indices.contains(index) else { return "" }
                return shared[index]
            case "inlineStr":
                return inlineBuffer
            case "b":
                return valueBuffer.trimmingCharacters(in: .whitespaces) == "1" ? "TRUE" : "FALSE"
            default:
                return valueBuffer
            }
        }
    }

    /// "AB12" → 28
    private static func columnIndex(fromRef ref: String) -> Int {
        var n = 0
        for character in ref {
            guard let scalar = character.unicodeScalars.first,
                  (65...90).contains(scalar.value) || (97...122).contains(scalar.value) else { break }
            let value = scalar.value >= 97 ? scalar.value - 97 : scalar.value - 65
            n = n * 26 + Int(value) + 1
        }
        return n
    }

    // MARK: 工具

    @discardableResult
    private static func runTool(_ path: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        try process.run()
        process.waitUntilExit()
        let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "SpreadsheetService", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey:
                                stderr.isEmpty ? "\(path) 退出码 \(process.terminationStatus)" : stderr])
        }
        return stderr
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private static func allMatches(of pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
}

// MARK: - 合并语义

enum SpreadsheetMerge {

    /// 字段变更：absent = 整列缺失或留空（保留原值）；value = 新值；
    /// invalid = 值无法解析（保留原值并警告）。文本列的空单元格按「清空」处理。
    enum Change<Value> {
        case absent
        case value(Value)
        case invalid
    }

    private struct RowFields {
        var category = Change<String>.absent
        var brand = Change<String>.absent
        var location = Change<String>.absent
        var status = Change<ItemStatus>.absent
        var notes = Change<String>.absent
        var price = Change<Double>.absent
        var quantity = Change<Int>.absent
        var purchaseDate = Change<Date?>.absent
        var channel = Change<String>.absent
        var warrantyUntil = Change<Date?>.absent
        var expiresAt = Change<Date?>.absent
    }

    static func plan(rows: [SpreadsheetRow], existing: [AssetItem],
                     knownCategories: Set<String>, now: Date = Date()) -> ImportPlan {
        var plan = ImportPlan()
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        var seenIDs = Set<UUID>()
        var unknownCategories: [String] = []

        for row in rows {
            let cells = row.cells
            guard let name = cells["名称"], !name.isEmpty else {
                plan.skippedRows += 1
                continue
            }

            let fields = readFields(cells)
            let rowID = UUID(uuidString: row.id)

            if let rowID, let target = existingByID[rowID] {
                if seenIDs.contains(rowID) {
                    plan.duplicateIDs += 1
                    plan.updates.removeAll { $0.existing.id == rowID }
                    plan.inserts.removeAll { $0.id == rowID }
                }
                seenIDs.insert(rowID)
                var warnings: [String] = []
                let newValue = apply(fields, to: target, now: now, warnings: &warnings)
                plan.warnings.append(contentsOf: warnings)
                if newValue != target {
                    plan.updates.append(.init(existing: target, newValue: newValue))
                }
            } else {
                if let rowID {
                    if seenIDs.contains(rowID) {
                        plan.duplicateIDs += 1
                        plan.inserts.removeAll { $0.id == rowID }
                        plan.updates.removeAll { $0.existing.id == rowID }
                    }
                    seenIDs.insert(rowID)
                }
                plan.inserts.append(makeItem(fields, name: name, now: now))
            }

            if let category = cells["分类"], !category.isEmpty,
               !knownCategories.contains(category), !unknownCategories.contains(category) {
                unknownCategories.append(category)
            }
        }

        plan.unknownCategories = unknownCategories
        plan.warnings = Array(plan.warnings.prefix(5))
        return plan
    }

    // MARK: 单元格 → 字段

    private static func readFields(_ cells: [String: String]) -> RowFields {
        var fields = RowFields()
        fields.category = readText(cells, "分类")
        fields.brand = readText(cells, "品牌/型号")
        fields.location = readText(cells, "存放位置")
        fields.notes = readText(cells, "备注")
        fields.channel = readText(cells, "购买渠道")

        if let raw = cells["状态"] {
            if raw.isEmpty {
                fields.status = .absent
            } else if let status = ItemStatus(rawValue: raw) {
                fields.status = .value(status)
            } else {
                fields.status = .invalid
            }
        }

        if let raw = cells["单价"] {
            if raw.isEmpty {
                fields.price = .value(0)
            } else if let price = parsePrice(raw) {
                fields.price = .value(price)
            } else {
                fields.price = .invalid
            }
        }

        // 数量：留空保持原值（空数量无意义）
        if let raw = cells["数量"], !raw.isEmpty {
            if let quantity = parseQuantity(raw) {
                fields.quantity = .value(quantity)
            } else {
                fields.quantity = .invalid
            }
        }

        fields.purchaseDate = readDate(cells, "购入日期")
        fields.warrantyUntil = readDate(cells, "质保到期")
        fields.expiresAt = readDate(cells, "到期日")
        return fields
    }

    private static func readText(_ cells: [String: String], _ field: String) -> Change<String> {
        guard let raw = cells[field] else { return .absent }
        return raw.isEmpty ? .value("") : .value(raw)
    }

    private static func readDate(_ cells: [String: String], _ field: String) -> Change<Date?> {
        guard let raw = cells[field] else { return .absent }
        if raw.isEmpty { return .value(nil) }
        if let date = parseDate(raw) { return .value(date) }
        return .invalid
    }

    /// 依次尝试常见文本格式，最后兜底 Excel 序列数（1900 日期系统，基准 1899-12-30）
    static func parseDate(_ raw: String) -> Date? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        for format in ["yyyy-MM-dd", "yyyy/M/d", "yyyy.M.d", "M/d/yyyy",
                       "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return date }
        }
        guard let serial = Double(text), (20000.0...80000.0).contains(serial) else { return nil }
        let utcDate = Date(timeIntervalSince1970: -2_209_161_600 + serial * 86_400)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: utcDate)
        return Calendar.current.date(from: DateComponents(year: components.year,
                                                          month: components.month,
                                                          day: components.day))
    }

    private static func parsePrice(_ raw: String) -> Double? {
        let filtered = raw.filter { "0123456789.".contains($0) }
        guard let price = Double(filtered), price >= 0, price < 1e12 else { return nil }
        return price
    }

    private static func parseQuantity(_ raw: String) -> Int? {
        let text = raw.trimmingCharacters(in: .whitespaces)
        // 兼容 "3" 与 "3.00"：只取小数点前的整数部分
        let head = text.split(separator: ".").first.map(String.init) ?? text
        let digits = head.filter(\.isNumber)
        guard let quantity = Int(digits) else { return nil }
        return min(max(quantity, 1), 9999)
    }

    // MARK: 应用到档案

    private static func apply(_ fields: RowFields, to item: AssetItem,
                              now: Date, warnings: inout [String]) -> AssetItem {
        var value = item
        var changed = false

        func set(_ change: Change<String>, _ keyPath: WritableKeyPath<AssetItem, String>) {
            if case .value(let text) = change, value[keyPath: keyPath] != text {
                value[keyPath: keyPath] = text
                changed = true
            }
        }
        set(fields.category, \.category)
        set(fields.brand, \.brand)
        set(fields.location, \.location)
        set(fields.notes, \.notes)
        set(fields.channel, \.purchaseChannel)

        switch fields.status {
        case .value(let status) where value.status != status:
            value.status = status
            changed = true
        case .invalid:
            warnings.append("有一行状态无法识别，保留原状态")
        default: break
        }

        switch fields.price {
        case .value(let price) where value.purchasePrice != price:
            value.purchasePrice = price
            changed = true
        case .invalid:
            warnings.append("有一行单价无法识别，保留原单价")
        default: break
        }

        switch fields.quantity {
        case .value(let quantity) where value.quantity != quantity:
            value.quantity = quantity
            changed = true
        case .invalid:
            warnings.append("有一行数量无法识别，保留原数量")
        default: break
        }

        func set(_ change: Change<Date?>, _ keyPath: WritableKeyPath<AssetItem, Date?>, _ label: String) {
            switch change {
            case .value(let date) where value[keyPath: keyPath] != date:
                value[keyPath: keyPath] = date
                changed = true
            case .invalid:
                warnings.append("有一行\(label)无法识别，保留原值")
            default: break
            }
        }
        set(fields.purchaseDate, \.purchaseDate, "购入日期")
        set(fields.warrantyUntil, \.warrantyUntil, "质保到期")
        set(fields.expiresAt, \.expiresAt, "到期日")

        // 状态流转语义与 ItemStore.setStatus 一致
        if value.status != item.status {
            value.retiredAt = value.status == .retired ? now : nil
        }
        if changed { value.updatedAt = now }
        return value
    }

    private static func makeItem(_ fields: RowFields, name: String, now: Date) -> AssetItem {
        func text(_ change: Change<String>) -> String {
            if case .value(let value) = change { return value }
            return ""
        }
        func unwrapped<T>(_ change: Change<T>, _ fallback: T) -> T {
            if case .value(let value) = change { return value }
            return fallback
        }
        var item = AssetItem(
            name: name,
            category: text(fields.category),
            location: text(fields.location),
            brand: text(fields.brand),
            status: unwrapped(fields.status, .inUse),
            notes: text(fields.notes),
            purchasePrice: unwrapped(fields.price, 0),
            purchaseDate: unwrapped(fields.purchaseDate, nil),
            purchaseChannel: text(fields.channel),
            warrantyUntil: unwrapped(fields.warrantyUntil, nil),
            quantity: max(1, unwrapped(fields.quantity, 1)),
            expiresAt: unwrapped(fields.expiresAt, nil),
            createdAt: now,
            updatedAt: now)
        item.retiredAt = item.status == .retired ? now : nil
        return item
    }
}
