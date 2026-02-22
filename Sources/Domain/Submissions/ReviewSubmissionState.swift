public enum ReviewSubmissionState: String, Sendable, Equatable, Codable, CaseIterable {
    case readyForReview = "READY_FOR_REVIEW"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case unresolvedIssues = "UNRESOLVED_ISSUES"
    case canceling = "CANCELING"
    case completing = "COMPLETING"
    case complete = "COMPLETE"

    /// The review process is finished.
    public var isComplete: Bool { self == .complete }

    /// The submission is in Apple's pipeline — agent should wait, not act.
    public var isPending: Bool {
        switch self {
        case .waitingForReview, .inReview, .canceling, .completing: return true
        default: return false
        }
    }

    /// The submission has unresolved issues that require developer action.
    public var hasIssues: Bool { self == .unresolvedIssues }

    public var displayName: String {
        switch self {
        case .readyForReview: return "Ready for Review"
        case .waitingForReview: return "Waiting for Review"
        case .inReview: return "In Review"
        case .unresolvedIssues: return "Unresolved Issues"
        case .canceling: return "Canceling"
        case .completing: return "Completing"
        case .complete: return "Complete"
        }
    }
}