/// Promotional image for a subscription. Mirrors `InAppPurchasePromotionalImage` for the
/// equivalent IAP-side asset.
public struct SubscriptionPromotionalImage: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure
    public let subscriptionId: String
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

    public init(id: String, subscriptionId: String, fileName: String, fileSize: Int, state: ImageState? = nil) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.fileName = fileName
        self.fileSize = fileSize
        self.state = state
    }
}

extension SubscriptionPromotionalImage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, fileName, fileSize, state
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        subscriptionId = try c.decode(String.self, forKey: .subscriptionId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        state = try c.decodeIfPresent(ImageState.self, forKey: .state)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(subscriptionId, forKey: .subscriptionId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(state, forKey: .state)
    }
}

extension SubscriptionPromotionalImage: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "File Size", "State"] }
    public var tableRow: [String] { [id, fileName, String(fileSize), state?.rawValue ?? ""] }
}

extension SubscriptionPromotionalImage: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        _ = RESTPathResolver._subscriptionPromotionalImageRoutes
        var items: [Affordance] = [
            Affordance(key: "listSiblings", command: "subscription-images", action: "list", params: ["subscription-id": subscriptionId]),
        ]
        if !(state?.isPendingReview ?? false) {
            items.append(Affordance(key: "delete", command: "subscription-images", action: "delete", params: ["image-id": id]))
        }
        return items
    }
}

extension RESTPathResolver {
    static let _subscriptionPromotionalImageRoutes: Void = {
        registerRoute(
            command: "subscription-images",
            parentParam: "subscription-id",
            parentSegment: "subscriptions",
            segment: "images"
        )
    }()
}
