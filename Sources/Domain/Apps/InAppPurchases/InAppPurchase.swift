public struct InAppPurchase: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure since ASC API omits it from response
    public let appId: String
    public let referenceName: String
    public let productId: String
    public let type: InAppPurchaseType
    public let state: InAppPurchaseState

    public init(
        id: String,
        appId: String,
        referenceName: String,
        productId: String,
        type: InAppPurchaseType,
        state: InAppPurchaseState
    ) {
        self.id = id
        self.appId = appId
        self.referenceName = referenceName
        self.productId = productId
        self.type = type
        self.state = state
    }
}

public enum InAppPurchaseType: String, Sendable, Codable, Equatable {
    case consumable = "CONSUMABLE"
    case nonConsumable = "NON_CONSUMABLE"
    case nonRenewingSubscription = "NON_RENEWING_SUBSCRIPTION"
    case freeSubscription = "FREE_SUBSCRIPTION"

    public init?(cliArgument: String) {
        switch cliArgument.lowercased() {
        case "consumable": self = .consumable
        case "non-consumable": self = .nonConsumable
        case "non-renewing-subscription": self = .nonRenewingSubscription
        case "free-subscription": self = .freeSubscription
        default: return nil
        }
    }

    public var displayName: String {
        switch self {
        case .consumable: return "Consumable"
        case .nonConsumable: return "Non-Consumable"
        case .nonRenewingSubscription: return "Non-Renewing Subscription"
        case .freeSubscription: return "Free Subscription"
        }
    }
}

public enum InAppPurchaseState: String, Sendable, Codable, Equatable {
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

extension InAppPurchase: Presentable {
    public static var tableHeaders: [String] {
        ["ID", "Reference Name", "Product ID", "Type", "State"]
    }
    public var tableRow: [String] {
        [id, referenceName, productId, type.displayName, state.rawValue]
    }
}

extension InAppPurchase: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "createLocalization", command: "iap-localizations", action: "create",
                       params: ["iap-id": id, "locale": "en-US", "name": "<name>"]),
            Affordance(key: "delete", command: "iap", action: "delete",
                       params: ["iap-id": id]),
            Affordance(key: "getAvailability", command: "iap-availability", action: "get",
                       params: ["iap-id": id]),
            Affordance(key: "getPriceSchedule", command: "iap-price-schedule", action: "get",
                       params: ["iap-id": id]),
            Affordance(key: "getReviewScreenshot", command: "iap-review-screenshot", action: "get",
                       params: ["iap-id": id]),
            Affordance(key: "listImages", command: "iap-images", action: "list",
                       params: ["iap-id": id]),
            Affordance(key: "listLocalizations", command: "iap-localizations", action: "list",
                       params: ["iap-id": id]),
            Affordance(key: "listOfferCodes", command: "iap-offer-codes", action: "list",
                       params: ["iap-id": id]),
            Affordance(key: "listPricePoints", command: "iap price-points", action: "list",
                       params: ["iap-id": id]),
            Affordance(key: "update", command: "iap", action: "update",
                       params: ["iap-id": id, "reference-name": "<name>"]),
        ]
        if state == .readyToSubmit {
            items.append(Affordance(key: "submit", command: "iap", action: "submit",
                                    params: ["iap-id": id]))
        }
        return items
    }
}
