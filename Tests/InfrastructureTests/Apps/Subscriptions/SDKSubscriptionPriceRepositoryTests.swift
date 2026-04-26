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
}
