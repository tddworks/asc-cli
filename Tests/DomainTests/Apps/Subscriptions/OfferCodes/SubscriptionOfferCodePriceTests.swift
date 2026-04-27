import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionOfferCodePriceTests {

    @Test func `price carries offerCodeId`() {
        let p = SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                           territory: "USA", subscriptionPricePointId: "spp-7")
        #expect(p.offerCodeId == "oc-1")
        #expect(p.id == "p-1")
        #expect(p.territory == "USA")
        #expect(p.subscriptionPricePointId == "spp-7")
    }

    @Test func `affordances include listPrices`() {
        let p = SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                           territory: "USA", subscriptionPricePointId: "spp-7")
        #expect(p.affordances["listPrices"] == "asc subscription-offer-codes prices list --offer-code-id oc-1")
    }

    @Test func `roundtrip preserves all fields`() throws {
        let p = SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                           territory: "USA", subscriptionPricePointId: "spp-7")
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(SubscriptionOfferCodePrice.self, from: data)
        #expect(decoded == p)
    }

    @Test func `omits nil fields from JSON`() throws {
        let p = SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1")
        let json = String(decoding: try JSONEncoder().encode(p), as: UTF8.self)
        #expect(!json.contains("territory"))
        #expect(!json.contains("subscriptionPricePointId"))
    }

    @Test func `exposes table headers and row`() {
        let p = SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                           territory: "USA", subscriptionPricePointId: "spp-7")
        #expect(SubscriptionOfferCodePrice.tableHeaders == ["ID", "Territory", "Price Point ID"])
        #expect(p.tableRow == ["p-1", "USA", "spp-7"])
    }

    @Test func `tableRow uses empty strings for nil fields`() {
        let p = SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1")
        #expect(p.tableRow == ["p-1", "", ""])
    }

    @Test func `apiLinks resolve listPrices to nested REST path`() {
        let p = SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                           territory: "USA", subscriptionPricePointId: "spp-7")
        #expect(p.apiLinks["listPrices"]?.href == "/api/v1/subscription-offer-codes/oc-1/prices")
        #expect(p.apiLinks["listPrices"]?.method == "GET")
    }
}
