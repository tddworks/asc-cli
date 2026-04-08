import Foundation

/// Composes HTML from templates and content.
///
/// Supports variable substitution, conditional blocks, and loops:
/// - `{{varName}}` — variable substitution
/// - `{{{varName}}}` — raw output (same as `{{}}`, no escaping)
/// - `{{#if varName}}...{{/if}}` — conditional block
/// - `{{#each varName}}...{{/each}}` — loop with `{{property}}` and `{{index}}`
/// - `{{slot.property}}` — dot-notation for nested values
public enum HTMLComposer {

    /// Render a template string with the given context.
    public static func render(_ template: String, with context: [String: Any]) -> String {
        var result = template

        // 1. Process {{#each key}}...{{/each}} blocks
        result = processEachBlocks(result, context: context)

        // 2. Process {{#if key}}...{{/if}} blocks
        result = processIfBlocks(result, context: context)

        // 3. Replace {{{var}}} (raw/triple-brace)
        result = replaceTripleBraces(result, context: context)

        // 4. Replace {{var}} (double-brace)
        result = replaceDoubleBraces(result, context: context)

        return result
    }

    // MARK: - Each Blocks

    private static func processEachBlocks(_ template: String, context: [String: Any]) -> String {
        var result = template
        while let range = findBlock(in: result, tag: "each") {
            let key = range.key
            let body = range.body
            let items = resolve(key, in: context) as? [[String: Any]] ?? []
            var rendered = ""
            for (index, item) in items.enumerated() {
                var itemContext = item
                itemContext["index"] = "\(index)"
                rendered += render(body, with: itemContext)
            }
            result = result.replacingCharacters(in: range.fullRange, with: rendered)
        }
        return result
    }

    // MARK: - If Blocks

    private static func processIfBlocks(_ template: String, context: [String: Any]) -> String {
        var result = template
        while let range = findBlock(in: result, tag: "if") {
            let key = range.key
            let body = range.body
            let value = resolve(key, in: context)
            let truthy = isTruthy(value)
            let rendered = truthy ? render(body, with: context) : ""
            result = result.replacingCharacters(in: range.fullRange, with: rendered)
        }
        return result
    }

    // MARK: - Variable Substitution

    private static func replaceTripleBraces(_ template: String, context: [String: Any]) -> String {
        var result = template
        let pattern = "\\{\\{\\{([^}]+)\\}\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        for match in matches.reversed() {
            guard let keyRange = Range(match.range(at: 1), in: result),
                  let fullRange = Range(match.range, in: result) else { continue }
            let key = String(result[keyRange]).trimmingCharacters(in: .whitespaces)
            let value = resolve(key, in: context).flatMap { "\($0)" } ?? ""
            result = result.replacingCharacters(in: fullRange, with: value)
        }
        return result
    }

    private static func replaceDoubleBraces(_ template: String, context: [String: Any]) -> String {
        var result = template
        let pattern = "\\{\\{([^#/}][^}]*)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        for match in matches.reversed() {
            guard let keyRange = Range(match.range(at: 1), in: result),
                  let fullRange = Range(match.range, in: result) else { continue }
            let key = String(result[keyRange]).trimmingCharacters(in: .whitespaces)
            let value = resolve(key, in: context).flatMap { "\($0)" } ?? ""
            result = result.replacingCharacters(in: fullRange, with: value)
        }
        return result
    }

    // MARK: - Helpers

    private static func resolve(_ keyPath: String, in context: [String: Any]) -> Any? {
        let parts = keyPath.split(separator: ".")
        var current: Any? = context
        for part in parts {
            guard let dict = current as? [String: Any] else { return nil }
            current = dict[String(part)]
        }
        return current
    }

    private static func isTruthy(_ value: Any?) -> Bool {
        guard let value else { return false }
        if let str = value as? String { return !str.isEmpty }
        if let arr = value as? [Any] { return !arr.isEmpty }
        return true
    }

    private struct BlockMatch {
        let key: String
        let body: String
        let fullRange: Range<String.Index>
    }

    private static func findBlock(in template: String, tag: String) -> BlockMatch? {
        let openPrefix = "{{#\(tag) "
        guard let openStart = template.range(of: openPrefix) else { return nil }
        guard let openEnd = template[openStart.upperBound...].range(of: "}}") else { return nil }
        let key = String(template[openStart.upperBound..<openEnd.lowerBound]).trimmingCharacters(in: .whitespaces)
        let closeTag = "{{/\(tag)}}"
        // Find the matching close tag, accounting for nesting
        var searchFrom = openEnd.upperBound
        var depth = 1
        while depth > 0 {
            // Find next open or close tag, whichever comes first
            let nextOpen = template[searchFrom...].range(of: openPrefix)
            let nextClose = template[searchFrom...].range(of: closeTag)
            guard let close = nextClose else { return nil }
            if let open = nextOpen, open.lowerBound < close.lowerBound {
                depth += 1
                searchFrom = open.upperBound
            } else {
                depth -= 1
                if depth == 0 {
                    let body = String(template[openEnd.upperBound..<close.lowerBound])
                    let fullRange = openStart.lowerBound..<close.upperBound
                    return BlockMatch(key: key, body: body, fullRange: fullRange)
                }
                searchFrom = close.upperBound
            }
        }
        return nil
    }
}
