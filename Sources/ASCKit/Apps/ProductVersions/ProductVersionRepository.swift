import Mockable

@Mockable
public protocol ProductVersionRepository: Sendable {
    func listInAppPurchaseVersions(iapId: String) async throws -> [ProductVersion]
    func listSubscriptionVersions(subscriptionId: String) async throws -> [ProductVersion]
    func listSubscriptionGroupVersions(groupId: String) async throws -> [ProductVersion]
}
