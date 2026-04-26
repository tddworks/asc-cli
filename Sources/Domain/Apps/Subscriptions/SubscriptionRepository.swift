import Mockable

@Mockable
public protocol SubscriptionRepository: Sendable {
    func listSubscriptions(groupId: String, limit: Int?) async throws -> PaginatedResponse<Subscription>
    func createSubscription(
        groupId: String,
        name: String,
        productId: String,
        period: SubscriptionPeriod,
        isFamilySharable: Bool,
        groupLevel: Int?
    ) async throws -> Subscription
    func updateSubscription(
        subscriptionId: String,
        name: String?,
        isFamilySharable: Bool?,
        groupLevel: Int?,
        reviewNote: String?
    ) async throws -> Subscription
    func deleteSubscription(subscriptionId: String) async throws
}
