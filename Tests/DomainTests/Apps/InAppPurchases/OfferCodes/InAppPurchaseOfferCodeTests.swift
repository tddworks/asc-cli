import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchaseOfferCodeTests {

    @Test func `offer code carries iapId`() {
        let code = MockRepositoryFactory.makeIAPOfferCode(iapId: "iap-99")
        #expect(code.iapId == "iap-99")
    }

    @Test func `offer code has name and active status`() {
        let code = MockRepositoryFactory.makeIAPOfferCode(
            name: "FREEGEMS",
            isActive: true
        )
        #expect(code.name == "FREEGEMS")
        #expect(code.isActive == true)
    }

    @Test func `customer eligibilities are preserved`() {
        let code = MockRepositoryFactory.makeIAPOfferCode(
            customerEligibilities: [.nonSpender, .churnedSpender]
        )
        #expect(code.customerEligibilities == [.nonSpender, .churnedSpender])
    }

    @Test func `IAP customer eligibility raw values match API`() {
        #expect(IAPCustomerEligibility.nonSpender.rawValue == "NON_SPENDER")
        #expect(IAPCustomerEligibility.activeSpender.rawValue == "ACTIVE_SPENDER")
        #expect(IAPCustomerEligibility.churnedSpender.rawValue == "CHURNED_SPENDER")
    }

    @Test func `affordances include listOfferCodes and listCustomCodes and listOneTimeCodes`() {
        let code = MockRepositoryFactory.makeIAPOfferCode(id: "oc-1", iapId: "iap-1")
        #expect(code.affordances["listOfferCodes"] == "asc iap-offer-codes list --iap-id iap-1")
        #expect(code.affordances["listCustomCodes"] == "asc iap-offer-code-custom-codes list --offer-code-id oc-1")
        #expect(code.affordances["listOneTimeCodes"] == "asc iap-offer-code-one-time-codes list --offer-code-id oc-1")
    }

    @Test func `deactivate affordance only when active`() {
        let active = MockRepositoryFactory.makeIAPOfferCode(id: "oc-1", isActive: true)
        #expect(active.affordances["deactivate"] == "asc iap-offer-codes update --active false --offer-code-id oc-1")

        let inactive = MockRepositoryFactory.makeIAPOfferCode(id: "oc-1", isActive: false)
        #expect(inactive.affordances["deactivate"] == nil)
    }

    @Test func `optional fields omitted from JSON when nil`() throws {
        let code = InAppPurchaseOfferCode(
            id: "oc-1",
            iapId: "iap-1",
            name: "TEST",
            customerEligibilities: [.nonSpender],
            isActive: true,
            totalNumberOfCodes: nil,
            productionCodeCount: nil,
            sandboxCodeCount: nil
        )
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("totalNumberOfCodes"))
        #expect(!json.contains("productionCodeCount"))
        #expect(!json.contains("sandboxCodeCount"))
    }

    @Test func `production and sandbox code counts split totals by environment`() {
        let code = MockRepositoryFactory.makeIAPOfferCode(
            productionCodeCount: 12_000,
            sandboxCodeCount: 250
        )
        #expect(code.productionCodeCount == 12_000)
        #expect(code.sandboxCodeCount == 250)
    }

    @Test func `production and sandbox code counts encode to JSON when present`() throws {
        let code = MockRepositoryFactory.makeIAPOfferCode(
            productionCodeCount: 100,
            sandboxCodeCount: 5
        )
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"productionCodeCount\":100"))
        #expect(json.contains("\"sandboxCodeCount\":5"))
    }
}
