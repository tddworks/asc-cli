import Foundation

public struct ReviewSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — always present so agents can correlate responses.
    public let appId: String
    public let platform: AppStorePlatform
    public let state: ReviewSubmissionState
    public let submittedDate: Date?

    public init(
        id: String,
        appId: String,
        platform: AppStorePlatform,
        state: ReviewSubmissionState,
        submittedDate: Date? = nil
    ) {
        self.id = id
        self.appId = appId
        self.platform = platform
        self.state = state
        self.submittedDate = submittedDate
    }

    public var isComplete: Bool { state.isComplete }
    public var isPending: Bool { state.isPending }
    public var hasIssues: Bool { state.hasIssues }
}

extension ReviewSubmission: AffordanceProviding {
    public var affordances: [String: String] {
        ["listVersions": "asc versions list --app-id \(appId)"]
    }
}