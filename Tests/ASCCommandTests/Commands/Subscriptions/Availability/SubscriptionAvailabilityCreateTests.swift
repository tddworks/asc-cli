import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionAvailabilityCreateTests {

    @Test func `create availability shows created record with territories and currency`() async throws {
        let mockRepo = MockSubscriptionAvailabilityRepository()
        given(mockRepo).createAvailability(subscriptionId: .any, isAvailableInNewTerritories: .any, territoryIds: .any)
            .willReturn(SubscriptionAvailability(
                id: "avail-new",
                subscriptionId: "sub-42",
                isAvailableInNewTerritories: true,
                territories: [
                    Territory(id: "JPN", currency: "JPY"),
                ]
            ))

        let cmd = try SubscriptionAvailabilityCreate.parse([
            "--subscription-id", "sub-42",
            "--available-in-new-territories",
            "--territory", "JPN",
            "--pretty",
        ])
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
              "id" : "avail-new",
              "isAvailableInNewTerritories" : true,
              "subscriptionId" : "sub-42",
              "territories" : [
                {
                  "currency" : "JPY",
                  "id" : "JPN"
                }
              ]
            }
          ]
        }
        """)
    }
}
