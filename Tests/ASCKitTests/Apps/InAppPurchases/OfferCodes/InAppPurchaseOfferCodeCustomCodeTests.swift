import Foundation
import Testing
@testable import ASCKit

@Suite
struct InAppPurchaseOfferCodeCustomCodeTests {

    @Test func `custom code carries offerCodeId`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeCustomCode(offerCodeId: "oc-99")
        #expect(code.offerCodeId == "oc-99")
    }

    @Test func `custom code has code string and count`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeCustomCode(
            customCode: "FREEGEMS100",
            numberOfCodes: 500
        )
        #expect(code.customCode == "FREEGEMS100")
        #expect(code.numberOfCodes == 500)
    }

    @Test func `affordances include listCustomCodes`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeCustomCode(offerCodeId: "oc-1")
        #expect(code.affordances["listCustomCodes"] == "asc iap-offer-code-custom-codes list --offer-code-id oc-1")
    }

    @Test func `deactivate affordance only when active`() {
        let active = MockRepositoryFactory.makeIAPOfferCodeCustomCode(id: "cc-1", isActive: true)
        #expect(active.affordances["deactivate"] == "asc iap-offer-code-custom-codes update --custom-code-id cc-1 --active false")

        let inactive = MockRepositoryFactory.makeIAPOfferCodeCustomCode(id: "cc-1", isActive: false)
        #expect(inactive.affordances["deactivate"] == nil)
    }
}
