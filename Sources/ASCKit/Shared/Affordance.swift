import Foundation

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
    /// Boolean CLI flags (`--to-library`); REST links don't carry them.
    public let flags: [String]

    /// Kept as its own initializer: installed plugins link against this exact signature.
    public init(key: String, command: String, action: String, params: [String: String] = [:]) {
        self.init(key: key, command: command, action: action, params: params, flags: [])
    }

    public init(key: String, command: String, action: String, params: [String: String] = [:], flags: [String]) {
        self.key = key
        self.command = command
        self.action = action
        self.params = params
        self.flags = flags
    }

    /// Renders as a CLI command: `asc {command} {action} --{k} {v} ...`, flags and params in name order.
    public var cliCommand: String {
        var parts = ["asc", command, action]
        let options: [(String, String?)] = params.map { ($0.key, $0.value) } + flags.map { ($0, nil) }
        for (k, v) in options.sorted(by: { $0.0 < $1.0 }) {
            parts.append("--\(k)")
            if let v { parts.append(v) }
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
        case "delete", "remove": return "DELETE"
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

