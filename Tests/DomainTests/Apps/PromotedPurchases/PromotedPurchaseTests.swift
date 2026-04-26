import Foundation
import Testing
@testable import Domain

@Suite
struct PromotedPurchaseTests {

    @Test func `promoted purchase carries appId and inAppPurchaseId`() {
        let p = PromotedPurchase(
            id: "pp-1", appId: "app-1", isVisibleForAllUsers: true,
            isEnabled: true, state: .approved, inAppPurchaseId: "iap-1"
        )
        #expect(p.appId == "app-1")
        #expect(p.inAppPurchaseId == "iap-1")
        #expect(p.subscriptionId == nil)
    }

    @Test func `affordances include listSiblings, update, delete`() {
        let p = PromotedPurchase(id: "pp-1", appId: "app-1", isVisibleForAllUsers: true, isEnabled: true)
        #expect(p.affordances["listSiblings"] == "asc promoted-purchases list --app-id app-1")
        #expect(p.affordances["update"] == "asc promoted-purchases update --promoted-id pp-1")
        #expect(p.affordances["delete"] == "asc promoted-purchases delete --promoted-id pp-1")
    }

    @Test func `omits nil ids from JSON`() throws {
        let p = PromotedPurchase(id: "pp-1", appId: "app-1", isVisibleForAllUsers: true, isEnabled: true)
        let json = String(decoding: try JSONEncoder().encode(p), as: UTF8.self)
        #expect(!json.contains("inAppPurchaseId"))
        #expect(!json.contains("subscriptionId"))
        #expect(!json.contains("state"))
    }
}
