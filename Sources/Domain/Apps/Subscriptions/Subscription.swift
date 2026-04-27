public struct Subscription: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent subscription group identifier — injected by Infrastructure since ASC API omits it from response
    public let groupId: String
    public let name: String
    public let productId: String
    public let subscriptionPeriod: SubscriptionPeriod
    public let isFamilySharable: Bool
    public let state: SubscriptionState
    public let groupLevel: Int?

    public init(
        id: String,
        groupId: String,
        name: String,
        productId: String,
        subscriptionPeriod: SubscriptionPeriod,
        isFamilySharable: Bool = false,
        state: SubscriptionState,
        groupLevel: Int? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.name = name
        self.productId = productId
        self.subscriptionPeriod = subscriptionPeriod
        self.isFamilySharable = isFamilySharable
        self.state = state
        self.groupLevel = groupLevel
    }
}

public enum SubscriptionPeriod: String, Sendable, Codable, Equatable {
    case oneWeek = "ONE_WEEK"
    case oneMonth = "ONE_MONTH"
    case twoMonths = "TWO_MONTHS"
    case threeMonths = "THREE_MONTHS"
    case sixMonths = "SIX_MONTHS"
    case oneYear = "ONE_YEAR"

    public var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        case .twoMonths: return "2 Months"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        }
    }
}

public enum SubscriptionState: String, Sendable, Codable, Equatable {
    case missingMetadata = "MISSING_METADATA"
    case readyToSubmit = "READY_TO_SUBMIT"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case developerActionNeeded = "DEVELOPER_ACTION_NEEDED"
    case pendingBinaryApproval = "PENDING_BINARY_APPROVAL"
    case approved = "APPROVED"
    case developerRemovedFromSale = "DEVELOPER_REMOVED_FROM_SALE"
    case removedFromSale = "REMOVED_FROM_SALE"
    case rejected = "REJECTED"

    public var isApproved: Bool { self == .approved }
    public var isLive: Bool { self == .approved }
    public var isEditable: Bool {
        self == .missingMetadata || self == .rejected || self == .developerActionNeeded
    }
    public var isPendingReview: Bool { self == .waitingForReview || self == .inReview }
}

extension Subscription: Codable {
    enum CodingKeys: String, CodingKey {
        case id, groupId, name, productId, subscriptionPeriod, isFamilySharable, state, groupLevel
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        groupId = try c.decode(String.self, forKey: .groupId)
        name = try c.decode(String.self, forKey: .name)
        productId = try c.decode(String.self, forKey: .productId)
        subscriptionPeriod = try c.decode(SubscriptionPeriod.self, forKey: .subscriptionPeriod)
        isFamilySharable = try c.decode(Bool.self, forKey: .isFamilySharable)
        state = try c.decode(SubscriptionState.self, forKey: .state)
        groupLevel = try c.decodeIfPresent(Int.self, forKey: .groupLevel)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(groupId, forKey: .groupId)
        try c.encode(name, forKey: .name)
        try c.encode(productId, forKey: .productId)
        try c.encode(subscriptionPeriod, forKey: .subscriptionPeriod)
        try c.encode(isFamilySharable, forKey: .isFamilySharable)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(groupLevel, forKey: .groupLevel)
    }
}

extension Subscription: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Name", "Product ID", "Period", "State"]
    }
    public var tableRow: [String] {
        [id, name, productId, subscriptionPeriod.displayName, state.rawValue]
    }
}

extension Subscription: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "createIntroductoryOffer", command: "subscription-offers", action: "create",
                       params: ["subscription-id": id, "duration": "ONE_MONTH", "mode": "FREE_TRIAL", "periods": "1"]),
            Affordance(key: "createLocalization", command: "subscription-localizations", action: "create",
                       params: ["subscription-id": id, "locale": "en-US", "name": "<name>"]),
            Affordance(key: "createPromotionalOffer", command: "subscription-promotional-offers", action: "create",
                       params: ["subscription-id": id, "name": "<name>", "offer-code": "<code>", "duration": "ONE_MONTH", "mode": "PAY_AS_YOU_GO", "periods": "1"]),
            Affordance(key: "delete", command: "subscriptions", action: "delete",
                       params: ["subscription-id": id]),
            Affordance(key: "getAvailability", command: "subscription-availability", action: "get",
                       params: ["subscription-id": id]),
            Affordance(key: "getReviewScreenshot", command: "subscription-review-screenshot", action: "get",
                       params: ["subscription-id": id]),
            Affordance(key: "listIntroductoryOffers", command: "subscription-offers", action: "list",
                       params: ["subscription-id": id]),
            Affordance(key: "listLocalizations", command: "subscription-localizations", action: "list",
                       params: ["subscription-id": id]),
            Affordance(key: "listOfferCodes", command: "subscription-offer-codes", action: "list",
                       params: ["subscription-id": id]),
            Affordance(key: "listPromotionalOffers", command: "subscription-promotional-offers", action: "list",
                       params: ["subscription-id": id]),
            Affordance(key: "listWinBackOffers", command: "win-back-offers", action: "list",
                       params: ["subscription-id": id]),
            Affordance(key: "listPricePoints", command: "subscriptions price-points", action: "list",
                       params: ["subscription-id": id]),
            Affordance(key: "update", command: "subscriptions", action: "update",
                       params: ["subscription-id": id, "name": "<name>"]),
        ]
        if state == .readyToSubmit {
            items.append(Affordance(key: "submit", command: "subscriptions", action: "submit",
                                    params: ["subscription-id": id]))
        }
        return items
    }
}
