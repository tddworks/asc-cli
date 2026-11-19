import Mockable

@Mockable
public protocol SubscriptionPromotionalOfferRepository: Sendable {
    func listPromotionalOffers(subscriptionId: String) async throws -> [SubscriptionPromotionalOffer]
    func createPromotionalOffer(
        subscriptionId: String,
        name: String,
        offerCode: String,
        duration: SubscriptionOfferDuration,
        offerMode: SubscriptionOfferMode,
        numberOfPeriods: Int,
        prices: [PromotionalOfferPriceInput]
    ) async throws -> SubscriptionPromotionalOffer
    func deletePromotionalOffer(offerId: String) async throws
    func listPrices(offerId: String) async throws -> [SubscriptionPromotionalOfferPrice]
}
