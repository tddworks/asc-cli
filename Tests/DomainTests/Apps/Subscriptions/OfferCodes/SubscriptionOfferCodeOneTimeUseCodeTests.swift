import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionOfferCodeOneTimeUseCodeTests {

    @Test func `one-time code carries offerCodeId`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(offerCodeId: "oc-99")
        #expect(code.offerCodeId == "oc-99")
    }

    @Test func `one-time code has count and dates`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(
            numberOfCodes: 5000,
            expirationDate: "2026-12-31"
        )
        #expect(code.numberOfCodes == 5000)
        #expect(code.expirationDate == "2026-12-31")
    }

    @Test func `active one-time code reports isActive true`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(isActive: true)
        #expect(code.isActive == true)
    }

    @Test func `affordances include listOneTimeCodes`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(offerCodeId: "oc-1")
        #expect(code.affordances["listOneTimeCodes"] == "asc subscription-offer-code-one-time-codes list --offer-code-id oc-1")
    }

    @Test func `deactivate affordance only when active`() {
        let active = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(id: "otc-1", isActive: true)
        #expect(active.affordances["deactivate"] == "asc subscription-offer-code-one-time-codes update --active false --one-time-code-id otc-1")

        let inactive = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(id: "otc-1", isActive: false)
        #expect(inactive.affordances["deactivate"] == nil)
    }

    @Test func `environment defaults to nil when not provided`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode()
        #expect(code.environment == nil)
    }

    @Test func `sandbox environment is preserved`() {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(environment: .sandbox)
        #expect(code.environment == .sandbox)
    }

    @Test func `environment encodes to JSON when present`() throws {
        let code = MockRepositoryFactory.makeSubscriptionOfferCodeOneTimeUseCode(environment: .sandbox)
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"environment\":\"SANDBOX\""))
    }

    @Test func `table headers include Environment column`() {
        #expect(SubscriptionOfferCodeOneTimeUseCode.tableHeaders.contains("Env"))
    }

    @Test func `optional fields omitted from JSON when nil`() throws {
        let code = SubscriptionOfferCodeOneTimeUseCode(
            id: "otc-1",
            offerCodeId: "oc-1",
            numberOfCodes: 100,
            createdDate: nil,
            expirationDate: "2026-12-31",
            isActive: true
        )
        let data = try JSONEncoder().encode(code)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("createdDate"))
    }
}
