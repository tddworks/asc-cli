@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKInAppPurchaseAvailabilityRepositoryTests {

    @Test func `getAvailability composes attributes call with availableTerritories relationship call`() async throws {
        let stub = StubAPIClient()
        // Call 1: GET /v2/inAppPurchases/{id}/inAppPurchaseAvailability — just attributes.
        stub.willReturn(InAppPurchaseAvailabilityResponse(
            data: InAppPurchaseAvailability(
                type: .inAppPurchaseAvailabilities,
                id: "avail-1",
                attributes: .init(isAvailableInNewTerritories: true)
            ),
            links: .init(this: "")
        ))
        // Call 2: GET /v1/inAppPurchaseAvailabilities/{id}/availableTerritories?limit=200 — full list.
        stub.willReturn(TerritoriesResponse(
            data: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
                Territory(type: .territories, id: "CHN", attributes: .init(currency: "CNY")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(iapId: "iap-99")

        #expect(result?.id == "avail-1")
        #expect(result?.iapId == "iap-99")
        #expect(result?.isAvailableInNewTerritories == true)
        #expect(result?.territories.count == 2)
        #expect(result?.territories[0].id == "USA")
        #expect(result?.territories[0].currency == "USD")
        #expect(result?.territories[1].id == "CHN")
        #expect(result?.territories[1].currency == "CNY")
    }

    @Test func `getAvailability returns more than 10 territories without pagination loss`() async throws {
        // Regression test: the parent endpoint's `include=availableTerritories` truncates the
        // relationship to ~10 entries. Using the dedicated `/availableTerritories` endpoint
        // with limit=200 returns the full list.
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseAvailabilityResponse(
            data: InAppPurchaseAvailability(
                type: .inAppPurchaseAvailabilities,
                id: "avail-big",
                attributes: .init(isAvailableInNewTerritories: false)
            ),
            links: .init(this: "")
        ))
        let manyTerritories: [AppStoreConnect_Swift_SDK.Territory] = (0..<175).map { i in
            AppStoreConnect_Swift_SDK.Territory(type: .territories, id: "T\(i)", attributes: .init(currency: "USD"))
        }
        stub.willReturn(TerritoriesResponse(data: manyTerritories, links: .init(this: "")))

        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(iapId: "iap-big")

        #expect(result?.territories.count == 175)
    }

    @Test func `getAvailability handles empty territory list`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseAvailabilityResponse(
            data: InAppPurchaseAvailability(
                type: .inAppPurchaseAvailabilities,
                id: "avail-2",
                attributes: .init(isAvailableInNewTerritories: false)
            ),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoriesResponse(data: [], links: .init(this: "")))

        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(iapId: "iap-1")

        #expect(result?.territories.isEmpty == true)
        #expect(result?.isAvailableInNewTerritories == false)
    }

    @Test func `getAvailability returns nil when IAP has no availability resource yet`() async throws {
        // Brand-new IAPs 404 on the availability endpoint until the developer creates the
        // resource. Mirrors iOS SDK's `refreshTerritoryStatuses` 404 tolerance — frontends
        // treat nil as "no availability set yet" and seed sensible defaults.
        let stub = StubAPIClient()
        // No `willReturn(_:)` for InAppPurchaseAvailabilityResponse → request throws → nil.
        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try? await repo.getAvailability(iapId: "iap-fresh")
        #expect(result == nil)
    }

    @Test func `createAvailability injects iapId into response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(InAppPurchaseAvailabilityResponse(
            data: InAppPurchaseAvailability(
                type: .inAppPurchaseAvailabilities,
                id: "avail-new",
                attributes: .init(isAvailableInNewTerritories: true),
                relationships: .init(availableTerritories: .init(data: [
                    .init(type: .territories, id: "USA"),
                ]))
            ),
            included: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKInAppPurchaseAvailabilityRepository(client: stub)
        let result = try await repo.createAvailability(
            iapId: "iap-42",
            isAvailableInNewTerritories: true,
            territoryIds: ["USA"]
        )

        #expect(result.id == "avail-new")
        #expect(result.iapId == "iap-42")
        #expect(result.territories[0].id == "USA")
        #expect(result.territories[0].currency == "USD")
    }
}
