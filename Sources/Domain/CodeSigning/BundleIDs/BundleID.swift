public struct BundleID: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    /// The bundle identifier string, e.g. `com.example.app`.
    public let identifier: String
    public let platform: BundleIDPlatform
    public let seedID: String?

    public init(
        id: String,
        name: String,
        identifier: String,
        platform: BundleIDPlatform,
        seedID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.identifier = identifier
        self.platform = platform
        self.seedID = seedID
    }
}

extension BundleID: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Identifier", "Platform"]
    }
    public var tableRow: [String] {
        [id, name, identifier, platform.displayName]
    }
}

extension BundleID: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc bundle-ids delete --bundle-id-id \(id)",
            "listProfiles": "asc profiles list --bundle-id-id \(id)",
        ]
    }
}

/// Platform for a bundle ID or code-signing resource.
public enum BundleIDPlatform: String, Sendable, Equatable, Codable, CaseIterable {
    case iOS = "IOS"
    case macOS = "MAC_OS"
    case universal = "UNIVERSAL"
    case services = "SERVICES"

    public var displayName: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .universal: return "Universal"
        case .services: return "Services"
        }
    }

    /// Accepts lowercase CLI argument strings (e.g. "ios", "macos").
    public init?(cliArgument: String) {
        switch cliArgument.lowercased() {
        case "ios": self = .iOS
        case "macos": self = .macOS
        case "universal": self = .universal
        case "services": self = .services
        default: return nil
        }
    }
}
