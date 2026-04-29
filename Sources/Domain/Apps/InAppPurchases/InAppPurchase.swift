public struct InAppPurchase: Sendable, Equatable, Identifiable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure since ASC API omits it from response
    public let appId: String
    public let referenceName: String
    public let productId: String
    public let type: InAppPurchaseType
    public let state: InAppPurchaseState
    public let reviewNote: String?
    /// True when this IAP looks like the first IAP being submitted for its app — Apple
    /// requires those to ride along with a new App Store version, which only the iris
    /// private API accepts (`submitWithNextAppStoreVersion: true`). Computed by
    /// Infrastructure when listing IAPs for an app: if no sibling IAP is in an
    /// approved/live state, every unapproved IAP is flagged as first-time. Defaults
    /// to `false` for paths without batch context (`asc iap get`); see
    /// `docs/features/iap-subscriptions/submission-iris-parity.md` for the caveat.
    public let isFirstTimeSubmission: Bool
    /// True when the iris listing reports this IAP is currently queued to ride along
    /// with the next App Store version submission (Apple's iris API exposes the bit
    /// as `attributes.submitWithNextAppStoreVersion`; the public SDK omits it). The
    /// IAP is staged but not yet under review — withdrawing means dequeue, not the
    /// classic "withdraw from active review". Populated only when iris cookies are
    /// available; defaults to `false` so CI scripts using API-key auth keep their
    /// existing JSON output unchanged.
    public let submitWithNextAppStoreVersion: Bool

    public init(
        id: String,
        appId: String,
        referenceName: String,
        productId: String,
        type: InAppPurchaseType,
        state: InAppPurchaseState,
        reviewNote: String? = nil,
        isFirstTimeSubmission: Bool = false,
        submitWithNextAppStoreVersion: Bool = false
    ) {
        self.id = id
        self.appId = appId
        self.referenceName = referenceName
        self.productId = productId
        self.type = type
        self.state = state
        self.reviewNote = reviewNote
        self.isFirstTimeSubmission = isFirstTimeSubmission
        self.submitWithNextAppStoreVersion = submitWithNextAppStoreVersion
    }
}

extension InAppPurchase: Codable {
    enum CodingKeys: String, CodingKey {
        case id, appId, referenceName, productId, type, state, reviewNote
        case isFirstTimeSubmission, submitWithNextAppStoreVersion
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        appId = try c.decode(String.self, forKey: .appId)
        referenceName = try c.decode(String.self, forKey: .referenceName)
        productId = try c.decode(String.self, forKey: .productId)
        type = try c.decode(InAppPurchaseType.self, forKey: .type)
        state = try c.decode(InAppPurchaseState.self, forKey: .state)
        reviewNote = try c.decodeIfPresent(String.self, forKey: .reviewNote)
        isFirstTimeSubmission = try c.decodeIfPresent(Bool.self, forKey: .isFirstTimeSubmission) ?? false
        submitWithNextAppStoreVersion = try c.decodeIfPresent(Bool.self, forKey: .submitWithNextAppStoreVersion) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(appId, forKey: .appId)
        try c.encode(referenceName, forKey: .referenceName)
        try c.encode(productId, forKey: .productId)
        try c.encode(type, forKey: .type)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(reviewNote, forKey: .reviewNote)
        // Omit boolean flags when false to avoid noise in the common case. The
        // affordance dispatch is the user-visible signal; these fields are read-side
        // metadata for agents that want the raw state explicitly.
        if isFirstTimeSubmission {
            try c.encode(isFirstTimeSubmission, forKey: .isFirstTimeSubmission)
        }
        if submitWithNextAppStoreVersion {
            try c.encode(submitWithNextAppStoreVersion, forKey: .submitWithNextAppStoreVersion)
        }
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
    /// True if this IAP has cleared Apple's review at least once. Used by Infrastructure
    /// to decide whether sibling IAPs in the same app are still "first-time" — the
    /// app's first-IAP gate is cleared as soon as one IAP reaches an approved-or-past
    /// state, and `removedFromSale` / `developerRemovedFromSale` both imply the IAP
    /// was approved earlier.
    public var hasBeenApproved: Bool {
        self == .approved || self == .developerRemovedFromSale || self == .removedFromSale
    }
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
            Affordance(key: "uploadReviewScreenshot", command: "iap-review-screenshot", action: "upload",
                       params: ["iap-id": id, "file": "<path>"]),
            Affordance(key: "listImages", command: "iap-images", action: "list",
                       params: ["iap-id": id]),
            Affordance(key: "uploadImage", command: "iap-images", action: "upload",
                       params: ["iap-id": id, "file": "<path>"]),
            Affordance(key: "listLocalizations", command: "iap-localizations", action: "list",
                       params: ["iap-id": id]),
            Affordance(key: "createOfferCode", command: "iap-offer-codes", action: "create",
                       params: ["iap-id": id, "name": "<name>",
                                "eligibility": "<NON_SPENDER|ACTIVE_SPENDER|CHURNED_SPENDER>"]),
            Affordance(key: "listOfferCodes", command: "iap-offer-codes", action: "list",
                       params: ["iap-id": id]),
            Affordance(key: "listPricePoints", command: "iap price-points", action: "list",
                       params: ["iap-id": id]),
            // Sets (or changes) the base price by picking a new base territory + price point.
            // Apple equalizes other territories from this manual entry. Calling with a new
            // `base-territory` is how the iOS app implements "Change Base Territory".
            Affordance(key: "setPrice", command: "iap prices", action: "set",
                       params: ["iap-id": id, "base-territory": "<territory>", "price-point-id": "<price-point-id>"]),
            Affordance(key: "update", command: "iap", action: "update",
                       params: ["iap-id": id, "reference-name": "<name>"]),
        ]
        if state == .readyToSubmit {
            if submitWithNextAppStoreVersion {
                // Already queued via iris — re-submitting via either path would be
                // rejected. Only surface the dequeue affordance. Iris-queued
                // submissions can only be removed via the iris DELETE endpoint
                // (public-SDK DELETE returns errors for them); the submission resource
                // is keyed by parent IAP id in iris so `--submission-id <iapId>` works.
                items.append(Affordance(key: "removeFromNextVersion", command: "iris iap-submissions", action: "delete",
                                        params: ["submission-id": id]))
            } else {
                // Inverse of removeFromNextVersion: `addToNextVersion` queues this IAP
                // to ride along with the next App Store version submission via iris.
                // Always available when ready and not yet queued — Apple permits it
                // for both first-time and subsequent IAPs.
                items.append(Affordance(key: "addToNextVersion", command: "iris iap-submissions", action: "create",
                                        params: ["iap-id": id]))
                // `submit` (public-SDK direct) is only available once the app has
                // shipped at least one IAP — Apple rejects the direct path for the
                // first IAP. Established apps see both options; the agent picks
                // standalone-review (submit) vs ride-along-with-version (addToNextVersion).
                if !isFirstTimeSubmission {
                    items.append(Affordance(key: "submit", command: "iap", action: "submit",
                                            params: ["iap-id": id]))
                }
            }
        }
        return items
    }
}
