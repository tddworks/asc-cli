import Foundation
import Testing
@testable import ASCKit

@Suite
struct SubscriptionOfferCodeCustomCodeTests {

    @Test func `custom code carries offerCodeId`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeCustomCode(offerCodeId: "oc-99")
        #expect(code.offerCodeId == "oc-99")
    }

    @Test func `custom code has code string and count`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeCustomCode(
            customCode: "SUMMER2026",
            numberOfCodes: 1000
        )
        #expect(code.customCode == "SUMMER2026")
        #expect(code.numberOfCodes == 1000)
    }

    @Test func `active custom code reports isActive true`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeCustomCode(isActive: true)
        #expect(code.isActive == true)
    }

    @Test func `affordances include listCustomCodes`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeCustomCode(offerCodeId: "oc-1")
        #expect(code.affordances["listCustomCodes"] == "asc subscription-offer-code-custom-codes list --offer-code-id oc-1")
    }

    @Test func `deactivate affordance only when active`() {
        let active = MockRepositoryFactory.makeSubscriptionOfferCodeCustomCode(id: "cc-1", isActive: true)
        #expect(active.affordances["deactivate"] == "asc subscription-offer-code-custom-codes update --custom-code-id cc-1 --active false")

        let inactive = MockRepositoryFactory.makeSubscriptionOfferCodeCustomCode(id: "cc-1", isActive: false)
        #expect(inactive.affordances["deactivate"] == nil)
    }

    @Test func `optional fields omitted from JSON when nil`() throws {
        let code = SubscriptionOfferCodeCustomCode(
            id: "cc-1",
            offerCodeId: "oc-1",
            customCode: "TEST",
            numberOfCodes: 100,
            createdDate: nil,
            expirationDate: nil,
            isActive: true
        )
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("createdDate"))
        #expect(!json.contains("expirationDate"))
    }
}
