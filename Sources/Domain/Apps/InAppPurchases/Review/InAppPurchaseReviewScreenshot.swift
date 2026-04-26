public struct InAppPurchaseReviewScreenshot: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure
    public let iapId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetState?

    public enum AssetState: String, Sendable, Codable, Equatable {
        case awaitingUpload = "AWAITING_UPLOAD"
        case uploadComplete = "UPLOAD_COMPLETE"
        case complete = "COMPLETE"
        case failed = "FAILED"
    }

    public init(id: String, iapId: String, fileName: String, fileSize: Int, assetState: AssetState? = nil) {
        self.id = id
        self.iapId = iapId
        self.fileName = fileName
        self.fileSize = fileSize
        self.assetState = assetState
    }
}

extension InAppPurchaseReviewScreenshot: Codable {
    enum CodingKeys: String, CodingKey {
        case id, iapId, fileName, fileSize, assetState
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        assetState = try c.decodeIfPresent(AssetState.self, forKey: .assetState)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(assetState, forKey: .assetState)
    }
}

extension InAppPurchaseReviewScreenshot: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "File Size", "State"] }
    public var tableRow: [String] { [id, fileName, String(fileSize), assetState?.rawValue ?? ""] }
}

extension InAppPurchaseReviewScreenshot: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc iap-review-screenshot delete --screenshot-id \(id)",
            "get": "asc iap-review-screenshot get --iap-id \(iapId)",
        ]
    }
}

public struct InAppPurchasePromotionalImage: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure
    public let iapId: String
    public let fileName: String
    public let fileSize: Int
    public let state: ImageState?

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

    public init(id: String, iapId: String, fileName: String, fileSize: Int, state: ImageState? = nil) {
        self.id = id
        self.iapId = iapId
        self.fileName = fileName
        self.fileSize = fileSize
        self.state = state
    }
}

extension InAppPurchasePromotionalImage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, iapId, fileName, fileSize, state
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        iapId = try c.decode(String.self, forKey: .iapId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        state = try c.decodeIfPresent(ImageState.self, forKey: .state)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(iapId, forKey: .iapId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(state, forKey: .state)
    }
}

extension InAppPurchasePromotionalImage: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "File Size", "State"] }
    public var tableRow: [String] { [id, fileName, String(fileSize), state?.rawValue ?? ""] }
}

extension InAppPurchasePromotionalImage: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc iap-images delete --image-id \(id)",
            "listSiblings": "asc iap-images list --iap-id \(iapId)",
        ]
    }
}
