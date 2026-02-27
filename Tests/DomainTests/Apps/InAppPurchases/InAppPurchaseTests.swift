import Testing
@testable import Domain

@Suite
struct InAppPurchaseTests {

    @Test func `iap carries appId and productId`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1", appId: "app-1", productId: "com.app.gold")
        #expect(iap.appId == "app-1")
        #expect(iap.productId == "com.app.gold")
    }

    @Test func `iap state isEditable for missingMetadata`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(state: .missingMetadata)
        #expect(iap.state.isEditable == true)
        #expect(iap.state.isApproved == false)
    }

    @Test func `iap state isApproved and isLive for approved`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(state: .approved)
        #expect(iap.state.isApproved == true)
        #expect(iap.state.isLive == true)
        #expect(iap.state.isEditable == false)
    }

    @Test func `iap affordances include listLocalizations`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["listLocalizations"] == "asc iap-localizations list --iap-id iap-1")
    }

    @Test func `iap affordances include createLocalization`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["createLocalization"] == "asc iap-localizations create --iap-id iap-1 --locale en-US --name <name>")
    }

    @Test func `iap type cliArgument initializer`() {
        #expect(InAppPurchaseType(cliArgument: "consumable") == .consumable)
        #expect(InAppPurchaseType(cliArgument: "non-consumable") == .nonConsumable)
        #expect(InAppPurchaseType(cliArgument: "non-renewing-subscription") == .nonRenewingSubscription)
        #expect(InAppPurchaseType(cliArgument: "unknown") == nil)
    }

    @Test func `iap localization affordances include listSiblings`() {
        let loc = MockRepositoryFactory.makeInAppPurchaseLocalization(id: "loc-1", iapId: "iap-1")
        #expect(loc.affordances["listSiblings"] == "asc iap-localizations list --iap-id iap-1")
    }
}
