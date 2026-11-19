/// A reviewable version of an in-app purchase, subscription or subscription group.
///
/// Apple versions products the same way it versions apps: each change goes through
/// review as a version, and a version is sent to review by adding it as an item to a
/// `ReviewSubmission` — alongside an app version when the product is new.
public struct ProductVersion: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent product identifier (IAP, subscription or subscription group id) —
    /// Apple's response omits it, so Infrastructure injects it from the request.
    public let productId: String
    public let kind: ProductVersionKind
    public let version: Int?
    public let state: ProductVersionState

    public init(id: String, productId: String, kind: ProductVersionKind, version: Int?, state: ProductVersionState) {
        self.id = id
        self.productId = productId
        self.kind = kind
        self.version = version
        self.state = state
    }

    public var isSubmittable: Bool { state.isSubmittable }
    public var isInReview: Bool { state.isInReview }
    public var isApproved: Bool { state.isApproved }
}

public enum ProductVersionKind: String, Sendable, Equatable, Codable, CaseIterable {
    case inAppPurchase = "IN_APP_PURCHASE"
    case subscription = "SUBSCRIPTION"
    case subscriptionGroup = "SUBSCRIPTION_GROUP"

    /// `asc` command that lists versions of this kind's product.
    var listCommand: String {
        switch self {
        case .inAppPurchase: "iap versions"
        case .subscription: "subscriptions versions"
        case .subscriptionGroup: "subscription-groups versions"
        }
    }

    /// Flag naming the parent product in `listCommand`.
    var productParam: String {
        switch self {
        case .inAppPurchase: "iap-id"
        case .subscription: "subscription-id"
        case .subscriptionGroup: "group-id"
        }
    }

    /// Flag `review-submissions items add` takes for a version of this kind.
    public var itemParam: String {
        switch self {
        case .inAppPurchase: "iap-version-id"
        case .subscription: "subscription-version-id"
        case .subscriptionGroup: "subscription-group-version-id"
        }
    }
}

public enum ProductVersionState: String, Sendable, Equatable, Codable, CaseIterable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case readyForReview = "READY_FOR_REVIEW"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case accepted = "ACCEPTED"
    case approved = "APPROVED"
    case replacedWithNewVersion = "REPLACED_WITH_NEW_VERSION"
    case rejected = "REJECTED"
    case developerRejected = "DEVELOPER_REJECTED"

    /// Can be added to a review submission.
    public var isSubmittable: Bool {
        self == .prepareForSubmission || self == .rejected || self == .developerRejected
    }

    public var isInReview: Bool { self == .waitingForReview || self == .inReview }

    public var isApproved: Bool { self == .accepted || self == .approved }
}

extension ProductVersion: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items = [
            Affordance(key: "listVersions", command: kind.listCommand, action: "list",
                       params: [kind.productParam: productId]),
        ]
        if isSubmittable {
            items.append(Affordance(key: "addToSubmission", command: "review-submissions items", action: "add",
                                    params: ["submission-id": "<submission-id>", kind.itemParam: id]))
        }
        return items
    }
}

extension ProductVersion: Presentable {
    public static var tableHeaders: [String] { ["ID", "Product ID", "Kind", "Version", "State"] }
    public var tableRow: [String] { [id, productId, kind.rawValue, version.map(String.init) ?? "-", state.rawValue] }
}
