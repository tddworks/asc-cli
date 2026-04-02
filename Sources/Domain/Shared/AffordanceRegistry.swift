import Foundation

/// Registry for plugin-contributed affordances.
///
/// Plugins extend domain models' affordances at runtime without modifying them.
///
/// ```swift
/// // Plugin registers at startup:
/// AffordanceRegistry.register(Simulator.self) { id, props in
///     if props["isBooted"] == "true" {
///         return ["stream": "asc simulators stream --udid \(id)"]
///     }
///     return [:]
/// }
///
/// // Domain model merges at output time:
/// AffordanceRegistry.affordances(for: Self.self, id: id, properties: [...])
/// ```
public enum AffordanceRegistry {
    public typealias Provider = @Sendable (String, [String: String]) -> [String: String]

    private static let lock = NSLock()
    private static nonisolated(unsafe) var providers: [String: [Provider]] = [:]

    /// Register affordances for a domain model type.
    public static func register<T: AffordanceProviding>(_ type: T.Type, _ provider: @escaping Provider) {
        let key = String(describing: type)
        lock.lock()
        providers[key, default: []].append(provider)
        lock.unlock()
    }

    /// Get plugin affordances for a model instance.
    public static func affordances<T: AffordanceProviding>(for type: T.Type, id: String, properties: [String: String] = [:]) -> [String: String] {
        let key = String(describing: type)
        lock.lock()
        let fns = providers[key] ?? []
        lock.unlock()
        var result: [String: String] = [:]
        for fn in fns { result.merge(fn(id, properties)) { _, new in new } }
        return result
    }
}
