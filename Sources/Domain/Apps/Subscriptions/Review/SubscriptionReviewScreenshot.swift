public struct SubscriptionReviewScreenshot: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure
    public let subscriptionId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetState?

    public enum AssetState: String, Sendable, Codable, Equatable {
        case awaitingUpload = "AWAITING_UPLOAD"
        case uploadComplete = "UPLOAD_COMPLETE"
        case complete = "COMPLETE"
        case failed = "FAILED"

        public var isComplete: Bool { self == .uploadComplete || self == .complete }
        public var hasFailed: Bool { self == .failed }
    }

    public init(id: String, subscriptionId: String, fileName: String, fileSize: Int, assetState: AssetState? = nil) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.fileName = fileName
        self.fileSize = fileSize
        self.assetState = assetState
    }
}

extension SubscriptionReviewScreenshot: Codable {
    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, fileName, fileSize, assetState
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        subscriptionId = try c.decode(String.self, forKey: .subscriptionId)
        fileName = try c.decode(String.self, forKey: .fileName)
        fileSize = try c.decode(Int.self, forKey: .fileSize)
        assetState = try c.decodeIfPresent(AssetState.self, forKey: .assetState)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(subscriptionId, forKey: .subscriptionId)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(fileSize, forKey: .fileSize)
        try c.encodeIfPresent(assetState, forKey: .assetState)
    }
}

extension SubscriptionReviewScreenshot: Presentable {
    public static var tableHeaders: [String] { ["ID", "File Name", "File Size", "State"] }
    public var tableRow: [String] { [id, fileName, String(fileSize), assetState?.rawValue ?? ""] }
}

extension SubscriptionReviewScreenshot: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        _ = RESTPathResolver._subscriptionReviewAssetRoutes
        var items: [Affordance] = [
            Affordance(key: "get", command: "subscription-review-screenshot", action: "get", params: ["subscription-id": subscriptionId]),
            Affordance(key: "upload", command: "subscription-review-screenshot", action: "upload", params: ["subscription-id": subscriptionId, "file": "<path>"]),
        ]
        if assetState?.isComplete ?? false || assetState?.hasFailed ?? false {
            items.append(Affordance(key: "delete", command: "subscription-review-screenshot", action: "delete", params: ["screenshot-id": id]))
        }
        return items
    }
}

extension RESTPathResolver {
    static let _subscriptionReviewAssetRoutes: Void = {
        registerRoute(
            command: "subscription-review-screenshot",
            parentParam: "subscription-id",
            parentSegment: "subscriptions",
            segment: "review-screenshot"
        )
    }()
}
