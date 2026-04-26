import Mockable

@Mockable
public protocol WinBackOfferRepository: Sendable {
    func listWinBackOffers(subscriptionId: String) async throws -> [WinBackOffer]
    func createWinBackOffer(
        subscriptionId: String,
        referenceName: String,
        offerId: String,
        duration: SubscriptionOfferDuration,
        offerMode: SubscriptionOfferMode,
        periodCount: Int,
        paidSubscriptionDurationInMonths: Int,
        timeSinceLastSubscribedMin: Int,
        timeSinceLastSubscribedMax: Int,
        waitBetweenOffersInMonths: Int?,
        startDate: String,
        endDate: String?,
        priority: WinBackOfferPriority,
        promotionIntent: WinBackOfferPromotionIntent?,
        prices: [WinBackOfferPriceInput]
    ) async throws -> WinBackOffer
    func updateWinBackOffer(
        offerId: String,
        startDate: String?,
        endDate: String?,
        priority: WinBackOfferPriority?,
        promotionIntent: WinBackOfferPromotionIntent?,
        paidSubscriptionDurationInMonths: Int?,
        timeSinceLastSubscribedMin: Int?,
        timeSinceLastSubscribedMax: Int?,
        waitBetweenOffersInMonths: Int?
    ) async throws -> WinBackOffer
    func deleteWinBackOffer(offerId: String) async throws
    func listPrices(offerId: String) async throws -> [WinBackOfferPrice]
}
