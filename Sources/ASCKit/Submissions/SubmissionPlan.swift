/// Everything to send to App Review together with an app version: the version
/// itself first, then each ready product's submittable version. A subscription
/// group's version goes right before its subscriptions.
public struct SubmissionPlan: Sendable, Equatable {
    public let appId: String
    public let platform: AppStorePlatform
    public let items: [PlannedReviewItem]

    public init(appId: String, platform: AppStorePlatform, items: [PlannedReviewItem]) {
        self.appId = appId
        self.platform = platform
        self.items = items
    }

    /// Opens (or reuses) the app's draft, adds the items in order and submits it.
    /// Stops at the first item Apple refuses, before anything is submitted — the
    /// items added so far stay in the draft.
    public func submit(repo: some SubmissionRepository) async throws -> ReviewSubmission {
        let draft = try await repo.createSubmission(appId: appId, platform: platform)
        for item in items {
            _ = try await repo.addItem(submissionId: draft.id, target: item.target)
        }
        return try await repo.submit(submissionId: draft.id)
    }
}

/// One thing a `SubmissionPlan` sends to review.
public struct PlannedReviewItem: Sendable, Equatable, Codable {
    public let kind: ReviewSubmissionItemLinkedResource
    /// The app version id, or the product version id.
    public let versionId: String
    /// The app id for the app version, else the IAP, subscription or group id.
    public let productId: String
    /// Version string for the app version, else the product's name.
    public let name: String

    public init(kind: ReviewSubmissionItemLinkedResource, versionId: String, productId: String, name: String) {
        self.kind = kind
        self.versionId = versionId
        self.productId = productId
        self.name = name
    }

    var target: ReviewItemTarget {
        switch kind {
        case .inAppPurchaseVersion: .inAppPurchaseVersion(versionId)
        case .subscriptionVersion: .subscriptionVersion(versionId)
        case .subscriptionGroupVersion: .subscriptionGroupVersion(versionId)
        default: .appStoreVersion(versionId)
        }
    }
}

extension PlannedReviewItem: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        switch kind {
        case .inAppPurchaseVersion:
            [Affordance(key: "listVersions", command: "iap versions", action: "list", params: ["iap-id": productId])]
        case .subscriptionVersion:
            [Affordance(key: "listVersions", command: "subscriptions versions", action: "list", params: ["subscription-id": productId])]
        case .subscriptionGroupVersion:
            [Affordance(key: "listVersions", command: "subscription-groups versions", action: "list", params: ["group-id": productId])]
        default:
            [Affordance(key: "getVersion", command: "versions", action: "get", params: ["version-id": versionId])]
        }
    }
}

extension PlannedReviewItem: Presentable {
    public static var tableHeaders: [String] { ["Kind", "Version ID", "Product ID", "Name"] }
    public var tableRow: [String] { [kind.rawValue, versionId, productId, name] }
}

/// Works out what to submit with an app version: every in-app purchase and
/// subscription that is `READY_TO_SUBMIT` and has a submittable version, plus
/// the version of each subscription group one of them belongs to.
public struct SubmissionPlanner: Sendable {
    let iapRepo: any InAppPurchaseRepository
    let groupRepo: any SubscriptionGroupRepository
    let subscriptionRepo: any SubscriptionRepository
    let productVersionRepo: any ProductVersionRepository

    public init(
        iapRepo: any InAppPurchaseRepository,
        groupRepo: any SubscriptionGroupRepository,
        subscriptionRepo: any SubscriptionRepository,
        productVersionRepo: any ProductVersionRepository
    ) {
        self.iapRepo = iapRepo
        self.groupRepo = groupRepo
        self.subscriptionRepo = subscriptionRepo
        self.productVersionRepo = productVersionRepo
    }

    public func plan(for version: AppStoreVersion) async throws -> SubmissionPlan {
        var items = [PlannedReviewItem(kind: .appStoreVersion, versionId: version.id,
                                       productId: version.appId, name: version.versionString)]

        let iaps = try await iapRepo.listInAppPurchases(appId: version.appId, limit: 200).data
        for iap in iaps where iap.state == .readyToSubmit {
            if let v = try await productVersionRepo.listInAppPurchaseVersions(iapId: iap.id).first(where: \.isSubmittable) {
                items.append(PlannedReviewItem(kind: .inAppPurchaseVersion, versionId: v.id, productId: iap.id, name: iap.referenceName))
            }
        }

        let groups = try await groupRepo.listSubscriptionGroups(appId: version.appId, limit: 200).data
        for group in groups {
            var subscriptionItems: [PlannedReviewItem] = []
            let subscriptions = try await subscriptionRepo.listSubscriptions(groupId: group.id, limit: 200).data
            for subscription in subscriptions where subscription.state == .readyToSubmit {
                if let v = try await productVersionRepo.listSubscriptionVersions(subscriptionId: subscription.id).first(where: \.isSubmittable) {
                    subscriptionItems.append(PlannedReviewItem(kind: .subscriptionVersion, versionId: v.id,
                                                               productId: subscription.id, name: subscription.name))
                }
            }
            guard !subscriptionItems.isEmpty else { continue }
            if let v = try await productVersionRepo.listSubscriptionGroupVersions(groupId: group.id).first(where: \.isSubmittable) {
                items.append(PlannedReviewItem(kind: .subscriptionGroupVersion, versionId: v.id,
                                               productId: group.id, name: group.referenceName))
            }
            items += subscriptionItems
        }

        return SubmissionPlan(appId: version.appId, platform: version.platform, items: items)
    }
}
