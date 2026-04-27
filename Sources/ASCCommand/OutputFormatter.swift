import Domain
import Foundation

// MARK: - Agent-first encoding helpers

/// Wraps a list in {"data": [...]} for agent-first JSON responses.
struct DataResponse<T: Encodable>: Encodable {
    let data: [T]
}

/// Wraps a paginated list with cursor metadata. `nextCursor`/`totalCount` are omitted when nil.
struct PaginatedDataResponse<T: Encodable>: Encodable {
    let data: [T]
    let nextCursor: String?
    let totalCount: Int?

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(data, forKey: .data)
        try c.encodeIfPresent(nextCursor, forKey: .nextCursor)
        try c.encodeIfPresent(totalCount, forKey: .totalCount)
    }

    private enum CodingKeys: String, CodingKey {
        case data, nextCursor, totalCount
    }
}

/// Wraps a single item in {"data": {...}} for agent-first JSON responses.
struct SingleDataResponse<T: Encodable>: Encodable {
    let data: T
}

/// Merges affordances (CLI mode) or _links (REST mode) into the JSON encoding
/// of any AffordanceProviding + Encodable item.
struct WithAffordances<T: Encodable & AffordanceProviding>: Encodable {
    private let item: T
    private let mode: AffordanceMode

    init(_ item: T, mode: AffordanceMode = .cli) {
        self.item = item
        self.mode = mode
    }

    func encode(to encoder: any Encoder) throws {
        try item.encode(to: encoder)
        switch mode {
        case .cli:
            var container = encoder.container(keyedBy: CLIAffordanceCodingKey.self)
            try container.encode(item.affordances, forKey: .affordances)
        case .rest:
            var container = encoder.container(keyedBy: RESTLinksCodingKey.self)
            try container.encode(item.apiLinks, forKey: ._links)
        }
    }

    private enum CLIAffordanceCodingKey: String, CodingKey {
        case affordances
    }

    private enum RESTLinksCodingKey: String, CodingKey {
        case _links
    }
}

// MARK: - OutputFormatter

struct OutputFormatter {
    let format: OutputFormat
    let pretty: Bool

    init(format: OutputFormat = .json, pretty: Bool = false) {
        self.format = format
        self.pretty = pretty
    }

    func format<T: Encodable>(_ value: T) throws -> String {
        switch format {
        case .json:
            return try formatJSON(value)
        case .table:
            return formatTable(value)
        case .markdown:
            return formatMarkdown(value)
        }
    }

    func formatItems<T: Encodable>(_ items: [T], headers: [String], rowMapper: (T) -> [String]) throws -> String {
        switch format {
        case .json:
            return try formatJSON(items)
        case .table:
            return renderTable(headers: headers, rows: items.map(rowMapper))
        case .markdown:
            return renderMarkdownTable(headers: headers, rows: items.map(rowMapper))
        }
    }

    /// Agent-first format using `Presentable` — no headers/rowMapper needed.
    func formatAgentItems<T: Encodable & AffordanceProviding & Presentable>(
        _ items: [T],
        affordanceMode: AffordanceMode = .cli
    ) throws -> String {
        switch format {
        case .json:
            return try formatJSON(DataResponse(data: items.map { WithAffordances($0, mode: affordanceMode) }))
        case .table:
            return renderTable(headers: T.tableHeaders, rows: items.map(\.tableRow))
        case .markdown:
            return renderMarkdownTable(headers: T.tableHeaders, rows: items.map(\.tableRow))
        }
    }

    /// Agent-first format: {"data": [...]} with affordances merged into each item.
    func formatAgentItems<T: Encodable & AffordanceProviding>(
        _ items: [T],
        headers: [String],
        rowMapper: (T) -> [String],
        affordanceMode: AffordanceMode = .cli
    ) throws -> String {
        switch format {
        case .json:
            return try formatJSON(DataResponse(data: items.map { WithAffordances($0, mode: affordanceMode) }))
        case .table:
            return renderTable(headers: headers, rows: items.map(rowMapper))
        case .markdown:
            return renderMarkdownTable(headers: headers, rows: items.map(rowMapper))
        }
    }

    /// Agent-first format with cursor pagination: `{"data": [...], "nextCursor": "...", "totalCount": N}`.
    /// `nextCursor` and `totalCount` are omitted when nil. Tabular/markdown output drops the
    /// pagination meta — paginated output only makes sense in JSON.
    func formatAgentPaginated<T: Encodable & AffordanceProviding & Presentable>(
        _ response: PaginatedResponse<T>,
        affordanceMode: AffordanceMode = .cli
    ) throws -> String {
        switch format {
        case .json:
            return try formatJSON(PaginatedDataResponse(
                data: response.data.map { WithAffordances($0, mode: affordanceMode) },
                nextCursor: response.nextCursor,
                totalCount: response.totalCount
            ))
        case .table:
            return renderTable(headers: T.tableHeaders, rows: response.data.map(\.tableRow))
        case .markdown:
            return renderMarkdownTable(headers: T.tableHeaders, rows: response.data.map(\.tableRow))
        }
    }

    // Plugin affordances are now merged by the AffordanceProviding protocol itself (OCP).
    // No need for a separate Identifiable overload — WithAffordances handles everything.

    private func formatJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.sortedKeys]
        }
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func formatTable<T>(_ value: T) -> String {
        "\(value)"
    }

    private func formatMarkdown<T>(_ value: T) -> String {
        "\(value)"
    }

    private func renderTable(headers: [String], rows: [[String]]) -> String {
        guard !headers.isEmpty else { return "" }

        var widths = headers.map(\.count)
        for row in rows {
            for (i, cell) in row.enumerated() where i < widths.count {
                widths[i] = max(widths[i], cell.count)
            }
        }

        var lines: [String] = []

        let headerLine = headers.enumerated().map { i, h in
            h.padding(toLength: widths[i], withPad: " ", startingAt: 0)
        }.joined(separator: "  ")
        lines.append(headerLine)

        let separator = widths.map { String(repeating: "-", count: $0) }.joined(separator: "  ")
        lines.append(separator)

        for row in rows {
            let line = row.enumerated().map { i, cell in
                let width = i < widths.count ? widths[i] : cell.count
                return cell.padding(toLength: width, withPad: " ", startingAt: 0)
            }.joined(separator: "  ")
            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    private func renderMarkdownTable(headers: [String], rows: [[String]]) -> String {
        guard !headers.isEmpty else { return "" }

        var lines: [String] = []
        lines.append("| " + headers.joined(separator: " | ") + " |")
        lines.append("| " + headers.map { _ in "---" }.joined(separator: " | ") + " |")

        for row in rows {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }

        return lines.joined(separator: "\n")
    }
}