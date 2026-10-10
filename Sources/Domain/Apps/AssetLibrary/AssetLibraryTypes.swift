/// What an asset is for. Fixed when the asset is reserved — App Store Connect never changes it.
public enum AssetCategory: String, Sendable, Equatable, Codable, CaseIterable {
    /// Screenshots and app previews for product pages.
    case appScreenshotsAndPreviews = "APP_SCREENSHOTS_AND_PREVIEWS"
    /// Other marketing media: in-app event artwork, product page header assets, …
    case creativeAssets = "CREATIVE_ASSETS"
}

/// Where an image or video is in its life: upload, processing, then App Review.
public enum LibraryAssetState: String, Sendable, Equatable, Codable, CaseIterable {
    case awaitingUpload = "AWAITING_UPLOAD"
    case uploadComplete = "UPLOAD_COMPLETE"
    case failed = "FAILED"
    case complete = "COMPLETE"
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case readyForReview = "READY_FOR_REVIEW"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case accepted = "ACCEPTED"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case archived = "ARCHIVED"

    /// Reserved, but the file hasn't been sent and committed yet.
    public var isAwaitingUpload: Bool { self == .awaitingUpload }

    /// App Store Connect has the file and is processing it.
    public var isProcessing: Bool { self == .uploadComplete }

    /// Processed — a placement can show it.
    public var isPlaceable: Bool {
        [.complete, .prepareForSubmission, .readyForReview, .waitingForReview, .inReview, .accepted, .approved].contains(self)
    }

    public var isInReview: Bool { [.waitingForReview, .inReview].contains(self) }

    public var isApproved: Bool { [.accepted, .approved].contains(self) }

    /// App Store Connect only archives approved assets.
    public var isArchivable: Bool { self == .approved }

    /// Processing failed or App Review rejected it — read `stateDetails`.
    public var isFailed: Bool { [.failed, .rejected].contains(self) }
}

/// Why an asset or placement is in its state (ASC API: `stateDetails[]`).
public struct AssetStateDetail: Sendable, Equatable, Codable {
    public let code: String?
    public let description: String?

    public init(code: String?, description: String?) {
        self.code = code
        self.description = description
    }
}

public enum AssetMediaType: String, Sendable, Equatable, Codable, CaseIterable {
    case image = "IMAGE"
    case video = "VIDEO"
}

/// The kind of slot a placement fills.
public enum AssetPlacementType: String, Sendable, Equatable, Codable, CaseIterable {
    case appScreenshot = "APP_SCREENSHOT"
    case imessageAppScreenshot = "IMESSAGE_APP_SCREENSHOT"
    case appPreview = "APP_PREVIEW"
    case productPageHeaderAsset = "PRODUCT_PAGE_HEADER_ASSET"
    case appStoreSearchResultsAsset = "APP_STORE_SEARCH_RESULTS_ASSET"
    case searchResultsAdsAsset = "SEARCH_RESULTS_ADS_ASSET"
    case todayTabAdsAsset = "TODAY_TAB_ADS_ASSET"
    case eventCardAsset = "EVENT_CARD_ASSET"
    case eventDetailsPageAsset = "EVENT_DETAILS_PAGE_ASSET"
    case retentionMessageAsset = "RETENTION_MESSAGE_ASSET"
}
