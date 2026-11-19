/// State of a single item attached to a `ReviewSubmission`.
///
/// When a submission's overall state is `UNRESOLVED_ISSUES`, the item-level state
/// pinpoints *which* attached resource Apple rejected. Apple's free-text reasoning
/// lives in the App Store Connect Resolution Center web UI only — the public API
/// exposes the state enum but not the reviewer's notes.
public enum ReviewSubmissionItemState: String, Sendable, Equatable, Codable, CaseIterable {
    case readyForReview = "READY_FOR_REVIEW"
    case accepted = "ACCEPTED"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case removed = "REMOVED"

    /// Apple rejected this item — developer action required.
    public var isRejected: Bool { self == .rejected }

    /// Apple passed this item (either preliminary intake or final approval).
    public var isApproved: Bool { self == .accepted || self == .approved }

    /// Waiting on Apple — agent should poll, not act.
    public var isPending: Bool { self == .readyForReview }

    public var displayName: String {
        switch self {
        case .readyForReview: return "Ready for Review"
        case .accepted: return "Accepted"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .removed: return "Removed"
        }
    }
}
