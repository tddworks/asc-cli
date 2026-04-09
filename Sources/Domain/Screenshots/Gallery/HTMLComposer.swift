import Foundation
import Mustache

/// Composes HTML from Mustache templates and content.
///
/// Uses `MustacheLibrary` to load and compile all `.mustache` templates once.
/// Templates support standard Mustache syntax:
/// - `{{varName}}` — HTML-escaped variable
/// - `{{{varName}}}` — raw/unescaped variable
/// - `{{#section}}...{{/section}}` — truthy section (if/each)
/// - `{{^section}}...{{/section}}` — inverted (else)
/// - `{{> partial}}` — partial inclusion
public enum HTMLComposer {

    /// Pre-compiled template library loaded from bundle resources.
    nonisolated(unsafe) private static var _library: MustacheLibrary?

    /// The template library. Lazily loads from bundle Resources on first access.
    public static var library: MustacheLibrary {
        if let lib = _library { return lib }
        let lib = loadLibrary()
        _library = lib
        return lib
    }

    /// Replace the library (e.g. for plugins providing custom templates).
    public static func setLibrary(_ lib: MustacheLibrary) {
        _library = lib
    }

    /// Render a named template with the given context.
    public static func render(template name: String, with context: Any) -> String {
        library.render(context, withTemplate: name) ?? ""
    }

    /// Render an inline template string with the given context.
    public static func render(_ template: String, with context: Any) -> String {
        guard let compiled = try? MustacheTemplate(string: template) else { return template }
        return compiled.render(context, library: library)
    }

    // MARK: - Library Loading

    private static func loadLibrary() -> MustacheLibrary {
        guard let resourceURL = Bundle.module.url(forResource: "Resources", withExtension: nil) else {
            return MustacheLibrary()
        }
        // Load .mustache files manually and compile
        var templates: [String: MustacheTemplate] = [:]
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: resourceURL.path) else {
            return MustacheLibrary()
        }
        for file in files where file.hasSuffix(".mustache") {
            let name = String(file.dropLast(".mustache".count))
            let path = resourceURL.appendingPathComponent(file).path
            guard let content = try? String(contentsOfFile: path, encoding: .utf8),
                  let compiled = try? MustacheTemplate(string: content) else { continue }
            templates[name] = compiled
        }
        return MustacheLibrary(templates: templates)
    }
}
