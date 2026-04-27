@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKSubscriptionAvailabilityRepositoryTests {

    @Test func `getAvailability composes attributes call with availableTerritories relationship call`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionAvailabilityResponse(
            data: SubscriptionAvailability(
                type: .subscriptionAvailabilities,
                id: "avail-1",
                attributes: .init(isAvailableInNewTerritories: true)
            ),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoriesResponse(
            data: [
                AppStoreConnect_Swift_SDK.Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
                AppStoreConnect_Swift_SDK.Territory(type: .territories, id: "GBR", attributes: .init(currency: "GBP")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(subscriptionId: "sub-99")

        #expect(result?.id == "avail-1")
        #expect(result?.subscriptionId == "sub-99")
        #expect(result?.territories.count == 2)
        #expect(result?.territories[0].id == "USA")
        #expect(result?.territories[0].currency == "USD")
        #expect(result?.territories[1].id == "GBR")
        #expect(result?.territories[1].currency == "GBP")
    }

    @Test func `getAvailability returns more than 10 territories without pagination loss`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionAvailabilityResponse(
            data: SubscriptionAvailability(
                type: .subscriptionAvailabilities,
                id: "avail-big",
                attributes: .init(isAvailableInNewTerritories: false)
            ),
            links: .init(this: "")
        ))
        let many: [AppStoreConnect_Swift_SDK.Territory] = (0..<175).map { i in
            AppStoreConnect_Swift_SDK.Territory(type: .territories, id: "T\(i)", attributes: .init(currency: "USD"))
        }
        stub.willReturn(TerritoriesResponse(data: many, links: .init(this: "")))

        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(subscriptionId: "sub-big")

        #expect(result?.territories.count == 175)
    }

    @Test func `getAvailability handles empty territory list`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionAvailabilityResponse(
            data: SubscriptionAvailability(
                type: .subscriptionAvailabilities,
                id: "avail-2",
                attributes: .init(isAvailableInNewTerritories: false)
            ),
            links: .init(this: "")
        ))
        stub.willReturn(TerritoriesResponse(data: [], links: .init(this: "")))

        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try await repo.getAvailability(subscriptionId: "sub-1")

        #expect(result?.territories.isEmpty == true)
    }

    @Test func `getAvailability returns nil when subscription has no availability resource yet`() async throws {
        let stub = StubAPIClient()
        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try? await repo.getAvailability(subscriptionId: "sub-fresh")
        #expect(result == nil)
    }

    @Test func `createAvailability injects subscriptionId and maps included territories`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(SubscriptionAvailabilityResponse(
            data: SubscriptionAvailability(
                type: .subscriptionAvailabilities,
                id: "avail-new",
                attributes: .init(isAvailableInNewTerritories: false),
                relationships: .init(availableTerritories: .init(data: [
                    .init(type: .territories, id: "JPN"),
                ]))
            ),
            included: [
                Territory(type: .territories, id: "JPN", attributes: .init(currency: "JPY")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKSubscriptionAvailabilityRepository(client: stub)
        let result = try await repo.createAvailability(
            subscriptionId: "sub-42",
            isAvailableInNewTerritories: false,
            territoryIds: ["JPN"]
        )

        #expect(result.id == "avail-new")
        #expect(result.subscriptionId == "sub-42")
        #expect(result.territories[0].id == "JPN")
        #expect(result.territories[0].currency == "JPY")
    }
}
