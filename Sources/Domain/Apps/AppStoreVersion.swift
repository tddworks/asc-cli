public struct AppStoreVersion: Sendable, Equatable, Identifiable {
    public let id: String
    public let versionString: String
    public let platform: AppStorePlatform

    public init(id: String, versionString: String, platform: AppStorePlatform) {
        self.id = id
        self.versionString = versionString
        self.platform = platform
    }

    /// Human-readable label, e.g. "iOS 2.1.0" or "macOS 1.5.0".
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
