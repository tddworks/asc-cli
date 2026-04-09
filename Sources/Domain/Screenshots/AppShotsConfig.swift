import Foundation

public struct AppShotsConfig: Sendable, Equatable, Codable {
    public let geminiApiKey: String

    public init(geminiApiKey: String) {
        self.geminiApiKey = geminiApiKey
    }
}
