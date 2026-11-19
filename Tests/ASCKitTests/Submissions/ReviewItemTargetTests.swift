import Testing
@testable import ASCKit

@Suite
struct ReviewItemTargetTests {

    @Test func `exactly one version id picks what the item sends to review`() {
        #expect(ReviewItemTarget(versionId: "v-1") == .appStoreVersion("v-1"))
        #expect(ReviewItemTarget(iapVersionId: "iv-1") == .inAppPurchaseVersion("iv-1"))
        #expect(ReviewItemTarget(subscriptionVersionId: "sv-1") == .subscriptionVersion("sv-1"))
        #expect(ReviewItemTarget(subscriptionGroupVersionId: "gv-1") == .subscriptionGroupVersion("gv-1"))
    }

    @Test func `no version id or more than one is not a valid item`() {
        #expect(ReviewItemTarget() == nil)
        #expect(ReviewItemTarget(versionId: "v-1", iapVersionId: "iv-1") == nil)
    }
}
