import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchasePricePointTests {

    @Test func `price point carries iapId and territory`() {
        let pp = MockRepositoryFactory.makeInAppPurchasePricePoint(id: "pp-1", iapId: "iap-1", territory: "USA")
        #expect(pp.iapId == "iap-1")
        #expect(pp.territory == "USA")
    }

    @Test func `price point with territory affordances include setPrice and listPricePoints`() {
        let pp = MockRepositoryFactory.makeInAppPurchasePricePoint(id: "pp-1", iapId: "iap-1", territory: "USA")
        #expect(pp.affordances["listPricePoints"] == "asc iap price-points list --iap-id iap-1")
        #expect(pp.affordances["setPrice"] == "asc iap prices set --base-territory USA --iap-id iap-1 --price-point-id pp-1")
    }

    @Test func `price point without territory affordances omit setPrice`() {
        let pp = MockRepositoryFactory.makeInAppPurchasePricePoint(id: "pp-1", iapId: "iap-1", territory: nil)
        #expect(pp.affordances["setPrice"] == nil)
        #expect(pp.affordances["listPricePoints"] != nil)
    }

    @Test func `price point nil fields are omitted from JSON output`() throws {
        let pp = InAppPurchasePricePoint(id: "pp-1", iapId: "iap-1")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(pp)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("territory"))
        #expect(!json.contains("customerPrice"))
        #expect(!json.contains("proceeds"))
    }
}
