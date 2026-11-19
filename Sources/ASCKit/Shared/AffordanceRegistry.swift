import Foundation

/// Registry for plugin-contributed affordances.
///
/// Plugins extend domain models' affordances at runtime without modifying them.
///
/// ```swift
/// // Plugin registers at startup:
/// AffordanceRegistry.register(Simulator.self) { id, props in
///     guard props["isBooted"] == "true" else { return [] }
///     return [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
/// }
///
/// // Merged at output time — renders to both CLI and REST:
/// AffordanceRegistry.affordances(for: Self.self, id: id, properties: [...])
/// ```
public enum AffordanceRegistry {
    public typealias Provider = @Sendable (String, [String: String]) -> [Affordance]

    private static let lock = NSLock()
    private static nonisolated(unsafe) var providers: [String: [Provider]] = [:]

    /// Register structured affordances for a domain model type.
    /// Returns `[Affordance]` — renders to both CLI commands and REST `_links`.
    public static func register<T: AffordanceProviding>(_ type: T.Type, _ provider: @escaping Provider) {
        let key = String(describing: type)
        lock.lock()
        providers[key, default: []].append(provider)
        lock.unlock()
    }

    /// Remove all registered providers (used by tests to avoid cross-test pollution).
    public static func reset() {
        lock.lock()
        providers.removeAll()
        lock.unlock()
    }

    /// Get plugin affordances for a model instance.
    public static func affordances<T: AffordanceProviding>(for type: T.Type, id: String, properties: [String: String] = [:]) -> [Affordance] {
        let key = String(describing: type)
        lock.lock()
        let fns = providers[key] ?? []
        lock.unlock()
        var result: [Affordance] = []
        for fn in fns { result.append(contentsOf: fn(id, properties)) }
        return result
    }
}
