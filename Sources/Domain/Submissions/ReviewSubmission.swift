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
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "getSubmission", command: "review-submissions", action: "get",
                       params: ["submission-id": id]),
            Affordance(key: "listItems", command: "review-submissions items", action: "list",
                       params: ["submission-id": id]),
            Affordance(key: "listVersions", command: "versions", action: "list",
                       params: ["app-id": appId]),
        ]
        if hasIssues {
            // Agent shortcut: when Apple flags issues, the rejected items expose
            // which resource needs fixing — surface them as the first thing to do.
            items.append(Affordance(key: "listRejectedItems", command: "review-submissions items", action: "list",
                                    params: ["submission-id": id, "state": "REJECTED"]))
            // The reviewer's message text lives only behind the iris (cookie-auth)
            // surface — the official API has no resolutionCenter endpoints.
            items.append(Affordance(key: "getResolutionDetails", command: "iris resolution-center", action: "get",
                                    params: ["submission-id": id]))
        }
        return items
    }
}

extension ReviewSubmission: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "App ID", "Platform", "State"]
    }
    public var tableRow: [String] {
        [id, appId, platform.rawValue, state.rawValue]
    }
}