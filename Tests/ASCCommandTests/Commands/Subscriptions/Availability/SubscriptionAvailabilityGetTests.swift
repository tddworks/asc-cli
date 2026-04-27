import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionAvailabilityGetTests {

    @Test func `get availability shows subscriptionId, territories with currency and affordances`() async throws {
        let mockRepo = MockSubscriptionAvailabilityRepository()
        given(mockRepo).getAvailability(subscriptionId: .any)
            .willReturn(SubscriptionAvailability(
                id: "avail-1",
                subscriptionId: "sub-42",
                isAvailableInNewTerritories: false,
                territories: [
                    Territory(id: "USA", currency: "USD"),
                    Territory(id: "GBR", currency: "GBP"),
                ]
            ))

        let cmd = try SubscriptionAvailabilityGet.parse(["--subscription-id", "sub-42", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createAvailability" : "asc subscription-availability create --subscription-id sub-42",
                "getAvailability" : "asc subscription-availability get --subscription-id sub-42",
                "listTerritories" : "asc territories list"
              },
              "id" : "avail-1",
              "isAvailableInNewTerritories" : false,
              "subscriptionId" : "sub-42",
              "territories" : [
                {
                  "currency" : "USD",
                  "id" : "USA"
                },
                {
                  "currency" : "GBP",
                  "id" : "GBR"
                }
              ]
            }
          ]
        }
        """)
    }
}
