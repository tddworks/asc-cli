@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKTerritoryRepositoryTests {

    @Test func `listTerritories maps id and currency from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(TerritoriesResponse(
            data: [
                Territory(type: .territories, id: "USA", attributes: .init(currency: "USD")),
                Territory(type: .territories, id: "JPN", attributes: .init(currency: "JPY")),
                Territory(type: .territories, id: "GBR", attributes: .init(currency: "GBP")),
            ],
            links: .init(this: "")
        ))

        let repo = SDKTerritoryRepository(client: stub)
        let result = try await repo.listTerritories()

        #expect(result.count == 3)
        #expect(result[0].id == "USA")
        #expect(result[0].currency == "USD")
        #expect(result[1].id == "JPN")
        #expect(result[1].currency == "JPY")
    }

    @Test func `listTerritories maps nil currency when attributes missing`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(TerritoriesResponse(
            data: [
                Territory(type: .territories, id: "USA"),
            ],
            links: .init(this: "")
        ))

        let repo = SDKTerritoryRepository(client: stub)
        let result = try await repo.listTerritories()

        #expect(result[0].id == "USA")
        #expect(result[0].currency == nil)
    }
}
