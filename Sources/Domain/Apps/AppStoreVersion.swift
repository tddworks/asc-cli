import Foundation

public struct AppStoreVersion: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — always present so agents can correlate responses.
    public let appId: String
    public let versionString: String
    public let platform: AppStorePlatform
    public let state: AppStoreVersionState
    public let createdDate: Date?

    public init(
        id: String,
        appId: String,
        versionString: String,
        platform: AppStorePlatform,
        state: AppStoreVersionState,
        createdDate: Date? = nil
    ) {
        self.id = id
        self.appId = appId
        self.versionString = versionString
        self.platform = platform
        self.state = state
        self.createdDate = createdDate
    }

    public var isLive: Bool { state.isLive }
    public var isEditable: Bool { state.isEditable }
    public var isPending: Bool { state.isPending }

    public var displayName: String { "\(platform.displayName) \(versionString)" }
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
}
