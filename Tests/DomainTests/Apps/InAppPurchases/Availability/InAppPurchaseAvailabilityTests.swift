import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchaseAvailabilityTests {

    @Test func `availability carries iap id as parent`() {
        let availability = MockRepositoryFactory.makeInAppPurchaseAvailability(
            id: "avail-1",
            iapId: "iap-42"
        )
        #expect(availability.iapId == "iap-42")
    }

    @Test func `availability tracks whether available in new territories`() {
        let available = MockRepositoryFactory.makeInAppPurchaseAvailability(isAvailableInNewTerritories: true)
        let notAvailable = MockRepositoryFactory.makeInAppPurchaseAvailability(isAvailableInNewTerritories: false)
        #expect(available.isAvailableInNewTerritories == true)
        #expect(notAvailable.isAvailableInNewTerritories == false)
    }

    @Test func `availability includes territories with currency`() {
        let availability = MockRepositoryFactory.makeInAppPurchaseAvailability(
            territories: [
                Territory(id: "USA", currency: "USD"),
                Territory(id: "CHN", currency: "CNY"),
            ]
        )
        #expect(availability.territories.count == 2)
        #expect(availability.territories[0].id == "USA")
        #expect(availability.territories[0].currency == "USD")
        #expect(availability.territories[1].id == "CHN")
        #expect(availability.territories[1].currency == "CNY")
    }

    @Test func `affordances include get availability command`() {
        let availability = MockRepositoryFactory.makeInAppPurchaseAvailability(
            id: "avail-1",
            iapId: "iap-42"
        )
        #expect(availability.affordances["getAvailability"] == "asc iap-availability get --iap-id iap-42")
    }

    @Test func `affordances include create availability command`() {
        let availability = MockRepositoryFactory.makeInAppPurchaseAvailability(
            id: "avail-1",
            iapId: "iap-42"
        )
        #expect(availability.affordances["createAvailability"] == "asc iap-availability create --iap-id iap-42")
    }

    @Test func `affordances include list territories command`() {
        let availability = MockRepositoryFactory.makeInAppPurchaseAvailability()
        #expect(availability.affordances["listTerritories"] == "asc territories list")
    }
}
