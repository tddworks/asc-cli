import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionPricePointTests {

    @Test func `price point carries subscriptionId`() {
        let pp = SubscriptionPricePoint(id: "pp-1", subscriptionId: "sub-1", territory: "USA", customerPrice: "9.99", proceeds: "6.99")
        #expect(pp.subscriptionId == "sub-1")
        #expect(pp.id == "pp-1")
    }

    @Test func `affordances include listPricePoints always`() {
        let pp = SubscriptionPricePoint(id: "pp-1", subscriptionId: "sub-1")
        #expect(pp.affordances["listPricePoints"] == "asc subscriptions price-points list --subscription-id sub-1")
    }

    @Test func `affordances include setPrice when territory present`() {
        let pp = SubscriptionPricePoint(id: "pp-1", subscriptionId: "sub-1", territory: "USA")
        #expect(pp.affordances["setPrice"] == "asc subscriptions prices set --subscription-id sub-1 --territory USA --price-point-id pp-1")
    }

    @Test func `affordances omit setPrice when territory absent`() {
        let pp = SubscriptionPricePoint(id: "pp-1", subscriptionId: "sub-1", territory: nil)
        #expect(pp.affordances["setPrice"] == nil)
    }

    @Test func `proceedsYear2 is encoded when present`() throws {
        let pp = SubscriptionPricePoint(id: "pp-1", subscriptionId: "sub-1", territory: "USA",
                                        customerPrice: "9.99", proceeds: "6.99", proceedsYear2: "7.49")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(pp), as: UTF8.self)
        #expect(json.contains("\"proceedsYear2\":\"7.49\""))
    }

    @Test func `proceedsYear2 is omitted when nil`() throws {
        let pp = SubscriptionPricePoint(id: "pp-1", subscriptionId: "sub-1", territory: "USA",
                                        customerPrice: "9.99", proceeds: "6.99", proceedsYear2: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(pp), as: UTF8.self)
        #expect(!json.contains("proceedsYear2"))
    }
}
