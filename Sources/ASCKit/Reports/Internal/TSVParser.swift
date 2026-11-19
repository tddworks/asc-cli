public enum TSVParser {
    public static func parse(_ tsv: String) -> [[String: String]] {
        let lines = tsv.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return [] }

        let headers = lines[0].components(separatedBy: "\t")
        return lines.dropFirst().map { line in
            let values = line.components(separatedBy: "\t")
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() where index < values.count {
                row[header] = values[index]
            }
            return row
        }
    }
}
