@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionPromotionalOfferRepositoryTests {

    @Test func `listPromotionalOffers injects subscriptionId into each offer`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPromotionalOffersResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPromotionalOffer(
                    type: .subscriptionPromotionalOffers, id: "po-1",
                    attributes: .init(duration: .oneMonth, name: "Winback", numberOfPeriods: 1,
                                      offerCode: "wb25", offerMode: .payAsYouGo)
                ),
                AppStoreConnect_Swift_SDK.SubscriptionPromotionalOffer(
                    type: .subscriptionPromotionalOffers, id: "po-2",
                    attributes: .init(duration: .threeMonths, name: "Loyalty", numberOfPeriods: 3,
                                      offerCode: "loy30", offerMode: .payUpFront)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPromotionalOfferRepository(client: stub)
        let result = try await repo.listPromotionalOffers(subscriptionId: "sub-77")

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.subscriptionId == "sub-77" })
    }

    @Test func `listPromotionalOffers maps duration, mode, offerCode and numberOfPeriods`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPromotionalOffersResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPromotionalOffer(
                    type: .subscriptionPromotionalOffers, id: "po-1",
                    attributes: .init(duration: .threeMonths, name: "Loyalty", numberOfPeriods: 3,
                                      offerCode: "loy30", offerMode: .payUpFront)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPromotionalOfferRepository(client: stub)
        let result = try await repo.listPromotionalOffers(subscriptionId: "sub-1")

        #expect(result[0].duration == .threeMonths)
        #expect(result[0].offerMode == .payUpFront)
        #expect(result[0].offerCode == "loy30")
        #expect(result[0].numberOfPeriods == 3)
    }

    @Test func `createPromotionalOffer injects subscriptionId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPromotionalOfferResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionPromotionalOffer(
                type: .subscriptionPromotionalOffers, id: "po-new",
                attributes: .init(duration: .oneMonth, name: "Winback", numberOfPeriods: 1,
                                  offerCode: "wb25", offerMode: .payAsYouGo)
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPromotionalOfferRepository(client: stub)
        let result = try await repo.createPromotionalOffer(
            subscriptionId: "sub-42",
            name: "Winback", offerCode: "wb25",
            duration: .oneMonth, offerMode: .payAsYouGo, numberOfPeriods: 1,
            prices: [PromotionalOfferPriceInput(territory: "USA", pricePointId: "spp-1")]
        )

        #expect(result.id == "po-new")
        #expect(result.subscriptionId == "sub-42")
    }

    @Test func `deletePromotionalOffer performs void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionPromotionalOfferRepository(client: stub)
        try await repo.deletePromotionalOffer(offerId: "po-1")
        #expect(stub.voidRequestCalled == true)
    }

    @Test func `listPrices injects offerId and maps territory + pricePoint`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPromotionalOfferPricesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPromotionalOfferPrice(
                    type: .subscriptionPromotionalOfferPrices, id: "p-1",
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: "USA")),
                        subscriptionPricePoint: .init(data: .init(type: .subscriptionPricePoints, id: "spp-9"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPromotionalOfferRepository(client: stub)
        let result = try await repo.listPrices(offerId: "po-77")

        #expect(result.count == 1)
        #expect(result[0].offerId == "po-77")
        #expect(result[0].territory == "USA")
        #expect(result[0].subscriptionPricePointId == "spp-9")
    }
}
