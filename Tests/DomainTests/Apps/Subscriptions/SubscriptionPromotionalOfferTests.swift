import Testing
@testable import Domain

@Suite
struct SubscriptionPromotionalOfferTests {

    @Test func `promotional offer carries subscriptionId`() {
        let offer = SubscriptionPromotionalOffer(
            id: "po-1", subscriptionId: "sub-1", name: "Winback",
            offerCode: "winback25", duration: .oneMonth, offerMode: .payAsYouGo, numberOfPeriods: 1
        )
        #expect(offer.subscriptionId == "sub-1")
        #expect(offer.offerCode == "winback25")
    }

    @Test func `affordances include listOffers and delete`() {
        let offer = SubscriptionPromotionalOffer(
            id: "po-1", subscriptionId: "sub-1", name: "Winback",
            offerCode: "winback25", duration: .oneMonth, offerMode: .payAsYouGo, numberOfPeriods: 1
        )
        #expect(offer.affordances["listOffers"] == "asc subscription-promotional-offers list --subscription-id sub-1")
        #expect(offer.affordances["delete"] == "asc subscription-promotional-offers delete --offer-id po-1")
        #expect(offer.affordances["listPrices"] == "asc subscription-promotional-offers prices list --offer-id po-1")
    }

    @Test func `price carries offerId and is encodable with sorted keys`() throws {
        let price = SubscriptionPromotionalOfferPrice(id: "p-1", offerId: "po-1", territory: "USA", subscriptionPricePointId: "spp-1")
        #expect(price.offerId == "po-1")
        #expect(price.affordances["listPrices"] == "asc subscription-promotional-offers prices list --offer-id po-1")
    }
}
