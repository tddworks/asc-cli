import Domain
import Foundation

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
