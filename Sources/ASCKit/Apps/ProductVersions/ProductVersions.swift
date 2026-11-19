import Mockable

@Mockable
public protocol ProductVersions: Sendable {
    func listInAppPurchaseVersions(iapId: String) async throws -> [ProductVersion]
    func listSubscriptionVersions(subscriptionId: String) async throws -> [ProductVersion]
    func listSubscriptionGroupVersions(groupId: String) async throws -> [ProductVersion]
}
