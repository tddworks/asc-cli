import ArgumentParser
import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppAvailabilityCreateTests {

    private let created = AppAvailability(id: "avail-1", appId: "app-1", isAvailableInNewTerritories: true, territories: [
        AppTerritoryAvailability(id: "ta-1", territoryId: "USA", isAvailable: true, releaseDate: nil,
                                 isPreOrderEnabled: false, contentStatuses: []),
    ])

    @Test func `creating availability for chosen territories shows the result`() async throws {
        let repo = MockAppAvailabilities()
        given(repo).createAppAvailability(appId: .any, isAvailableInNewTerritories: .any, territoryIds: .any).willReturn(created)

        let cmd = try AppAvailabilityCreate.parse(["--app-id", "app-1", "--territory", "USA", "--territory", "JPN",
                                                   "--available-in-new-territories", "--pretty"])
        let output = try await cmd.execute(repo: repo, territoryRepo: MockTerritories())

        verify(repo).createAppAvailability(appId: .value("app-1"), isAvailableInNewTerritories: .value(true),
                                           territoryIds: .value(["USA", "JPN"])).called(1)
        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getAvailability" : "asc app-availability get --app-id app-1",
                "listTerritories" : "asc territories list"
              },
              "appId" : "app-1",
              "id" : "avail-1",
              "isAvailableInNewTerritories" : true,
              "territories" : [
                {
                  "contentStatuses" : [

                  ],
                  "id" : "ta-1",
                  "isAvailable" : true,
                  "isPreOrderEnabled" : false,
                  "territoryId" : "USA"
                }
              ]
            }
          ]
        }
        """)
    }

    @Test func `all territories makes the app available everywhere Apple sells`() async throws {
        let repo = MockAppAvailabilities()
        given(repo).createAppAvailability(appId: .any, isAvailableInNewTerritories: .any, territoryIds: .any).willReturn(created)
        let territories = MockTerritories()
        given(territories).listTerritories().willReturn([
            Territory(id: "USA", currency: "USD"), Territory(id: "JPN", currency: "JPY"), Territory(id: "FRA", currency: "EUR"),
        ])

        let cmd = try AppAvailabilityCreate.parse(["--app-id", "app-1", "--all-territories"])
        _ = try await cmd.execute(repo: repo, territoryRepo: territories)

        verify(repo).createAppAvailability(appId: .value("app-1"), isAvailableInNewTerritories: .value(false),
                                           territoryIds: .value(["USA", "JPN", "FRA"])).called(1)
    }

    @Test func `creating availability needs either territories or all territories`() async throws {
        let neither = try AppAvailabilityCreate.parse(["--app-id", "app-1"])
        await #expect(throws: ValidationError.self) {
            _ = try await neither.execute(repo: MockAppAvailabilities(), territoryRepo: MockTerritories())
        }
        let both = try AppAvailabilityCreate.parse(["--app-id", "app-1", "--territory", "USA", "--all-territories"])
        await #expect(throws: ValidationError.self) {
            _ = try await both.execute(repo: MockAppAvailabilities(), territoryRepo: MockTerritories())
        }
    }
}
