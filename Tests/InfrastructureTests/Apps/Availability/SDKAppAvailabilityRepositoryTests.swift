@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKAppAvailabilityRepositoryTests {

    @Test func `getAppAvailability injects appId and maps territory statuses from dedicated relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppAvailabilityV2Response(
            data: AppAvailabilityV2(
                type: .appAvailabilities,
                id: "avail-1",
                attributes: .init(isAvailableInNewTerritories: true)
            ),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoryAvailabilitiesResponse(
            data: [
                TerritoryAvailability(
                    type: .territoryAvailabilities,
                    id: "ta-1",
                    attributes: .init(
                        isAvailable: true,
                        contentStatuses: [.available]
                    ),
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: "USA"))
                    )
                ),
                TerritoryAvailability(
                    type: .territoryAvailabilities,
                    id: "ta-2",
                    attributes: .init(
                        isAvailable: false,
                        contentStatuses: [.cannotSellRestrictedRating]
                    ),
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: "CHN"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppAvailabilityRepository(client: stub)
        let result = try await repo.getAppAvailability(appId: "app-99")

        #expect(result.id == "avail-1")
        #expect(result.appId == "app-99")
        #expect(result.isAvailableInNewTerritories == true)
        #expect(result.territories.count == 2)
        #expect(result.territories[0].territoryId == "USA")
        #expect(result.territories[0].isAvailable == true)
        #expect(result.territories[1].territoryId == "CHN")
        #expect(result.territories[1].isAvailable == false)
        #expect(result.territories[1].contentStatuses == [.cannotSellRestrictedRating])
    }

    @Test func `getAppAvailability maps pre-order fields from dedicated relationship`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppAvailabilityV2Response(
            data: AppAvailabilityV2(
                type: .appAvailabilities,
                id: "avail-2",
                attributes: .init(isAvailableInNewTerritories: false)
            ),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoryAvailabilitiesResponse(
            data: [
                TerritoryAvailability(
                    type: .territoryAvailabilities,
                    id: "ta-3",
                    attributes: .init(
                        isAvailable: true,
                        releaseDate: "2026-04-01",
                        isPreOrderEnabled: true,
                        contentStatuses: [.availableForPreorder]
                    ),
                    relationships: .init(
                        territory: .init(data: .init(type: .territories, id: "JPN"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppAvailabilityRepository(client: stub)
        let result = try await repo.getAppAvailability(appId: "app-1")

        #expect(result.territories[0].releaseDate == "2026-04-01")
        #expect(result.territories[0].isPreOrderEnabled == true)
    }

    @Test func `getAppAvailability handles empty territories`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppAvailabilityV2Response(
            data: AppAvailabilityV2(
                type: .appAvailabilities,
                id: "avail-3",
                attributes: .init(isAvailableInNewTerritories: true)
            ),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoryAvailabilitiesResponse(data: [], links: .init(this: "")))

        let repo = SDKAppAvailabilityRepository(client: stub)
        let result = try await repo.getAppAvailability(appId: "app-1")

        #expect(result.territories.isEmpty)
    }

    @Test func `getAppAvailability returns more than ten territories - regression against include truncation`() async throws {
        let many = (0..<175).map { i in
            TerritoryAvailability(
                type: .territoryAvailabilities,
                id: "ta-\(i)",
                attributes: .init(isAvailable: true, contentStatuses: [.available]),
                relationships: .init(territory: .init(data: .init(type: .territories, id: "T-\(i)")))
            )
        }
        let stub = StubAPIClient()
        stub.willReturn(AppAvailabilityV2Response(
            data: AppAvailabilityV2(
                type: .appAvailabilities,
                id: "avail-many",
                attributes: .init(isAvailableInNewTerritories: true)
            ),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoryAvailabilitiesResponse(data: many, links: .init(this: "")))

        let repo = SDKAppAvailabilityRepository(client: stub)
        let result = try await repo.getAppAvailability(appId: "app-many")

        #expect(result.territories.count == 175)
    }
}
