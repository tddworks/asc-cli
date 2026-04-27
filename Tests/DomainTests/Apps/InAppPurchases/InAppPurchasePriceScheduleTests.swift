import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchasePriceScheduleTests {

    @Test func `schedule carries baseTerritory and territoryPrices`() {
        let usa = Territory(id: "USA", currency: "USD")
        let jpn = Territory(id: "JPN", currency: "JPY")
        let schedule = InAppPurchasePriceSchedule(
            id: "iap-1",
            iapId: "iap-1",
            baseTerritory: usa,
            territoryPrices: [
                TerritoryPrice(territory: usa, customerPrice: "9.99", proceeds: "6.99"),
                TerritoryPrice(territory: jpn, customerPrice: "1500", proceeds: "1050"),
            ]
        )
        #expect(schedule.baseTerritory == usa)
        #expect(schedule.territoryPrices.count == 2)
        #expect(schedule.territoryPrices[0].customerPrice == "9.99")
    }

    @Test func `schedule basePrice resolves from baseTerritory`() {
        let usa = Territory(id: "USA", currency: "USD")
        let jpn = Territory(id: "JPN", currency: "JPY")
        let schedule = InAppPurchasePriceSchedule(
            id: "iap-1",
            iapId: "iap-1",
            baseTerritory: usa,
            territoryPrices: [
                TerritoryPrice(territory: usa, customerPrice: "9.99", proceeds: "6.99"),
                TerritoryPrice(territory: jpn, customerPrice: "1500", proceeds: "1050"),
            ]
        )
        #expect(schedule.basePrice?.customerPrice == "9.99")
        #expect(schedule.basePrice?.territory.id == "USA")
    }

    @Test func `schedule basePrice nil when baseTerritory missing`() {
        let schedule = InAppPurchasePriceSchedule(id: "iap-1", iapId: "iap-1")
        #expect(schedule.baseTerritory == nil)
        #expect(schedule.territoryPrices.isEmpty)
        #expect(schedule.basePrice == nil)
    }

    @Test func `territory price encodes territory inline`() throws {
        let entry = TerritoryPrice(
            territory: Territory(id: "USA", currency: "USD"),
            customerPrice: "9.99",
            proceeds: "6.99"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(entry)
        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("\"territory\":{"))
        #expect(json.contains("\"customerPrice\":\"9.99\""))
        #expect(json.contains("\"proceeds\":\"6.99\""))
    }
}
