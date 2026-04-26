import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionPriceCodableTests {

    @Test func `subscription price roundtrip`() throws {
        let p = SubscriptionPrice(id: "price-1", subscriptionId: "sub-1")
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(SubscriptionPrice.self, from: data)
        #expect(decoded == p)
    }

    @Test func `subscription price affordances point at price-points list`() {
        let p = SubscriptionPrice(id: "price-1", subscriptionId: "sub-1")
        #expect(p.affordances["listPricePoints"] == "asc subscriptions price-points list --subscription-id sub-1")
    }

    @Test func `subscription price exposes table headers and row`() {
        let p = SubscriptionPrice(id: "price-1", subscriptionId: "sub-1")
        #expect(SubscriptionPrice.tableHeaders == ["ID", "Subscription ID"])
        #expect(p.tableRow == ["price-1", "sub-1"])
    }

    @Test func `pricePoint roundtrip preserves all fields including proceedsYear2`() throws {
        let pp = SubscriptionPricePoint(
            id: "spp-1", subscriptionId: "sub-1", territory: "USA",
            customerPrice: "9.99", proceeds: "6.99", proceedsYear2: "7.49"
        )
        let data = try JSONEncoder().encode(pp)
        let decoded = try JSONDecoder().decode(SubscriptionPricePoint.self, from: data)
        #expect(decoded == pp)
    }
}
