public struct InAppPurchaseReviewScreenshot: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure
    public let iapId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetState?
    /// CDN-hosted image with a `{w}x{h}bb.{f}` template URL — populated once ASC finishes
    /// processing the upload. Nil while `assetState == .awaitingUpload`.
    public let imageAsset: ImageAsset?

    public enum AssetState: String, Sendable, Codable, Equatable {
        case awaitingUpload = "AWAITING_UPLOAD"
        case uploadComplete = "UPLOAD_COMPLETE"
        case complete = "COMPLETE"
        case failed = "FAILED"

        public var isComplete: Bool { self == .uploadComplete || self == .complete }
        public var hasFailed: Bool { self == .failed }
    }

    public init(
        id: String,
        iapId: String,
        fileName: String,
        fileSize: Int,
        assetState: AssetState? = nil,
        imageAsset: ImageAsset? = nil
    ) {
        self.id = id
        self.iapId = iapId
        self.fileName = fileName
        self.fileSize = fileSize
        self.assetState = assetState
        self.imageAsset = imageAsset
    }
}

extension InAppPurchaseReviewScreenshot: Codable {
    enum CodingKeys: String, CodingKey {
        case id, iapId, fileName, fileSize, assetState, imageAsset
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        assetState = try c.decodeIfPresent(AssetState.self, forKey: .assetState)
        imageAsset = try c.decodeIfPresent(ImageAsset.self, forKey: .imageAsset)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(assetState, forKey: .assetState)
        try c.encodeIfPresent(imageAsset, forKey: .imageAsset)
    }
}

extension InAppPurchaseReviewScreenshot: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "File Size", "State"] }
    public var tableRow: [String] { [id, fileName, String(fileSize), assetState?.rawValue ?? ""] }
}

extension InAppPurchaseReviewScreenshot: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        _ = RESTPathResolver._iapReviewAssetRoutes
        var items: [Affordance] = [
            Affordance(key: "get", command: "iap-review-screenshot", action: "get", params: ["iap-id": iapId]),
            Affordance(key: "upload", command: "iap-review-screenshot", action: "upload", params: ["iap-id": iapId, "file": "<path>"]),
        ]
        // Delete is offered once the asset is reachable (upload finished or failed).
        // While `awaitingUpload`, the slot is reserved but the asset isn't there
        // yet — re-uploading is the natural recovery path.
        if assetState?.isComplete ?? false || assetState?.hasFailed ?? false {
            items.append(Affordance(key: "delete", command: "iap-review-screenshot", action: "delete", params: ["screenshot-id": id]))
        }
        return items
    }
}

public struct InAppPurchasePromotionalImage: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure
    public let iapId: String
    public let fileName: String
    public let fileSize: Int
    public let state: ImageState?
    public let imageAsset: ImageAsset?

    public enum ImageState: String, Sendable, Codable, Equatable {
        case awaitingUpload = "AWAITING_UPLOAD"
        case uploadComplete = "UPLOAD_COMPLETE"
        case failed = "FAILED"
        case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
        case waitingForReview = "WAITING_FOR_REVIEW"
        case approved = "APPROVED"
        case rejected = "REJECTED"

        public var isApproved: Bool { self == .approved }
        public var isPendingReview: Bool { self == .waitingForReview }
    }

    public init(
        id: String,
        iapId: String,
        fileName: String,
        fileSize: Int,
        state: ImageState? = nil,
        imageAsset: ImageAsset? = nil
    ) {
        self.id = id
        self.iapId = iapId
        self.fileName = fileName
        self.fileSize = fileSize
        self.state = state
        self.imageAsset = imageAsset
    }
}

extension InAppPurchasePromotionalImage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, iapId, fileName, fileSize, state, imageAsset
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        state = try c.decodeIfPresent(ImageState.self, forKey: .state)
        imageAsset = try c.decodeIfPresent(ImageAsset.self, forKey: .imageAsset)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(state, forKey: .state)
        try c.encodeIfPresent(imageAsset, forKey: .imageAsset)
    }
}

extension InAppPurchasePromotionalImage: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "File Size", "State"] }
    public var tableRow: [String] { [id, fileName, String(fileSize), state?.rawValue ?? ""] }
}

extension InAppPurchasePromotionalImage: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        _ = RESTPathResolver._iapReviewAssetRoutes
        var items: [Affordance] = [
            Affordance(key: "listSiblings", command: "iap-images", action: "list", params: ["iap-id": iapId]),
        ]
        // Delete is suppressed while App Review is looking at the image — submitting
        // a delete during review is a 409 conflict in ASC.
        if !(state?.isPendingReview ?? false) {
            items.append(Affordance(key: "delete", command: "iap-images", action: "delete", params: ["image-id": id]))
        }
        return items
    }
}

extension RESTPathResolver {
    static let _iapReviewAssetRoutes: Void = {
        // Single review screenshot per IAP — represented as a 1-element collection at
        // /api/v1/apps/{iapId}/iap-review-screenshot. Conceptually a singleton, but the
        // shape mirrors other nested resources for agent navigation.
        registerRoute(
            command: "iap-review-screenshot",
            parentParam: "iap-id",
            parentSegment: "iap",
            segment: "review-screenshot"
        )
        registerRoute(
            command: "iap-images",
            parentParam: "iap-id",
            parentSegment: "iap",
            segment: "images"
        )
    }()
}
