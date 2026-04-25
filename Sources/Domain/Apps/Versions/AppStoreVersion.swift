import Foundation

public struct AppStoreVersion: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — always present so agents can correlate responses.
    public let appId: String
    public let versionString: String
    public let platform: AppStorePlatform
    public let state: AppStoreVersionState
    public let createdDate: Date?
    /// Linked build ID, if a build has been associated with this version.
    public let buildId: String?
    /// Copyright string shown on the App Store page.
    public let copyright: String?
    /// Apple's release-type enum, kept as the raw string ("MANUAL",
    /// "AFTER_APPROVAL", "SCHEDULED") so the Domain doesn't have to
    /// mirror Apple's enum and stay in sync with their additions.
    public let releaseType: String?
    /// ISO-8601 timestamp for SCHEDULED releases. Stays as a string so
    /// JSON in/out is lossless and the Domain doesn't pull a Date
    /// formatter into its public API.
    public let earliestReleaseDate: String?

    public init(
        id: String,
        appId: String,
        versionString: String,
        platform: AppStorePlatform,
        state: AppStoreVersionState,
        createdDate: Date? = nil,
        buildId: String? = nil,
        copyright: String? = nil,
        releaseType: String? = nil,
        earliestReleaseDate: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.versionString = versionString
        self.platform = platform
        self.state = state
        self.createdDate = createdDate
        self.buildId = buildId
        self.copyright = copyright
        self.releaseType = releaseType
        self.earliestReleaseDate = earliestReleaseDate
    }

    public var isLive: Bool { state.isLive }
    public var isEditable: Bool { state.isEditable }
    public var isPending: Bool { state.isPending }

    public var displayName: String { "\(platform.displayName) \(versionString)" }
}

// MARK: - Codable (omit nil optional fields from JSON output)

extension AppStoreVersion: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, versionString, platform, state, createdDate, buildId
        case copyright, releaseType, earliestReleaseDate
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        versionString = try c.decode(String.self, forKey: .versionString)
        platform = try c.decode(AppStorePlatform.self, forKey: .platform)
        state = try c.decode(AppStoreVersionState.self, forKey: .state)
        createdDate = try c.decodeIfPresent(Date.self, forKey: .createdDate)
        buildId = try c.decodeIfPresent(String.self, forKey: .buildId)
        copyright = try c.decodeIfPresent(String.self, forKey: .copyright)
        releaseType = try c.decodeIfPresent(String.self, forKey: .releaseType)
        earliestReleaseDate = try c.decodeIfPresent(String.self, forKey: .earliestReleaseDate)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encode(versionString, forKey: .versionString)
        try c.encode(platform, forKey: .platform)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(createdDate, forKey: .createdDate)
        try c.encodeIfPresent(buildId, forKey: .buildId)
        try c.encodeIfPresent(copyright, forKey: .copyright)
        try c.encodeIfPresent(releaseType, forKey: .releaseType)
        try c.encodeIfPresent(earliestReleaseDate, forKey: .earliestReleaseDate)
    }
}

extension AppStoreVersion: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Platform", "Version", "State", "Live"]
    }
    public var tableRow: [String] {
        [id, platform.displayName, versionString, state.displayName, isLive ? "Yes" : "No"]
    }
}

extension AppStoreVersion: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "listLocalizations", command: "version-localizations", action: "list", params: ["version-id": id]),
            Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": appId]),
            Affordance(key: "checkReadiness", command: "versions", action: "check-readiness", params: ["version-id": id]),
            Affordance(key: "getReviewDetail", command: "version-review-detail", action: "get", params: ["version-id": id]),
        ]
        if isEditable {
            items.append(Affordance(key: "updateVersion", command: "versions", action: "update", params: ["version-id": id]))
            items.append(Affordance(key: "submitForReview", command: "versions", action: "submit", params: ["version-id": id]))
        }
        return items
    }
}

public enum AppStorePlatform: String, Sendable, Equatable, Codable, CaseIterable {
    case iOS = "IOS"
    case macOS = "MAC_OS"
    case tvOS = "TV_OS"
    case watchOS = "WATCH_OS"
    case visionOS = "VISION_OS"

    public var displayName: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .tvOS: return "tvOS"
        case .watchOS: return "watchOS"
        case .visionOS: return "visionOS"
        }
    }

    /// Accepts lowercase CLI argument strings (e.g. "ios", "macos").
    public init?(cliArgument: String) {
        switch cliArgument.lowercased() {
        case "ios": self = .iOS
        case "macos": self = .macOS
        case "tvos": self = .tvOS
        case "watchos": self = .watchOS
        case "visionos": self = .visionOS
        default: return nil
        }
    }
}
