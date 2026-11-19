import Foundation

/// An app entry on the app wall (`homepage/apps.json`).
///
/// Supports three modes (combinable):
/// - `developerId` — auto-fetches all apps from the App Store for this developer
/// - `apps` — specific App Store URLs
/// - `developer` — optional display name for the card
public struct AppWallApp: Sendable, Equatable, Codable {
    public let developer: String?
    public let developerId: String?
    public let github: String?
    public let x: String?
    public let apps: [String]?

    public init(
        developer: String? = nil,
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

    /// True when the entry has at least one source of apps to display on the wall.
    /// An entry without `developerId` or `apps` would appear as an empty card.
    public var hasAppSource: Bool {
        developerId != nil || (apps?.isEmpty == false)
    }

    /// A short label for branch names and PR titles, derived from the best available field.
    public var branchLabel: String {
        if let developer, !developer.isEmpty { return developer }
        if let developerId, !developerId.isEmpty { return developerId }
        if let firstURL = apps?.first, let appId = Self.extractAppId(from: firstURL) { return appId }
        return "unknown"
    }

    // Custom Codable: omit nil/empty fields from JSON output
    enum CodingKeys: String, CodingKey {
        case developer, developerId, github, x, apps
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(developer, forKey: .developer)
        try container.encodeIfPresent(developerId, forKey: .developerId)
        try container.encodeIfPresent(github, forKey: .github)
        try container.encodeIfPresent(x, forKey: .x)
        try container.encodeIfPresent(apps, forKey: .apps)
    }

    /// Extracts the numeric app ID from an App Store URL (e.g. "/id6446381990" → "6446381990").
    private static func extractAppId(from url: String) -> String? {
        guard let range = url.range(of: #"id(\d+)"#, options: .regularExpression) else { return nil }
        return String(url[range].dropFirst(2))
    }
}
