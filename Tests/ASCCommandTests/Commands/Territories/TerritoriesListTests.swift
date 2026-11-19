import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct TerritoriesListTests {

    @Test func `listed territories show id, currency and affordances`() async throws {
        let mockRepo = MockTerritoryRepository()
        given(mockRepo).listTerritories()
            .willReturn([
                Territory(id: "USA", currency: "USD"),
                Territory(id: "JPN", currency: "JPY"),
            ])

        let cmd = try TerritoriesList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listTerritories" : "asc territories list"
              },
              "currency" : "USD",
              "id" : "USA"
            },
            {
              "affordances" : {
                "listTerritories" : "asc territories list"
              },
              "currency" : "JPY",
              "id" : "JPN"
            }
          ]
        }
        """)
    }
}
