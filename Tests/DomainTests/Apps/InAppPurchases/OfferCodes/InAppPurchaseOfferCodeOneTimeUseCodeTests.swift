import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchaseOfferCodeOneTimeUseCodeTests {

    @Test func `one-time code carries offerCodeId`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(offerCodeId: "oc-99")
        #expect(code.offerCodeId == "oc-99")
    }

    @Test func `one-time code has count and dates`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(
            numberOfCodes: 3000,
            expirationDate: "2026-06-30"
        )
        #expect(code.numberOfCodes == 3000)
        #expect(code.expirationDate == "2026-06-30")
    }

    @Test func `affordances include listOneTimeCodes`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(offerCodeId: "oc-1")
        #expect(code.affordances["listOneTimeCodes"] == "asc iap-offer-code-one-time-codes list --offer-code-id oc-1")
    }

    @Test func `deactivate affordance only when active`() {
        let active = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(id: "otc-1", isActive: true)
        #expect(active.affordances["deactivate"] == "asc iap-offer-code-one-time-codes update --active false --one-time-code-id otc-1")

        let inactive = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(id: "otc-1", isActive: false)
        #expect(inactive.affordances["deactivate"] == nil)
    }

    @Test func `environment defaults to nil when not provided`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode()
        #expect(code.environment == nil)
    }

    @Test func `sandbox environment is preserved`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(environment: .sandbox)
        #expect(code.environment == .sandbox)
    }

    @Test func `production environment is preserved`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(environment: .production)
        #expect(code.environment == .production)
    }

    @Test func `environment encodes to JSON when present`() throws {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(environment: .sandbox)
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"environment\":\"SANDBOX\""))
    }

    @Test func `environment omitted from JSON when nil`() throws {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(environment: nil)
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("environment"))
    }

    @Test func `table headers include Environment column`() {
        #expect(InAppPurchaseOfferCodeOneTimeUseCode.tableHeaders.contains("Env"))
    }

    @Test func `table row includes environment raw value`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(environment: .sandbox)
        #expect(code.tableRow.contains("SANDBOX"))
    }

    @Test func `apiLinks resolve listOneTimeCodes to nested REST path under offer code`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(offerCodeId: "oc-1")
        #expect(code.apiLinks["listOneTimeCodes"]?.href == "/api/v1/iap-offer-codes/oc-1/one-time-codes")
        #expect(code.apiLinks["listOneTimeCodes"]?.method == "GET")
    }

    @Test func `apiLinks resolve deactivate to PATCH on the code id`() {
        let code = MockRepositoryFactory.makeIAPOfferCodeOneTimeUseCode(id: "otc-1", isActive: true)
        #expect(code.apiLinks["deactivate"]?.href == "/api/v1/iap-offer-code-one-time-codes/otc-1")
        #expect(code.apiLinks["deactivate"]?.method == "PATCH")
    }
}
