import Foundation

/// Default template repository that loads HTML templates from the Domain module's bundle resources.
///
/// Templates are `.html` files in `Sources/Domain/Screenshots/Gallery/Resources/`.
/// Loaded templates are cached in memory after first read.
public final class BundledHTMLTemplateRepository: HTMLTemplateRepository, @unchecked Sendable {
    private var cache: [String: String] = [:]
    private let lock = NSLock()

    public init() {}

    public func template(named name: String) -> String? {
        lock.lock()
        if let cached = cache[name] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let url = Bundle.module.url(forResource: name, withExtension: "html", subdirectory: "Resources") else {
            return nil
        }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        lock.lock()
        cache[name] = content
        lock.unlock()
        return content
    }
}
