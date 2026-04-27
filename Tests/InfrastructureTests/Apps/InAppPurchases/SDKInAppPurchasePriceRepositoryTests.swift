@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchasePriceRepositoryTests {

    // MARK: - listPricePoints

    @Test func `listPricePoints injects iapId into each price point`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasePricePointsResponse(
            data: [
                InAppPurchasePricePoint(type: .inAppPurchasePricePoints, id: "pp-1"),
                InAppPurchasePricePoint(type: .inAppPurchasePricePoints, id: "pp-2"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.listPricePoints(iapId: "iap-99", territory: nil, limit: nil, cursor: nil)

        #expect(result.data.count == 2)
        #expect(result.data.allSatisfy { $0.iapId == "iap-99" })
    }

    @Test func `listPricePoints maps territory from relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasePricePointsResponse(
            data: [
                InAppPurchasePricePoint(
                    type: .inAppPurchasePricePoints,
                    id: "pp-1",
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.listPricePoints(iapId: "iap-1", territory: nil, limit: nil, cursor: nil)

        #expect(result.data[0].territory == "USA")
    }

    @Test func `listPricePoints maps customerPrice and proceeds from attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasePricePointsResponse(
            data: [
                InAppPurchasePricePoint(
                    type: .inAppPurchasePricePoints,
                    id: "pp-1",
                    attributes: .init(customerPrice: "0.99", proceeds: "0.70")
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.listPricePoints(iapId: "iap-1", territory: nil, limit: nil, cursor: nil)

        #expect(result.data[0].customerPrice == "0.99")
        #expect(result.data[0].proceeds == "0.70")
    }

    @Test func `listPricePoints surfaces nextCursor and totalCount from response meta`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasePricePointsResponse(
            data: [InAppPurchasePricePoint(type: .inAppPurchasePricePoints, id: "pp-1")],
            links: .init(this: ""),
            meta: PagingInformation(paging: .init(total: 100, limit: 50, nextCursor: "next-page-token"))
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.listPricePoints(iapId: "iap-1", territory: nil, limit: 50, cursor: nil)

        #expect(result.nextCursor == "next-page-token")
        #expect(result.totalCount == 100)
    }

    // MARK: - setPriceSchedule

    @Test func `setPriceSchedule injects iapId into result`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasePriceScheduleResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchasePriceSchedule(type: .inAppPurchasePriceSchedules, id: "sched-1"),
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.setPriceSchedule(iapId: "iap-abc", baseTerritory: "USA", pricePointId: "pp-1")

        #expect(result.id == "sched-1")
        #expect(result.iapId == "iap-abc")
    }

    // ASC requires the inline-created manual price to (a) use the `${...}` placeholder
    // convention so the relationship correlation works, and (b) carry an `inAppPurchaseV2`
    // back-reference so the server knows which IAP the price belongs to. Omitting either
    // produces a 4xx that surfaces as a 500 to web clients.
    @Test func `price schedule request mirrors iOS app shape`() throws {
        let request = SDKInAppPurchasePriceRepository.makePriceScheduleCreateRequest(
            iapId: "iap-abc",
            baseTerritory: "CHN",
            pricePointId: "pp-1"
        )

        // Top-level relationships
        #expect(request.data.relationships.inAppPurchase.data.id == "iap-abc")
        #expect(request.data.relationships.baseTerritory.data.id == "CHN")
        let manualPriceRefs = request.data.relationships.manualPrices.data
        #expect(manualPriceRefs.count == 1)
        let tempId = manualPriceRefs[0].id
        #expect(tempId == "${local-manual-price-1}")

        // Inline-created manual price must back-reference the IAP and the price point.
        guard
            let included = request.included?.first,
            case .inAppPurchasePriceInlineCreate(let inline) = included
        else {
            Issue.record("expected inAppPurchasePriceInlineCreate in included")
            return
        }
        #expect(inline.id == tempId)
        let v2DataId = inline.relationships?.inAppPurchaseV2?.data?.id
        let ppDataId = inline.relationships?.inAppPurchasePricePoint?.data?.id
        #expect(v2DataId == "iap-abc")
        #expect(ppDataId == "pp-1")
    }

    // MARK: - listEqualizations

    @Test func `listEqualizations returns one entry per equalized territory`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasePricePointsResponse(
            data: [
                InAppPurchasePricePoint(
                    type: .inAppPurchasePricePoints,
                    id: "pp-USA",
                    attributes: .init(customerPrice: "9.99", proceeds: "6.99"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                ),
                InAppPurchasePricePoint(
                    type: .inAppPurchasePricePoints,
                    id: "pp-JPN",
                    attributes: .init(customerPrice: "1500", proceeds: "1050"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "JPN")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.listEqualizations(pricePointId: "pp-USA", limit: nil)

        #expect(result.count == 2)
        #expect(result[0].territory == "USA")
        #expect(result[0].customerPrice == "9.99")
        #expect(result[1].territory == "JPN")
        #expect(result[1].customerPrice == "1500")
    }

    @Test func `listEqualizations injects iapId as nil since the call is by price point not iap`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchasePricePointsResponse(
            data: [
                InAppPurchasePricePoint(type: .inAppPurchasePricePoints, id: "pp-USA"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.listEqualizations(pricePointId: "pp-USA", limit: nil)

        // The equalizations endpoint is keyed by price point, not by IAP, so iapId is empty.
        #expect(result[0].iapId == "")
    }

    // MARK: - getPriceSchedule with enriched territoryPrices

    @Test func `getPriceSchedule populates baseTerritory from include`() async throws {
        let stub = StubAPIClient()

        // Step 1: schedule with baseTerritory included.
        stub.willReturn(InAppPurchasePriceScheduleResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchasePriceSchedule(
                type: .inAppPurchasePriceSchedules,
                id: "iap-7",
                relationships: .init(baseTerritory: .init(data: .init(type: .territories, id: "USA")))
            ),
            included: [
                .territory(Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")))
            ],
            links: .init(this: "")
        ))

        // Step 2: manualPrices empty (we only test base territory wiring here).
        stub.willReturn(InAppPurchasePricesResponse(data: [], links: .init(this: "")))

        // Step 3: equalizations empty.
        stub.willReturn(InAppPurchasePricePointsResponse(data: [], links: .init(this: "")))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.getPriceSchedule(iapId: "iap-7")

        #expect(result?.baseTerritory?.id == "USA")
        #expect(result?.baseTerritory?.currency == "USD")
    }

    @Test func `getPriceSchedule includes equalized territories in territoryPrices`() async throws {
        let stub = StubAPIClient()

        // Step 1: schedule with base territory USA.
        stub.willReturn(InAppPurchasePriceScheduleResponse(
            data: AppStoreConnect_Swift_SDK.InAppPurchasePriceSchedule(
                type: .inAppPurchasePriceSchedules,
                id: "iap-7",
                relationships: .init(baseTerritory: .init(data: .init(type: .territories, id: "USA")))
            ),
            included: [
                .territory(Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")))
            ],
            links: .init(this: "")
        ))

        // Step 2: manualPrices — one entry pointing at price point pp-USA.
        stub.willReturn(InAppPurchasePricesResponse(
            data: [
                AppStoreConnect_Swift_SDK.InAppPurchasePrice(
                    type: .inAppPurchasePrices,
                    id: "price-1",
                    relationships: .init(
                        inAppPurchasePricePoint: .init(data: .init(type: .inAppPurchasePricePoints, id: "pp-USA")),
                        territory: .init(data: .init(type: .territories, id: "USA"))
                    )
                )
            ],
            included: [
                .territory(Territory(type: .territories, id: "USA", attributes: .init(currency: "USD"))),
                .inAppPurchasePricePoint(InAppPurchasePricePoint(
                    type: .inAppPurchasePricePoints,
                    id: "pp-USA",
                    attributes: .init(customerPrice: "9.99", proceeds: "6.99")
                ))
            ],
            links: .init(this: "")
        ))

        // Step 3: equalizations — JPN auto-equalized from the USA base price.
        stub.willReturn(InAppPurchasePricePointsResponse(
            data: [
                InAppPurchasePricePoint(
                    type: .inAppPurchasePricePoints,
                    id: "pp-USA",
                    attributes: .init(customerPrice: "9.99", proceeds: "6.99"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))
                ),
                InAppPurchasePricePoint(
                    type: .inAppPurchasePricePoints,
                    id: "pp-JPN",
                    attributes: .init(customerPrice: "1500", proceeds: "1050"),
                    relationships: .init(territory: .init(data: .init(type: .territories, id: "JPN")))
                ),
            ],
            included: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
                Territory(type: .territories, id: "JPN", attributes: .init(currency: "JPY")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchasePriceRepository(client: stub)
        let result = try await repo.getPriceSchedule(iapId: "iap-7")

        // territoryPrices contains USA (manual + equalized) deduped + JPN (equalized).
        let prices: [Domain.TerritoryPrice] = result?.territoryPrices ?? []
        #expect(prices.count == 2)
        var byTerritory: [String: Domain.TerritoryPrice] = [:]
        for entry in prices { byTerritory[entry.territory.id] = entry }
        #expect(byTerritory["USA"]?.customerPrice == "9.99")
        #expect(byTerritory["USA"]?.territory.currency == "USD")
        #expect(byTerritory["JPN"]?.customerPrice == "1500")
        #expect(byTerritory["JPN"]?.territory.currency == "JPY")
    }
}
