import Mockable

@Mockable
public protocol SubscriptionPriceRepository: Sendable {
    func listPricePoints(subscriptionId: String, territory: String?) async throws -> [SubscriptionPricePoint]
    func setPrice(
        subscriptionId: String,
        territory: String,
        pricePointId: String,
        startDate: String?,
        preserveCurrentPrice: Bool?
    ) async throws -> SubscriptionPrice
}
