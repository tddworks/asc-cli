import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionOfferCodeTests {

    @Test func `offer code carries subscriptionId`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCode(subscriptionId: "sub-99")
        #expect(code.subscriptionId == "sub-99")
    }

    @Test func `offer code has name and configuration`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCode(
            name: "SUMMER2026",
            duration: .oneMonth,
            offerMode: .freeTrial,
            numberOfPeriods: 1
        )
        #expect(code.name == "SUMMER2026")
        #expect(code.duration == .oneMonth)
        #expect(code.offerMode == .freeTrial)
        #expect(code.numberOfPeriods == 1)
    }

    @Test func `active offer code reports isActive true`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCode(isActive: true)
        #expect(code.isActive == true)
    }

    @Test func `inactive offer code reports isActive false`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCode(isActive: false)
        #expect(code.isActive == false)
    }

    @Test func `customer eligibilities are preserved`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCode(
            customerEligibilities: [.new, .lapsed]
        )
        #expect(code.customerEligibilities == [.new, .lapsed])
    }

    @Test func `offer eligibility raw values match API`() {
        #expect(SubscriptionOfferEligibility.stackable.rawValue == "STACKABLE")
        #expect(SubscriptionOfferEligibility.introductory.rawValue == "INTRODUCTORY")
        #expect(SubscriptionOfferEligibility.subscriptionOffer.rawValue == "SUBSCRIPTION_OFFER")
    }

    @Test func `customer eligibility raw values match API`() {
        #expect(SubscriptionCustomerEligibility.new.rawValue == "NEW")
        #expect(SubscriptionCustomerEligibility.lapsed.rawValue == "LAPSED")
        #expect(SubscriptionCustomerEligibility.winBack.rawValue == "WIN_BACK")
        #expect(SubscriptionCustomerEligibility.paidSubscriber.rawValue == "PAID_SUBSCRIBER")
    }

    @Test func `affordances include listOfferCodes and listCustomCodes and listOneTimeCodes`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCode(id: "oc-1", subscriptionId: "sub-1")
        #expect(code.affordances["listOfferCodes"] == "asc subscription-offer-codes list --subscription-id sub-1")
        #expect(code.affordances["listCustomCodes"] == "asc subscription-offer-code-custom-codes list --offer-code-id oc-1")
        #expect(code.affordances["listOneTimeCodes"] == "asc subscription-offer-code-one-time-codes list --offer-code-id oc-1")
    }

    @Test func `deactivate affordance only when active`() {
        let active = MockRepositoryFactory.makeSubscriptionOfferCode(id: "oc-1", isActive: true)
        #expect(active.affordances["deactivate"] == "asc subscription-offer-codes update --active false --offer-code-id oc-1")

        let inactive = MockRepositoryFactory.makeSubscriptionOfferCode(id: "oc-1", isActive: false)
        #expect(inactive.affordances["deactivate"] == nil)
    }

    @Test func `optional fields omitted from JSON when nil`() throws {
        let code = SubscriptionOfferCode(
            id: "oc-1",
            subscriptionId: "sub-1",
            name: "TEST",
            customerEligibilities: [.new],
            offerEligibility: .stackable,
            duration: .oneMonth,
            offerMode: .freeTrial,
            numberOfPeriods: 1,
            totalNumberOfCodes: nil,
            isActive: true
        )
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("totalNumberOfCodes"))
    }

    @Test func `non-nil optional fields included in JSON`() throws {
        let code = SubscriptionOfferCode(
            id: "oc-1",
            subscriptionId: "sub-1",
            name: "TEST",
            customerEligibilities: [.new],
            offerEligibility: .stackable,
            duration: .oneMonth,
            offerMode: .freeTrial,
            numberOfPeriods: 1,
            totalNumberOfCodes: 500,
            isActive: true
        )
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("totalNumberOfCodes"))
    }
}
