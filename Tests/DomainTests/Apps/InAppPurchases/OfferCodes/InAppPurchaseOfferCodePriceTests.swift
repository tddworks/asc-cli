import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchaseOfferCodePriceTests {

    @Test func `price carries offerCodeId`() {
        let p = InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                            territory: "USA", pricePointId: "pp-9")
        #expect(p.offerCodeId == "oc-1")
        #expect(p.id == "p-1")
        #expect(p.territory == "USA")
        #expect(p.pricePointId == "pp-9")
    }

    @Test func `affordances include listPrices`() {
        let p = InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                            territory: "USA", pricePointId: "pp-9")
        #expect(p.affordances["listPrices"] == "asc iap-offer-codes prices list --offer-code-id oc-1")
    }

    @Test func `roundtrip preserves all fields`() throws {
        let p = InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                            territory: "USA", pricePointId: "pp-9")
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(InAppPurchaseOfferCodePrice.self, from: data)
        #expect(decoded == p)
    }

    @Test func `omits nil fields from JSON`() throws {
        let p = InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1")
        let json = String(decoding: try JSONEncoder().encode(p), as: UTF8.self)
        #expect(!json.contains("territory"))
        #expect(!json.contains("pricePointId"))
    }

    @Test func `exposes table headers and row`() {
        let p = InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                            territory: "USA", pricePointId: "pp-9")
        #expect(InAppPurchaseOfferCodePrice.tableHeaders == ["ID", "Territory", "Price Point ID"])
        #expect(p.tableRow == ["p-1", "USA", "pp-9"])
    }

    @Test func `tableRow uses empty strings for nil fields`() {
        let p = InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1")
        #expect(p.tableRow == ["p-1", "", ""])
    }

    @Test func `apiLinks resolve listPrices to nested REST path`() {
        let p = InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1",
                                            territory: "USA", pricePointId: "pp-9")
        #expect(p.apiLinks["listPrices"]?.href == "/api/v1/iap-offer-codes/oc-1/prices")
        #expect(p.apiLinks["listPrices"]?.method == "GET")
    }
}
