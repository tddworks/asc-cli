import Foundation

public struct ScreenshotManifest: Codable, Sendable {
    public let version: String
    public let exportedAt: String?
    public let localizations: [String: LocalizationManifest]

    public struct LocalizationManifest: Codable, Sendable {
        public let displayType: ScreenshotDisplayType
        public let screenshots: [ScreenshotEntry]
    }

    public struct ScreenshotEntry: Codable, Sendable {
        public let order: Int
        public let file: String
    }
}
