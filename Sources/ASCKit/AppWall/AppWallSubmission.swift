import Foundation

/// The result of submitting an app wall entry — a GitHub pull request.
public struct AppWallSubmission: Sendable, Equatable, Codable, Identifiable, AffordanceProviding {
    public var id: String { String(prNumber) }
    public let prNumber: Int
    public let prUrl: String
    public let title: String
    public let developer: String

    public init(prNumber: Int, prUrl: String, title: String, developer: String) {
        self.prNumber = prNumber
        self.prUrl = prUrl
        self.title = title
        self.developer = developer
    }

    public var affordances: [String: String] {
        ["openPR": "open \(prUrl)"]
    }
}
