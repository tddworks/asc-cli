import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPAvailabilityGetTests {

    @Test func `get availability shows iapId, territories with currency and affordances`() async throws {
        let mockRepo = MockInAppPurchaseAvailabilityRepository()
        given(mockRepo).getAvailability(iapId: .any)
            .willReturn(InAppPurchaseAvailability(
                id: "avail-1",
                iapId: "iap-42",
                isAvailableInNewTerritories: true,
                territories: [
                    Territory(id: "USA", currency: "USD"),
                    Territory(id: "CHN", currency: "CNY"),
                ]
            ))

        let cmd = try IAPAvailabilityGet.parse(["--iap-id", "iap-42", "--pretty"])
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
              "id" : "avail-1",
              "isAvailableInNewTerritories" : true,
              "territories" : [
                {
                  "currency" : "USD",
                  "id" : "USA"
                },
                {
                  "currency" : "CNY",
                  "id" : "CHN"
                }
              ]
            }
          ]
        }
        """)
    }
}
