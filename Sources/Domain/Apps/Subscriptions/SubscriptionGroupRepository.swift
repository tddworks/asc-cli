import Mockable

@Mockable
public protocol SubscriptionGroupRepository: Sendable {
    func listSubscriptionGroups(appId: String, limit: Int?) async throws -> PaginatedResponse<SubscriptionGroup>
    func createSubscriptionGroup(appId: String, referenceName: String) async throws -> SubscriptionGroup
}
