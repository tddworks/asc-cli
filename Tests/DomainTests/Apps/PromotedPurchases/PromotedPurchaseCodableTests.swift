import Foundation
import Testing
@testable import Domain

@Suite
struct PromotedPurchaseCodableTests {

    @Test func `roundtrip preserves all fields when populated`() throws {
        let p = PromotedPurchase(
            id: "pp-1", appId: "app-1",
            isVisibleForAllUsers: true, isEnabled: false,
            state: .approved, inAppPurchaseId: "iap-1", subscriptionId: nil
        )
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(PromotedPurchase.self, from: data)
        #expect(decoded == p)
    }

    @Test func `state isLocked covers waitingForReview, inReview only`() {
        let cases: [(PromotedPurchaseState, Bool)] = [
            (.approved, false),
            (.rejected, false),
            (.prepareForSubmission, false),
            (.waitingForReview, true),
            (.inReview, true),
            (.developerActionNeeded, false),
        ]
        for (state, expected) in cases {
            #expect(state.isLocked == expected, "isLocked for \(state.rawValue)")
        }
    }

    @Test func `state isApproved is only true for approved`() {
        #expect(PromotedPurchaseState.approved.isApproved == true)
        #expect(PromotedPurchaseState.rejected.isApproved == false)
        #expect(PromotedPurchaseState.developerActionNeeded.isApproved == false)
    }

    @Test func `table row uses iap prefix when promoting an IAP`() {
        let p = PromotedPurchase(id: "pp-1", appId: "app-1",
                                 isVisibleForAllUsers: true, isEnabled: true,
                                 inAppPurchaseId: "iap-9")
        #expect(p.tableRow.last == "iap:iap-9")
    }

    @Test func `table row uses sub prefix when promoting a subscription`() {
        let p = PromotedPurchase(id: "pp-1", appId: "app-1",
                                 isVisibleForAllUsers: true, isEnabled: true,
                                 subscriptionId: "sub-9")
        #expect(p.tableRow.last == "sub:sub-9")
    }
}
