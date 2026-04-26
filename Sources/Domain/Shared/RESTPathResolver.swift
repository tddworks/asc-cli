import Foundation

/// Resolves a CLI command + params tuple into a REST API path.
///
/// **Single rule for resource actions (get/update/delete/submit/…):**
///  the command *is* the REST segment. Whatever `-id` flag appears in
///  `params` names the resource being acted on — the flag shape is a
///  CLI concern, not a REST one.
///
/// **Single rule for list/create under a parent:** domains register a
/// route up-front (`registerRoute`) declaring the parent param and the
/// child segment.
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
    private static let initLock = NSLock()
    nonisolated(unsafe) private static var routes: [String: Route] = [:]
    nonisolated(unsafe) private static var initialized = false

    // MARK: - Registration API (called by domain modules)

    /// Register a nested resource route.
    public static func registerRoute(command: String, parentParam: String, parentSegment: String, segment: String) {
        lock.lock()
        defer { lock.unlock() }
        routes[command] = Route(parentParam: parentParam, parentSegment: parentSegment, segment: segment)
    }

    /// Remove a route (for testing cleanup).
    public static func removeRoute(command: String) {
        lock.lock()
        defer { lock.unlock() }
        routes.removeValue(forKey: command)
    }

    // MARK: - Resolution

    public static func resolve(command: String, action: String, params: [String: String]) -> String {
        ensureInitialized()

        lock.lock()
        let currentRoutes = routes
        lock.unlock()

        let base = "/api/v1"

        // Singleton resources under a parent — when a `get` action's only id-shaped param
        // matches the registered parent param, the resource is a singleton living under the
        // parent (e.g. `iap-review-screenshot` under `iap-id`), not a resource keyed by its
        // own id. Map to `/parent/{id}/segment` so agents can walk the hierarchy.
        if action == "get", let route = currentRoutes[command],
           let parentId = params[route.parentParam],
           !params.keys.contains(where: { $0.hasSuffix("-id") && $0 != route.parentParam }) {
            return "\(base)/\(route.parentSegment)/\(parentId)/\(route.segment)"
        }

        // Actions on a resource by its own id (get, update, delete, submit, …).
        if action != "list", action != "create",
           let idValue = resourceId(in: params, command: command) {
            return resourcePath(base: base, segment: command, id: idValue, action: action)
        }

        // List/create under a parent resource.
        if let route = currentRoutes[command],
           let parentId = params[route.parentParam] {
            return "\(base)/\(route.parentSegment)/\(parentId)/\(route.segment)"
        }

        // Top-level (list/create on the resource itself).
        return "\(base)/\(command)"
    }

    // MARK: - Helpers

    /// Pick the id value for a resource action. Prefers the singularized-from-command
    /// name (`version-id` for `versions`, `certificate-id` for `certificates`), otherwise
    /// accepts any `*-id` key — CLI flags can be short aliases shared across commands
    /// (`--localization-id`, `--product-id`) and the *command* is the authoritative segment.
    private static func resourceId(in params: [String: String], command: String) -> String? {
        if let value = params["\(singularize(command))-id"] { return value }
        guard let key = params.keys.filter({ $0.hasSuffix("-id") }).sorted().first else { return nil }
        return params[key]
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

    // MARK: - Lazy initialization

    /// Triggers all domain route registrations on first use.
    /// Each domain adds a static `_*Routes: Void` property via extension.
    ///
    /// Must hold the lock for the whole registration sequence so concurrent callers
    /// don't observe `initialized == true` while the `routes` dictionary is still empty.
    private static func ensureInitialized() {
        // Separate from `lock` so the domain `registerRoute` calls triggered below
        // can acquire `lock` without re-entering this critical section.
        initLock.lock()
        defer { initLock.unlock() }
        guard !initialized else { return }

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

        initialized = true
    }
}
