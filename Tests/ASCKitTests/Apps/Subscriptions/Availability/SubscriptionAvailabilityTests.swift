import Testing
@testable import ASCKit

@Suite
struct SubscriptionAvailabilityTests {

    @Test func `availability carries subscription id as parent`() {
        let availability = MockRepositoryFactory.makeSubscriptionAvailability(
            id: "avail-1",
            subscriptionId: "sub-42"
        )
        #expect(availability.subscriptionId == "sub-42")
    }

    @Test func `availability tracks whether available in new territories`() {
        let available = MockRepositoryFactory.makeSubscriptionAvailability(isAvailableInNewTerritories: true)
        let notAvailable = MockRepositoryFactory.makeSubscriptionAvailability(isAvailableInNewTerritories: false)
        #expect(available.isAvailableInNewTerritories == true)
        #expect(notAvailable.isAvailableInNewTerritories == false)
    }

    @Test func `availability includes territories with currency`() {
        let availability = MockRepositoryFactory.makeSubscriptionAvailability(
            territories: [
                Territory(id: "USA", currency: "USD"),
                Territory(id: "GBR", currency: "GBP"),
            ]
        )
        #expect(availability.territories.count == 2)
        #expect(availability.territories[0].id == "USA")
        #expect(availability.territories[1].currency == "GBP")
    }

    @Test func `affordances include get availability command`() {
        let availability = MockRepositoryFactory.makeSubscriptionAvailability(
            id: "avail-1",
            subscriptionId: "sub-42"
        )
        #expect(availability.affordances["getAvailability"] == "asc subscription-availability get --subscription-id sub-42")
    }

    @Test func `affordances include list territories command`() {
        let availability = MockRepositoryFactory.makeSubscriptionAvailability()
        #expect(availability.affordances["listTerritories"] == "asc territories list")
    }
}
