import Foundation

/// An app entry on the app wall (`homepage/apps.json`).
///
/// Supports two modes (combinable):
/// - `developerId` — auto-fetches all apps from the App Store for this developer
/// - `apps` — specific App Store URLs
public struct AppWallApp: Sendable, Equatable, Codable, Identifiable {
    public var id: String { developer }
    public let developer: String
    public let developerId: String?
    public let github: String?
    public let x: String?
    public let apps: [String]?

    public init(
        developer: String,
        developerId: String? = nil,
        github: String? = nil,
        x: String? = nil,
        apps: [String]? = nil
    ) {
        self.developer = developer
        self.developerId = developerId
        self.github = github
        self.x = x
        self.apps = apps
    }

    // Custom Codable: omit nil/empty fields from JSON output
    enum CodingKeys: String, CodingKey {
        case developer, developerId, github, x, apps
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(developer, forKey: .developer)
        try container.encodeIfPresent(developerId, forKey: .developerId)
        try container.encodeIfPresent(github, forKey: .github)
        try container.encodeIfPresent(x, forKey: .x)
        try container.encodeIfPresent(apps, forKey: .apps)
    }
}
