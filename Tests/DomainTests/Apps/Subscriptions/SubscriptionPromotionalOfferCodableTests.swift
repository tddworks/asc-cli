import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionPromotionalOfferCodableTests {

    @Test func `offer roundtrip preserves all fields`() throws {
        let offer = SubscriptionPromotionalOffer(
            id: "po-1", subscriptionId: "sub-1", name: "Winback",
            offerCode: "wb25", duration: .threeMonths, offerMode: .payAsYouGo, numberOfPeriods: 3
        )
        let data = try JSONEncoder().encode(offer)
        let decoded = try JSONDecoder().decode(SubscriptionPromotionalOffer.self, from: data)
        #expect(decoded == offer)
    }

    @Test func `price roundtrip preserves territory and subscriptionPricePointId`() throws {
        let price = SubscriptionPromotionalOfferPrice(id: "p-1", offerId: "po-1", territory: "USA", subscriptionPricePointId: "spp-1")
        let data = try JSONEncoder().encode(price)
        let decoded = try JSONDecoder().decode(SubscriptionPromotionalOfferPrice.self, from: data)
        #expect(decoded == price)
    }

    @Test func `price omits nil fields from JSON`() throws {
        let price = SubscriptionPromotionalOfferPrice(id: "p-1", offerId: "po-1")
        let json = String(decoding: try JSONEncoder().encode(price), as: UTF8.self)
        #expect(!json.contains("territory"))
        #expect(!json.contains("subscriptionPricePointId"))
    }

    @Test func `PromotionalOfferPriceInput value equality`() {
        let a = PromotionalOfferPriceInput(territory: "USA", pricePointId: "spp-1")
        let b = PromotionalOfferPriceInput(territory: "USA", pricePointId: "spp-1")
        let c = PromotionalOfferPriceInput(territory: "GBR", pricePointId: "spp-1")
        #expect(a == b)
        #expect(a != c)
    }
}
