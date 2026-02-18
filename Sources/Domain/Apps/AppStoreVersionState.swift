public enum AppStoreVersionState: String, Sendable, Equatable, Codable, CaseIterable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case pendingDeveloperRelease = "PENDING_DEVELOPER_RELEASE"
    case pendingAppleRelease = "PENDING_APPLE_RELEASE"
    case processingForAppStore = "PROCESSING_FOR_APP_STORE"
    case readyForSale = "READY_FOR_SALE"
    case developerRejected = "DEVELOPER_REJECTED"
    case rejected = "REJECTED"
    case metadataRejected = "METADATA_REJECTED"
    case removedFromSale = "REMOVED_FROM_SALE"
    case developerRemovedFromSale = "DEVELOPER_REMOVED_FROM_SALE"
    case invalidBinary = "INVALID_BINARY"
    case waitingForExportCompliance = "WAITING_FOR_EXPORT_COMPLIANCE"
    case pendingContract = "PENDING_CONTRACT"

    /// The version is live on the App Store.
    public var isLive: Bool { self == .readyForSale }

    /// The version can be edited (metadata, screenshots, etc.).
    public var isEditable: Bool {
        switch self {
        case .prepareForSubmission, .developerRejected, .rejected, .metadataRejected:
            return true
        default:
            return false
        }
    }

    /// The version is in Apple's review pipeline — agent should wait, not act.
    public var isPending: Bool {
        switch self {
        case .waitingForReview, .inReview, .pendingDeveloperRelease,
             .pendingAppleRelease, .processingForAppStore, .waitingForExportCompliance:
            return true
        default:
            return false
        }
    }

    public var displayName: String {
        switch self {
        case .prepareForSubmission: return "Prepare for Submission"
        case .waitingForReview: return "Waiting for Review"
        case .inReview: return "In Review"
        case .pendingDeveloperRelease: return "Pending Developer Release"
        case .pendingAppleRelease: return "Pending Apple Release"
        case .processingForAppStore: return "Processing for App Store"
        case .readyForSale: return "Ready for Sale"
        case .developerRejected: return "Developer Rejected"
        case .rejected: return "Rejected"
        case .metadataRejected: return "Metadata Rejected"
        case .removedFromSale: return "Removed from Sale"
        case .developerRemovedFromSale: return "Developer Removed from Sale"
        case .invalidBinary: return "Invalid Binary"
        case .waitingForExportCompliance: return "Waiting for Export Compliance"
        case .pendingContract: return "Pending Contract"
        }
    }
}
