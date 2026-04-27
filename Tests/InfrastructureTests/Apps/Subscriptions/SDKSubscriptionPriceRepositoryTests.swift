@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionPriceRepositoryTests {

    @Test func `listPricePoints injects subscriptionId into each price point`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPricePointsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-1",
                    attributes: .init(customerPrice: "9.99", proceeds: "6.99", proceedsYear2: "7.49"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                ),
                AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-2",
                    attributes: .init(customerPrice: "8.99", proceeds: "6.29", proceedsYear2: "6.99"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "GBR")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPriceRepository(client: stub)
        let result = try await repo.listPricePoints(subscriptionId: "sub-77", territory: nil)

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.subscriptionId == "sub-77" })
    }

    @Test func `listPricePoints maps customerPrice, proceeds, proceedsYear2 and territory`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPricePointsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-1",
                    attributes: .init(customerPrice: "9.99", proceeds: "6.99", proceedsYear2: "7.49"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                )
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPriceRepository(client: stub)
        let result = try await repo.listPricePoints(subscriptionId: "sub-1", territory: "USA")

        #expect(result[0].customerPrice == "9.99")
        #expect(result[0].proceeds == "6.99")
        #expect(result[0].proceedsYear2 == "7.49")
        #expect(result[0].territory == "USA")
    }

    @Test func `setPrice injects subscriptionId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPriceResponse(
            data: AppStoreConnect_Swift_SDK.SubscriptionPrice(
                type: .subscriptionPrices, id: "price-new"
            ),
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPriceRepository(client: stub)
        let result = try await repo.setPrice(
            subscriptionId: "sub-42", territory: "USA", pricePointId: "spp-1",
            startDate: nil, preserveCurrentPrice: nil
        )

        #expect(result.id == "price-new")
        #expect(result.subscriptionId == "sub-42")
    }

    // MARK: - listEqualizations

    @Test func `listEqualizations returns one entry per equalized territory`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPricePointsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-USA",
                    attributes: .init(customerPrice: "5.99", proceeds: "4.19"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                ),
                AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-JPN",
                    attributes: .init(customerPrice: "980", proceeds: "686"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "JPN")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPriceRepository(client: stub)
        let result = try await repo.listEqualizations(pricePointId: "spp-USA", limit: nil)

        #expect(result.count == 2)
        #expect(result[0].territory == "USA")
        #expect(result[0].customerPrice == "5.99")
        #expect(result[1].territory == "JPN")
        #expect(result[1].customerPrice == "980")
    }

    // MARK: - getPriceSchedule

    @Test func `getPriceSchedule returns nil when no prices exist`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionPricesResponse(data: [], links: .init(this: "")))

        let repo = SDKSubscriptionPriceRepository(client: stub)
        let result = try await repo.getPriceSchedule(subscriptionId: "sub-7")

        #expect(result == nil)
    }

    @Test func `getPriceSchedule populates territoryPrices from manual prices and equalizations`() async throws {
        let stub = StubAPIClient()

        // Step 1: GET /v1/subscriptions/{id}/prices — manual prices.
        stub.willReturn(SubscriptionPricesResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPrice(
                    type: .subscriptionPrices, id: "price-1",
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: "USA")),
                        subscriptionPricePoint: .init(data: .init(type: .subscriptionPricePoints, id: "spp-USA"))
                    )
                )
            ],
            included: [
                .territory(Territory(type: .territories, id: "USA", attributes: .init(currency: "USD"))),
                .subscriptionPricePoint(AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-USA",
                    attributes: .init(customerPrice: "5.99", proceeds: "4.19")
                ))
            ],
            links: .init(this: "")
        ))

        // Step 2: GET /v1/subscriptionPricePoints/{id}/equalizations — JPN auto-equalized.
        stub.willReturn(SubscriptionPricePointsResponse(
            data: [
                AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-USA",
                    attributes: .init(customerPrice: "5.99", proceeds: "4.19"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                ),
                AppStoreConnect_Swift_SDK.SubscriptionPricePoint(
                    type: .subscriptionPricePoints, id: "spp-JPN",
                    attributes: .init(customerPrice: "980", proceeds: "686"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "JPN")))
                ),
            ],
            included: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
                Territory(type: .territories, id: "JPN", attributes: .init(currency: "JPY")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionPriceRepository(client: stub)
        let result = try await repo.getPriceSchedule(subscriptionId: "sub-7")

        let prices: [Domain.TerritoryPrice] = result?.territoryPrices ?? []
        #expect(prices.count == 2)
        var byTerritory: [String: Domain.TerritoryPrice] = [:]
        for entry in prices { byTerritory[entry.territory.id] = entry }
        #expect(byTerritory["USA"]?.customerPrice == "5.99")
        #expect(byTerritory["USA"]?.territory.currency == "USD")
        #expect(byTerritory["JPN"]?.customerPrice == "980")
        #expect(byTerritory["JPN"]?.territory.currency == "JPY")
        #expect(result?.subscriptionId == "sub-7")
    }
}
