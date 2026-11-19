import Mockable

@Mockable
public protocol SubscriptionIntroductoryOfferRepository: Sendable {
    func listIntroductoryOffers(subscriptionId: String) async throws -> [SubscriptionIntroductoryOffer]
    func createIntroductoryOffer(
        subscriptionId: String,
        duration: SubscriptionOfferDuration,
        offerMode: SubscriptionOfferMode,
        numberOfPeriods: Int,
        startDate: String?,
        endDate: String?,
        territory: String?,
        pricePointId: String?
    ) async throws -> SubscriptionIntroductoryOffer
    func deleteIntroductoryOffer(offerId: String) async throws
}
