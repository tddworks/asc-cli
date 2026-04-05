// MARK: - Structured Affordance (single source of truth)

/// A structured affordance that can render to both CLI commands and REST links.
///
/// Models define affordances once using this type. The rendering to CLI
/// (`cliCommand`) or REST (`restLink`) is derived automatically.
public struct Affordance: Sendable, Equatable {
    public let key: String
    public let command: String
    public let action: String
    public let params: [String: String]

    public init(key: String, command: String, action: String, params: [String: String] = [:]) {
        self.key = key
        self.command = command
        self.action = action
        self.params = params
    }

    /// Renders as a CLI command: `asc {command} {action} --{k} {v} ...`
    public var cliCommand: String {
        var parts = ["asc", command, action]
        for (k, v) in params.sorted(by: { $0.key < $1.key }) {
            parts.append("--\(k)")
            parts.append(v)
        }
        return parts.joined(separator: " ")
    }

    /// Renders as a REST link with href and HTTP method.
    public var restLink: APILink {
        let method = Self.httpMethod(for: action)
        let path = RESTPathResolver.resolve(command: command, action: action, params: params)
        return APILink(href: path, method: method)
    }

    private static func httpMethod(for action: String) -> String {
        switch action {
        case "list", "get": return "GET"
        case "create": return "POST"
        case "update": return "PATCH"
        case "delete": return "DELETE"
        default: return "POST"
        }
    }
}

// MARK: - APILink

/// A HATEOAS link with an href and HTTP method.
public struct APILink: Sendable, Equatable, Codable {
    public let href: String
    public let method: String

    public init(href: String, method: String) {
        self.href = href
        self.method = method
    }
}

// MARK: - AffordanceMode

/// Controls whether affordances render as CLI commands or REST links.
public enum AffordanceMode: Sendable, Equatable {
    case cli
    case rest
}

// MARK: - REST Path Resolver

/// Resolves CLI command + params into a REST API path.
///
/// Uses a route table mapping CLI commands to their parent parameter
/// and REST segment. The parent parameter determines nesting:
/// `--app-id 123` + `versions` → `/api/v1/apps/123/versions`
public enum RESTPathResolver {

