public struct PromotedPurchase: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure
    public let appId: String
    public let isVisibleForAllUsers: Bool
    public let isEnabled: Bool
    public let state: PromotedPurchaseState?
    /// Either an IAP id or a subscription id, whichever this slot promotes.
    public let inAppPurchaseId: String?
    public let subscriptionId: String?

    public init(
        id: String,
        appId: String,
        isVisibleForAllUsers: Bool,
        isEnabled: Bool,
        state: PromotedPurchaseState? = nil,
        inAppPurchaseId: String? = nil,
        subscriptionId: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.isVisibleForAllUsers = isVisibleForAllUsers
        self.isEnabled = isEnabled
        self.state = state
        self.inAppPurchaseId = inAppPurchaseId
        self.subscriptionId = subscriptionId
    }
}

public enum PromotedPurchaseState: String, Sendable, Codable, Equatable {
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case developerActionNeeded = "DEVELOPER_ACTION_NEEDED"
}

extension PromotedPurchase: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, isVisibleForAllUsers, isEnabled, state, inAppPurchaseId, subscriptionId
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        isVisibleForAllUsers = try c.decode(Bool.self, forKey: .isVisibleForAllUsers)
        isEnabled = try c.decode(Bool.self, forKey: .isEnabled)
        state = try c.decodeIfPresent(PromotedPurchaseState.self, forKey: .state)
        inAppPurchaseId = try c.decodeIfPresent(String.self, forKey: .inAppPurchaseId)
        subscriptionId = try c.decodeIfPresent(String.self, forKey: .subscriptionId)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encode(isVisibleForAllUsers, forKey: .isVisibleForAllUsers)
        try c.encode(isEnabled, forKey: .isEnabled)
        try c.encodeIfPresent(state, forKey: .state)
        try c.encodeIfPresent(inAppPurchaseId, forKey: .inAppPurchaseId)
        try c.encodeIfPresent(subscriptionId, forKey: .subscriptionId)
    }
}

extension PromotedPurchase: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Visible", "Enabled", "State", "Promotes"]
    }
    public var tableRow: [String] {
        let promotes = inAppPurchaseId.map { "iap:\($0)" } ?? subscriptionId.map { "sub:\($0)" } ?? ""
        return [id, String(isVisibleForAllUsers), String(isEnabled), state?.rawValue ?? "", promotes]
    }
}

extension PromotedPurchase: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "delete": "asc promoted-purchases delete --promoted-id \(id)",
            "listSiblings": "asc promoted-purchases list --app-id \(appId)",
            "update": "asc promoted-purchases update --promoted-id \(id)",
        ]
    }
}
