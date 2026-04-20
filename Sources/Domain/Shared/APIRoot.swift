/// HATEOAS entry point for the REST API.
///
/// `GET /api/v1` returns this model. Its affordances list all top-level
/// resources the agent can navigate to — the starting point for discovery.
public struct APIRoot: Sendable, Equatable, Codable {
    public let version: String

    public init(version: String = "v1") {
        self.version = version
    }
}

extension APIRoot: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            // App management
            Affordance(key: "apps", command: "apps", action: "list", params: [:]),
            Affordance(key: "builds", command: "builds", action: "list", params: [:]),
            Affordance(key: "reviewSubmissions", command: "review-submissions", action: "list", params: [:]),

            // Code signing
            Affordance(key: "certificates", command: "certificates", action: "list", params: [:]),
            Affordance(key: "bundleIds", command: "bundle-ids", action: "list", params: [:]),
            Affordance(key: "devices", command: "devices", action: "list", params: [:]),
            Affordance(key: "profiles", command: "profiles", action: "list", params: [:]),

            // Local resources
            Affordance(key: "simulators", command: "simulators", action: "list", params: [:]),
            Affordance(key: "plugins", command: "plugins", action: "list", params: [:]),

            // Reference data
            Affordance(key: "territories", command: "territories", action: "list", params: [:]),
            Affordance(key: "appCategories", command: "app-categories", action: "list", params: [:]),

            // App shots (screenshot generation)
            Affordance(key: "appShotsTemplates", command: "app-shots-templates", action: "list", params: [:]),
            Affordance(key: "appShotsThemes", command: "app-shots-themes", action: "list", params: [:]),
        ]
    }
}