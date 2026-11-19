import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppAvailabilityGetTests {

    @Test func `get app availability shows per-territory status with content reasons`() async throws {
        let mockRepo = MockAppAvailabilityRepository()
        given(mockRepo).getAppAvailability(appId: .any)
            .willReturn(AppAvailability(
                id: "avail-1",
                appId: "app-42",
                isAvailableInNewTerritories: true,
                territories: [
                    AppTerritoryAvailability(
                        id: "ta-1",
                        territoryId: "USA",
                        isAvailable: true,
                        releaseDate: nil,
                        isPreOrderEnabled: false,
                        contentStatuses: [.available]
                    ),
                    AppTerritoryAvailability(
                        id: "ta-2",
                        territoryId: "CHN",
                        isAvailable: false,
                        releaseDate: nil,
                        isPreOrderEnabled: false,
                        contentStatuses: [.cannotSellRestrictedRating]
                    ),
                ]
            ))

        let cmd = try AppAvailabilityGet.parse(["--app-id", "app-42", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getAvailability" : "asc app-availability get --app-id app-42",
                "listTerritories" : "asc territories list"
              },
              "appId" : "app-42",
              "id" : "avail-1",
              "isAvailableInNewTerritories" : true,
              "territories" : [
                {
                  "contentStatuses" : [
                    "AVAILABLE"
                  ],
                  "id" : "ta-1",
                  "isAvailable" : true,
                  "isPreOrderEnabled" : false,
                  "territoryId" : "USA"
                },
                {
                  "contentStatuses" : [
                    "CANNOT_SELL_RESTRICTED_RATING"
                  ],
                  "id" : "ta-2",
                  "isAvailable" : false,
                  "isPreOrderEnabled" : false,
                  "territoryId" : "CHN"
                }
              ]
            }
          ]
        }
        """)
    }

    @Test func `an app with no availability set up shows no data`() async throws {
        let mockRepo = MockAppAvailabilityRepository()
        given(mockRepo).getAppAvailability(appId: .any).willReturn(nil)

        let output = try await AppAvailabilityGet.parse(["--app-id", "app-42", "--pretty"]).execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}
