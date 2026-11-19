import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppPricingCommandsTests {

    @Test func `listed price points show the price and the command to set it`() async throws {
        let mockRepo = MockAppPrices()
        given(mockRepo).listPricePoints(appId: .value("app-1"), territory: .value("USA")).willReturn([
            AppPricePoint(id: "pp-1", appId: "app-1", territory: "USA", customerPrice: "4.99", proceeds: "4.24"),
        ])

        let cmd = try AppsPricePointsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPricePoints" : "asc apps price-points list --app-id app-1 --territory USA",
                "setPrice" : "asc apps prices set --app-id app-1 --base-territory USA --price-point-id pp-1"
              },
              "appId" : "app-1",
              "customerPrice" : "4.99",
              "id" : "pp-1",
              "proceeds" : "4.24",
              "territory" : "USA"
            }
          ]
        }
        """)
    }

    @Test func `price points can be listed for another territory`() async throws {
        let mockRepo = MockAppPrices()
        given(mockRepo).listPricePoints(appId: .any, territory: .any).willReturn([])

        _ = try await AppsPricePointsList.parse(["--app-id", "app-1", "--territory", "JPN"]).execute(repo: mockRepo)

        verify(mockRepo).listPricePoints(appId: .value("app-1"), territory: .value("JPN")).called(1)
    }

    @Test func `setting the price shows the new schedule`() async throws {
        let mockRepo = MockAppPrices()
        given(mockRepo).setPriceSchedule(appId: .value("app-1"), baseTerritory: .value("USA"), pricePointId: .value("pp-1"))
            .willReturn(AppPriceSchedule(id: "sched-1", appId: "app-1", baseTerritory: "USA"))

        let cmd = try AppsPricesSet.parse(["--app-id", "app-1", "--base-territory", "USA", "--price-point-id", "pp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPricePoints" : "asc apps price-points list --app-id app-1 --territory USA"
              },
              "appId" : "app-1",
              "baseTerritory" : "USA",
              "id" : "sched-1"
            }
          ]
        }
        """)
    }
}