    /// (parentParam, parentSegment, resourceSegment)
    /// parentParam: the CLI flag that identifies the parent resource
    /// parentSegment: the REST path segment for the parent type
    /// resourceSegment: the REST path segment for this resource
    private static let routeTable: [String: (parentParam: String, parentSegment: String, segment: String)] = [
        // App children
        "versions": (parentParam: "app-id", parentSegment: "apps", segment: "versions"),
        "builds": (parentParam: "app-id", parentSegment: "apps", segment: "builds"),
        "reviews": (parentParam: "app-id", parentSegment: "apps", segment: "reviews"),
        "app-infos": (parentParam: "app-id", parentSegment: "apps", segment: "app-infos"),
        "testflight": (parentParam: "app-id", parentSegment: "apps", segment: "testflight"),
        "iap": (parentParam: "app-id", parentSegment: "apps", segment: "iap"),
        "subscription-groups": (parentParam: "app-id", parentSegment: "apps", segment: "subscription-groups"),
        "xcode-cloud": (parentParam: "app-id", parentSegment: "apps", segment: "xcode-cloud"),
        "perf-metrics": (parentParam: "app-id", parentSegment: "apps", segment: "perf-metrics"),
        "diagnostics": (parentParam: "app-id", parentSegment: "apps", segment: "diagnostics"),
        "app-clips": (parentParam: "app-id", parentSegment: "apps", segment: "app-clips"),

        // Version children
        "version-localizations": (parentParam: "version-id", parentSegment: "versions", segment: "localizations"),
        "version-review-detail": (parentParam: "version-id", parentSegment: "versions", segment: "review-detail"),

        // Localization children
        "screenshot-sets": (parentParam: "localization-id", parentSegment: "version-localizations", segment: "screenshot-sets"),
        "screenshots": (parentParam: "set-id", parentSegment: "screenshot-sets", segment: "screenshots"),
        "app-preview-sets": (parentParam: "localization-id", parentSegment: "version-localizations", segment: "preview-sets"),
        "app-previews": (parentParam: "set-id", parentSegment: "app-preview-sets", segment: "previews"),

        // App info children
        "app-info-localizations": (parentParam: "app-info-id", parentSegment: "app-infos", segment: "localizations"),
        "age-rating": (parentParam: "app-info-id", parentSegment: "app-infos", segment: "age-rating"),

        // IAP children
        "iap-localizations": (parentParam: "iap-id", parentSegment: "iap", segment: "localizations"),
        "iap-offer-codes": (parentParam: "iap-id", parentSegment: "iap", segment: "offer-codes"),
        "iap-availability": (parentParam: "iap-id", parentSegment: "iap", segment: "availability"),

        // Subscription group children
        "subscriptions": (parentParam: "group-id", parentSegment: "subscription-groups", segment: "subscriptions"),

        // Subscription children
        "subscription-localizations": (parentParam: "subscription-id", parentSegment: "subscriptions", segment: "localizations"),
        "subscription-offer-codes": (parentParam: "subscription-id", parentSegment: "subscriptions", segment: "offer-codes"),
        "subscription-offers": (parentParam: "subscription-id", parentSegment: "subscriptions", segment: "introductory-offers"),
        "subscription-availability": (parentParam: "subscription-id", parentSegment: "subscriptions", segment: "availability"),

        // TestFlight children
        "beta-review": (parentParam: "build-id", parentSegment: "builds", segment: "beta-review"),
        "beta-build-localizations": (parentParam: "build-id", parentSegment: "builds", segment: "beta-localizations"),

        // Xcode Cloud children
        "xcode-cloud-workflows": (parentParam: "product-id", parentSegment: "xcode-cloud", segment: "workflows"),
        "xcode-cloud-build-runs": (parentParam: "workflow-id", parentSegment: "xcode-cloud-workflows", segment: "build-runs"),

        // Code signing children
        "bundle-id-profiles": (parentParam: "bundle-id-id", parentSegment: "bundle-ids", segment: "profiles"),

        // App shots (screenshot generation)
        "app-shots-templates": (parentParam: "", parentSegment: "", segment: "app-shots/templates"),
        "app-shots-themes": (parentParam: "", parentSegment: "", segment: "app-shots/themes"),
    ]

    /// Maps CLI `--{param}-id` to the REST segment for the resource itself (used for get/update/delete).
    private static let resourceTable: [String: String] = [
        "version-id": "versions",
        "app-id": "apps",
        "build-id": "builds",
        "localization-id": "version-localizations",
        "set-id": "screenshot-sets",
        "review-id": "reviews",
        "iap-id": "iap",
        "group-id": "subscription-groups",
        "subscription-id": "subscriptions",
        "app-info-id": "app-infos",
        "certificate-id": "certificates",
        "device-id": "devices",
        "profile-id": "profiles",
        "bundle-id-id": "bundle-ids",
        "product-id": "xcode-cloud",
        "workflow-id": "xcode-cloud-workflows",
        "simulator-id": "simulators",
        "plugin-id": "plugins",
    ]

    static func resolve(command: String, action: String, params: [String: String]) -> String {
        let base = "/api/v1"

        // Actions on an existing resource by its own ID (get, update, delete, submit, etc.)
        if action != "list" && action != "create" {
            // Find the resource's own ID param (e.g. "version-id" for "versions")
            let idParam = "\(singularize(command))-id"
            if let idValue = params[idParam] {
                let segment = resourceTable[idParam] ?? command
                if action == "get" || action == "update" || action == "delete" {
                    return "\(base)/\(segment)/\(idValue)"
                }
                // Custom actions (submit, etc.) → POST /resource/id/action
                return "\(base)/\(segment)/\(idValue)/\(action)"
            }
        }

        // List/create under parent
        if let route = routeTable[command] {
            if let parentId = params[route.parentParam] {
                return "\(base)/\(route.parentSegment)/\(parentId)/\(route.segment)"
            }
        }

        // Top-level resource (e.g. apps list)
        return "\(base)/\(command)"
    }

    /// Naive singularization: "versions" → "version", "builds" → "build"
    private static func singularize(_ command: String) -> String {
        if command.hasSuffix("s") {
            return String(command.dropLast())
        }
        return command
    }
}