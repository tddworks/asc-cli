/// What a review submission item sends to review: an app version, or a version
/// of an in-app purchase, subscription or subscription group.
public enum ReviewItemTarget: Sendable, Equatable {
    case appStoreVersion(String)
    case inAppPurchaseVersion(String)
    case subscriptionVersion(String)
    case subscriptionGroupVersion(String)

    /// The item named by exactly one version id (the CLI flags / REST body keys
    /// `version-id`, `iap-version-id`, `subscription-version-id`,
    /// `subscription-group-version-id`); `nil` when none or several are given.
    public init?(
        versionId: String? = nil,
        iapVersionId: String? = nil,
        subscriptionVersionId: String? = nil,
        subscriptionGroupVersionId: String? = nil
    ) {
        let targets: [ReviewItemTarget] = [
            versionId.map(ReviewItemTarget.appStoreVersion),
            iapVersionId.map(ReviewItemTarget.inAppPurchaseVersion),
            subscriptionVersionId.map(ReviewItemTarget.subscriptionVersion),
            subscriptionGroupVersionId.map(ReviewItemTarget.subscriptionGroupVersion),
        ].compactMap { $0 }
        guard targets.count == 1, let target = targets.first else { return nil }
        self = target
    }

    public var id: String {
        switch self {
        case .appStoreVersion(let id), .inAppPurchaseVersion(let id),
             .subscriptionVersion(let id), .subscriptionGroupVersion(let id):
            return id
        }
    }

    public var linkedResource: ReviewSubmissionItemLinkedResource {
        switch self {
        case .appStoreVersion: .appStoreVersion
        case .inAppPurchaseVersion: .inAppPurchaseVersion
        case .subscriptionVersion: .subscriptionVersion
        case .subscriptionGroupVersion: .subscriptionGroupVersion
        }
    }
}
