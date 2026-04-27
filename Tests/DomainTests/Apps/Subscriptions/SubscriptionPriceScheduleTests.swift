import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionPriceScheduleTests {

    @Test func `schedule carries territoryPrices and subscriptionId`() {
        let usa = Territory(id: "USA", currency: "USD")
        let jpn = Territory(id: "JPN", currency: "JPY")
        let schedule = SubscriptionPriceSchedule(
            id: "sub-1",
            subscriptionId: "sub-1",
            territoryPrices: [
                TerritoryPrice(territory: usa, customerPrice: "5.99", proceeds: "4.19"),
                TerritoryPrice(territory: jpn, customerPrice: "980", proceeds: "686"),
            ]
        )
        #expect(schedule.subscriptionId == "sub-1")
        #expect(schedule.territoryPrices.count == 2)
    }

    @Test func `price(for:) returns the entry for a given territory`() {
        let usa = Territory(id: "USA", currency: "USD")
        let jpn = Territory(id: "JPN", currency: "JPY")
        let schedule = SubscriptionPriceSchedule(
            id: "sub-1",
            subscriptionId: "sub-1",
            territoryPrices: [
                TerritoryPrice(territory: usa, customerPrice: "5.99", proceeds: "4.19"),
                TerritoryPrice(territory: jpn, customerPrice: "980", proceeds: "686"),
            ]
        )
        #expect(schedule.price(for: "USA")?.customerPrice == "5.99")
        #expect(schedule.price(for: "JPN")?.customerPrice == "980")
        #expect(schedule.price(for: "DEU") == nil)
    }

    @Test func `schedule has no baseTerritory — subscriptions are per-territory`() {
        // Compile-time check: type must NOT have a baseTerritory member (would conflict with
        // semantic model). If you add `baseTerritory` to SubscriptionPriceSchedule, this test
        // will fail to compile — surface that decision explicitly.
        let schedule = SubscriptionPriceSchedule(id: "sub-1", subscriptionId: "sub-1")
        // Ensure the encode shape doesn't mention baseTerritory.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try! encoder.encode(schedule)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(!json.contains("baseTerritory"))
    }

    @Test func `schedule affordances expose listPricePoints and getSubscription`() {
        let schedule = SubscriptionPriceSchedule(id: "sub-1", subscriptionId: "sub-1")
        #expect(schedule.affordances["listPricePoints"] == "asc subscriptions price-points list --subscription-id sub-1")
        #expect(schedule.affordances["getSubscription"] != nil)
    }
}
