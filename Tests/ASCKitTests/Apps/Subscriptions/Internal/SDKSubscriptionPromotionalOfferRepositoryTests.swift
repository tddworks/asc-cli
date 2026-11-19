@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

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

    @Test func `promotional offer prices include every territory beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> SubscriptionPromotionalOfferPricesResponse {
            SubscriptionPromotionalOfferPricesResponse(
                data: range.map { i in
                    AppStoreConnect_Swift_SDK.SubscriptionPromotionalOfferPrice(
                        type: .subscriptionPromotionalOfferPrices, id: "p-\(i)",
                        relationships: .init(
                            territory: .init(data: .init(type: .territories, id: "T\(i)")),
                            subscriptionPricePoint: .init(data: .init(type: .subscriptionPricePoints, id: "pp-\(i)"))
                        )
                    )
                },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 175, limit: 200, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<100, nextCursor: "page-2"), page(100..<175, nextCursor: nil)])

        let repo = SDKSubscriptionPromotionalOfferRepository(client: stub)
        let result = try await repo.listPrices(offerId: "po-1")

        #expect(result.count == 175)
        #expect(result.last?.territory == "T174")
        #expect(result.last?.subscriptionPricePointId == "pp-174")
    }

    @Test func `promotional offer prices ask Apple for each price's territory and price point`() async throws {
        // Apple only links each price to its territory and price point when asked via `include`.
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPromotionalOfferPricesResponse(data: [], links: .init(this: "")))

        let repo = SDKSubscriptionPromotionalOfferRepository(client: stub)
        _ = try await repo.listPrices(offerId: "po-1")

        let query = Dictionary(uniqueKeysWithValues: (stub.lastQuery ?? []).map { ($0.0, $0.1 ?? "") })
        #expect(query["include"] == "territory,subscriptionPricePoint")
    }
}
