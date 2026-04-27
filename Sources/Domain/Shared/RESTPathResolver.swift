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

        if action != "list", action != "create" {
            // Action on this resource by its own id (e.g. `versions get --version-id v-1`).
            if let ownId = params["\(singularize(command))-id"] {
                return resourcePath(base: base, segment: command, id: ownId, action: action)
            }
            // Singleton-under-parent (e.g. `iap-availability get --iap-id X` →
            // `/api/v1/iap/X/availability`). Triggered when a route is registered for
            // this command and its parent param is in `params`.
            if let route = currentRoutes[command], let parentId = params[route.parentParam] {
                let nested = "\(base)/\(route.parentSegment)/\(parentId)/\(route.segment)"
                switch action {
                case "get", "update", "delete": return nested
                default: return "\(nested)/\(action)"
                }
            }
            // Fallback: any *-id key (CLI flag names that don't match the singularized command).
            if let idValue = resourceId(in: params, command: command) {
                return resourcePath(base: base, segment: command, id: idValue, action: action)
            }
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
        _ = _iapReviewAssetRoutes
        _ = _subscriptionRoutes
        _ = _subscriptionReviewAssetRoutes
        _ = _subscriptionPromotionalOfferRoutes
        _ = _winBackOfferRoutes
        _ = _subscriptionPricePointRoutes
        _ = _testFlightRoutes
        _ = _xcodeCloudRoutes
        _ = _codeSigningRoutes
        _ = _appShotsRoutes

        initialized = true
    }
}
