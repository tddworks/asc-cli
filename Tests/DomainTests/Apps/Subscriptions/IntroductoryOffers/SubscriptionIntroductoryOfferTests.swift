import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionIntroductoryOfferTests {

    @Test func `offer carries subscriptionId`() {
        let offer = MockRepositoryFactory.makeSubscriptionIntroductoryOffer(
            id: "offer-1",
            subscriptionId: "sub-42"
        )
        #expect(offer.subscriptionId == "sub-42")
    }

    @Test func `affordances include listOffers`() {
        let offer = MockRepositoryFactory.makeSubscriptionIntroductoryOffer(
            id: "offer-1",
            subscriptionId: "sub-42"
        )
        #expect(offer.affordances["listOffers"] == "asc subscription-offers list --subscription-id sub-42")
    }

    @Test func `affordances include delete with offer id`() {
        let offer = MockRepositoryFactory.makeSubscriptionIntroductoryOffer(
            id: "offer-1",
            subscriptionId: "sub-42"
        )
        #expect(offer.affordances["delete"] == "asc subscription-offers delete --offer-id offer-1")
    }

    @Test func `nil startDate endDate territory omitted from JSON`() throws {
        let offer = MockRepositoryFactory.makeSubscriptionIntroductoryOffer(
            startDate: nil,
            endDate: nil,
            territory: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(offer)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("startDate"))
        #expect(!json.contains("endDate"))
        #expect(!json.contains("territory"))
    }

    @Test func `present startDate endDate territory included in JSON`() throws {
        let offer = MockRepositoryFactory.makeSubscriptionIntroductoryOffer(
            startDate: "2024-01-01",
            endDate: "2024-06-30",
            territory: "USA"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(offer)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"startDate\""))
        #expect(json.contains("\"endDate\""))
        #expect(json.contains("\"territory\""))
        #expect(json.contains("2024-01-01"))
        #expect(json.contains("2024-06-30"))
        #expect(json.contains("USA"))
    }

    @Test func `offerMode requiresPricePoint is true for payAsYouGo and payUpFront`() {
        #expect(SubscriptionOfferMode.payAsYouGo.requiresPricePoint == true)
        #expect(SubscriptionOfferMode.payUpFront.requiresPricePoint == true)
        #expect(SubscriptionOfferMode.freeTrial.requiresPricePoint == false)
    }
}
