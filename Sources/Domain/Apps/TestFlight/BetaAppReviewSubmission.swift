import Foundation

public struct BetaAppReviewSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent build identifier — injected by infrastructure.
    public let buildId: String
    public let state: BetaReviewState
    public let submittedDate: Date?

    public init(
        id: String,
        buildId: String,
        state: BetaReviewState = .waitingForReview,
        submittedDate: Date? = nil
    ) {
        self.id = id
        self.buildId = buildId
        self.state = state
        self.submittedDate = submittedDate
    }

    public var isApproved: Bool { state == .approved }
    public var isRejected: Bool { state == .rejected }
    public var isPending: Bool { state == .waitingForReview }
    public var isInReview: Bool { state == .inReview }
}

// MARK: - BetaReviewState

public enum BetaReviewState: String, Sendable, Codable, Equatable {
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case rejected = "REJECTED"
    case approved = "APPROVED"
}

// MARK: - AffordanceProviding

extension BetaAppReviewSubmission: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getSubmission": "asc beta-review submissions get --submission-id \(id)",
            "listSubmissions": "asc beta-review submissions list --build-id \(buildId)",
        ]
    }
}