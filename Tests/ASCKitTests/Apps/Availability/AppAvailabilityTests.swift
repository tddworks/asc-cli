import Testing
@testable import ASCKit

@Suite
struct AppAvailabilityTests {

    @Test func `app availability carries app id as parent`() {
        let availability = MockRepositoryFactory.makeAppAvailability(
            id: "avail-1",
            appId: "app-42"
        )
        #expect(availability.appId == "app-42")
    }

    @Test func `app availability includes per-territory statuses`() {
        let availability = MockRepositoryFactory.makeAppAvailability(
            territories: [
                MockRepositoryFactory.makeAppTerritoryAvailability(territoryId: "USA", isAvailable: true),
                MockRepositoryFactory.makeAppTerritoryAvailability(territoryId: "CHN", isAvailable: false),
            ]
        )
        #expect(availability.territories.count == 2)
        #expect(availability.territories[0].isAvailable == true)
        #expect(availability.territories[1].isAvailable == false)
    }

    @Test func `affordances include get app availability`() {
        let availability = MockRepositoryFactory.makeAppAvailability(appId: "app-42")
        #expect(availability.affordances["getAvailability"] == "asc app-availability get --app-id app-42")
    }

    @Test func `affordances include list territories`() {
        let availability = MockRepositoryFactory.makeAppAvailability()
        #expect(availability.affordances["listTerritories"] == "asc territories list")
    }

    @Test func `app availability links to reading it over REST`() {
        let availability = MockRepositoryFactory.makeAppAvailability(appId: "app-42")
        #expect(availability.apiLinks["getAvailability"]?.href == "/api/v1/apps/app-42/availability")
        #expect(availability.apiLinks["getAvailability"]?.method == "GET")
    }

    @Test func `the availability table row shows how many territories are available`() {
        let availability = AppAvailability(id: "avail-1", appId: "app-1", isAvailableInNewTerritories: true, territories: [
            AppTerritoryAvailability(id: "ta-1", territoryId: "USA", isAvailable: true, releaseDate: nil,
                                     isPreOrderEnabled: false, contentStatuses: []),
            AppTerritoryAvailability(id: "ta-2", territoryId: "CHN", isAvailable: false, releaseDate: nil,
                                     isPreOrderEnabled: false, contentStatuses: []),
        ])
        #expect(AppAvailability.tableHeaders == ["ID", "App ID", "Available in New Territories", "Territories"])
        #expect(availability.tableRow == ["avail-1", "app-1", "true", "1/2 available"])
    }
}
