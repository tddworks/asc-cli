@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

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

        #expect(result?.id == "avail-1")
        #expect(result?.appId == "app-99")
        #expect(result?.isAvailableInNewTerritories == true)
        #expect(result?.territories.count == 2)
        #expect(result?.territories[0].territoryId == "USA")
        #expect(result?.territories[0].isAvailable == true)
        #expect(result?.territories[1].territoryId == "CHN")
        #expect(result?.territories[1].isAvailable == false)
        #expect(result?.territories[1].contentStatuses == [.cannotSellRestrictedRating])
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

        #expect(result?.territories[0].releaseDate == "2026-04-01")
        #expect(result?.territories[0].isPreOrderEnabled == true)
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

        #expect(result?.territories.isEmpty == true)
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

        #expect(result?.territories.count == 175)
    }

    // MARK: - Not set up / create

    @Test func `an app with no availability set up reads as none`() async throws {
        let stub = StubAPIClient()
        stub.errorToThrow = APIProvider.Error.requestFailure(404, ErrorResponse(errors: [
            ResponseError(status: "404", code: "NOT_FOUND", title: "The specified resource does not exist",
                          detail: "There is no resource of type 'appAvailabilities' with id 'app-1'"),
        ]), nil)

        let repo = SDKAppAvailabilityRepository(client: stub)
        let result = try await repo.getAppAvailability(appId: "app-1")

        #expect(result == nil)
    }

    @Test func `creating availability makes every given territory available in one request`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppAvailabilityV2Response(
            data: AppAvailabilityV2(type: .appAvailabilities, id: "avail-1", attributes: .init(isAvailableInNewTerritories: true)),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoryAvailabilitiesResponse(
            data: [
                TerritoryAvailability(type: .territoryAvailabilities, id: "ta-1", attributes: .init(isAvailable: true),
                                      relationships: .init(territory: .init(data: .init(type: .territories, id: "USA")))),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppAvailabilityRepository(client: stub)
        let result = try await repo.createAppAvailability(
            appId: "app-1", isAvailableInNewTerritories: true, territoryIds: ["USA", "JPN"]
        )

        let post = stub.requests.first { $0.method == "POST" }
        #expect(post?.path == "/v2/appAvailabilities")
        #expect(post?.body == #"{"data":{"attributes":{"availableInNewTerritories":true},"relationships":{"app":{"data":{"id":"app-1","type":"apps"}},"territoryAvailabilities":{"data":[{"id":"${ta-USA}","type":"territoryAvailabilities"},{"id":"${ta-JPN}","type":"territoryAvailabilities"}]}},"type":"appAvailabilities"},"included":[{"attributes":{"available":true},"id":"${ta-USA}","relationships":{"territory":{"data":{"id":"USA","type":"territories"}}},"type":"territoryAvailabilities"},{"attributes":{"available":true},"id":"${ta-JPN}","relationships":{"territory":{"data":{"id":"JPN","type":"territories"}}},"type":"territoryAvailabilities"}]}"#)
        #expect(result.appId == "app-1")
        #expect(result.isAvailableInNewTerritories)
        #expect(result.territories.map(\.territoryId) == ["USA"])
    }
}
