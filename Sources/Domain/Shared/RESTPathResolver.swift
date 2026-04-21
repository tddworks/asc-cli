import Foundation

/// Resolves CLI command + params into a REST API path.
///
/// **Open-Closed**: the resolver never needs editing to add routes.
/// Each domain registers its own routes via `RESTPathResolver.registerRoute()`
/// — typically in the same file as its `AffordanceProviding` conformance.
///
/// Example (in `App.swift`):
/// ```swift
/// extension RESTPathResolver {
///     static let _appRoutes: Void = {
///         registerRoute(command: "versions", parentParam: "app-id", parentSegment: "apps", segment: "versions")
///     }()
/// }
/// ```
public final class RESTPathResolver: @unchecked Sendable {

    public struct Route: Sendable {
        public let parentParam: String
        public let parentSegment: String
        public let segment: String

        public init(parentParam: String, parentSegment: String, segment: String) {
            self.parentParam = parentParam
            self.parentSegment = parentSegment
            self.segment = segment
        }
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var routes: [String: Route] = [:]
    nonisolated(unsafe) private static var resources: [String: String] = [:]
    nonisolated(unsafe) private static var initialized = false

    // MARK: - Registration API (called by domain modules)

    /// Register a nested resource route.
    public static func registerRoute(command: String, parentParam: String, parentSegment: String, segment: String) {
        lock.lock()
        defer { lock.unlock() }
        routes[command] = Route(parentParam: parentParam, parentSegment: parentSegment, segment: segment)
    }

    /// Register a resource ID mapping (for get/update/delete actions).
    public static func registerResource(param: String, segment: String) {
        lock.lock()
        defer { lock.unlock() }
        resources[param] = segment
    }

    /// Remove a route (for testing cleanup).
    public static func removeRoute(command: String) {
        lock.lock()
        defer { lock.unlock() }
        routes.removeValue(forKey: command)
    }

    /// Remove a resource mapping (for testing cleanup).
    public static func removeResource(param: String) {
        lock.lock()
        defer { lock.unlock() }
        resources.removeValue(forKey: param)
    }

    // MARK: - Resolution

    public static func resolve(command: String, action: String, params: [String: String]) -> String {
        ensureInitialized()

        lock.lock()
        let currentRoutes = routes
        let currentResources = resources
        lock.unlock()

        let base = "/api/v1"

        // Actions on an existing resource by its own ID (get, update, delete, submit, etc.)
        if action != "list" && action != "create" {
            // Preferred: the flag matches the singularized command (e.g. `--version-id` for
            // `versions`) and may be aliased via a global mapping (e.g. `product-id → xcode-cloud`).
            let derivedIdParam = "\(singularize(command))-id"
            if let idValue = params[derivedIdParam] {
                let segment = currentResources[derivedIdParam] ?? command
                return resourcePath(base: base, segment: segment, id: idValue, action: action)
            }
            // Fallback: the CLI may use a shorter alias shared between resources
            // (e.g. `--localization-id` in both version-localizations and app-info-localizations).
            // The command name alone determines the segment — global alias tables are ambiguous here.
            if let key = params.keys.filter({ $0.hasSuffix("-id") }).sorted().first,
               let idValue = params[key] {
                return resourcePath(base: base, segment: command, id: idValue, action: action)
            }
        }

        // List/create under parent
        if let route = currentRoutes[command] {
            if let parentId = params[route.parentParam] {
                return "\(base)/\(route.parentSegment)/\(parentId)/\(route.segment)"
            }
        }

        // Top-level resource (e.g. apps list)
        return "\(base)/\(command)"
    }

    // MARK: - Lazy initialization

    /// Triggers all domain route registrations on first use.
    /// Each domain adds a static `_*Routes: Void` property via extension.
    private static func ensureInitialized() {
        lock.lock()
        guard !initialized else { lock.unlock(); return }
        initialized = true
        lock.unlock()

        // Touch each domain's lazy registration property.
        // OCP: add one line here when adding a new domain.
        _ = _appRoutes
        _ = _versionRoutes
        _ = _appInfoRoutes
        _ = _iapRoutes
        _ = _subscriptionRoutes
        _ = _testFlightRoutes
        _ = _xcodeCloudRoutes
        _ = _codeSigningRoutes
        _ = _appShotsRoutes
        _ = _resourceMappings
    }

    private static func resourcePath(base: String, segment: String, id: String, action: String) -> String {
        if action == "get" || action == "update" || action == "delete" {
            return "\(base)/\(segment)/\(id)"
        }
        return "\(base)/\(segment)/\(id)/\(action)"
    }

    private static func singularize(_ command: String) -> String {
        if command.hasSuffix("s") {
            return String(command.dropLast())
        }
        return command
    }
}
