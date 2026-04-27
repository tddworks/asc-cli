import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPAvailabilityCreateTests {

    @Test func `create availability shows created record with territories and currency`() async throws {
        let mockRepo = MockInAppPurchaseAvailabilityRepository()
        given(mockRepo).createAvailability(iapId: .any, isAvailableInNewTerritories: .any, territoryIds: .any)
            .willReturn(InAppPurchaseAvailability(
                id: "avail-new",
                iapId: "iap-42",
                isAvailableInNewTerritories: true,
                territories: [
                    Territory(id: "USA", currency: "USD"),
                ]
            ))

        let cmd = try IAPAvailabilityCreate.parse([
            "--iap-id", "iap-42",
            "--available-in-new-territories",
            "--territory", "USA",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createAvailability" : "asc iap-availability create --iap-id iap-42",
                "getAvailability" : "asc iap-availability get --iap-id iap-42",
                "listTerritories" : "asc territories list"
              },
              "iapId" : "iap-42",
              "id" : "avail-new",
              "isAvailableInNewTerritories" : true,
              "territories" : [
                {
                  "currency" : "USD",
                  "id" : "USA"
                }
              ]
            }
          ]
        }
        """)
    }
}
