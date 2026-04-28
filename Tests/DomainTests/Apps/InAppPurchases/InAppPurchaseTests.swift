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

    @Test func `iap affordances include listPricePoints always`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["listPricePoints"] == "asc iap price-points list --iap-id iap-1")
    }

    @Test func `iap affordances include submit only when readyToSubmit`() {
        let ready = MockRepositoryFactory.makeInAppPurchase(id: "iap-1", state: .readyToSubmit)
        let missing = MockRepositoryFactory.makeInAppPurchase(id: "iap-2", state: .missingMetadata)
        #expect(ready.affordances["submit"] == "asc iap submit --iap-id iap-1")
        #expect(missing.affordances["submit"] == nil)
    }

    @Test func `iap localization affordances include listSiblings`() {
        let loc = MockRepositoryFactory.makeInAppPurchaseLocalization(id: "loc-1", iapId: "iap-1")
        #expect(loc.affordances["listSiblings"] == "asc iap-localizations list --iap-id iap-1")
    }

    @Test func `iap localization affordances include update with localization id`() {
        let loc = MockRepositoryFactory.makeInAppPurchaseLocalization(id: "loc-1", iapId: "iap-1")
        #expect(loc.affordances["update"] == "asc iap-localizations update --localization-id loc-1 --name <name>")
    }

    @Test func `iap localization affordances include delete with localization id`() {
        let loc = MockRepositoryFactory.makeInAppPurchaseLocalization(id: "loc-1", iapId: "iap-1")
        #expect(loc.affordances["delete"] == "asc iap-localizations delete --localization-id loc-1")
    }

    @Test func `iap affordances include listOfferCodes`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["listOfferCodes"] == "asc iap-offer-codes list --iap-id iap-1")
    }

    @Test func `iap affordances include createOfferCode`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["createOfferCode"] == "asc iap-offer-codes create --eligibility <NON_SPENDER|ACTIVE_SPENDER|CHURNED_SPENDER> --iap-id iap-1 --name <name>")
    }

    @Test func `iap apiLinks include createOfferCode as POST under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["createOfferCode"]?.href == "/api/v1/iap/iap-1/offer-codes")
        #expect(iap.apiLinks["createOfferCode"]?.method == "POST")
    }

    @Test func `iap affordances include update with iap id`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["update"] == "asc iap update --iap-id iap-1 --reference-name <name>")
    }

    @Test func `iap affordances include delete with iap id`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["delete"] == "asc iap delete --iap-id iap-1")
    }

    // MARK: - REST navigation links (HATEOAS)

    @Test func `iap apiLinks include listLocalizations under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["listLocalizations"]?.href == "/api/v1/iap/iap-1/localizations")
        #expect(iap.apiLinks["listLocalizations"]?.method == "GET")
    }

    @Test func `iap apiLinks include listOfferCodes under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["listOfferCodes"]?.href == "/api/v1/iap/iap-1/offer-codes")
        #expect(iap.apiLinks["listOfferCodes"]?.method == "GET")
    }

    @Test func `iap apiLinks include getAvailability under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["getAvailability"]?.href == "/api/v1/iap/iap-1/availability")
        #expect(iap.apiLinks["getAvailability"]?.method == "GET")
    }

    @Test func `iap apiLinks include getReviewScreenshot under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["getReviewScreenshot"]?.href == "/api/v1/iap/iap-1/review-screenshot")
        #expect(iap.apiLinks["getReviewScreenshot"]?.method == "GET")
    }

    @Test func `iap apiLinks include listImages under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["listImages"]?.href == "/api/v1/iap/iap-1/images")
        #expect(iap.apiLinks["listImages"]?.method == "GET")
    }

    @Test func `iap apiLinks include listPricePoints under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["listPricePoints"]?.href == "/api/v1/iap/iap-1/price-points")
        #expect(iap.apiLinks["listPricePoints"]?.method == "GET")
    }

    @Test func `iap apiLinks include update and delete on flat resource`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["update"]?.href == "/api/v1/iap/iap-1")
        #expect(iap.apiLinks["update"]?.method == "PATCH")
        #expect(iap.apiLinks["delete"]?.href == "/api/v1/iap/iap-1")
        #expect(iap.apiLinks["delete"]?.method == "DELETE")
    }

    @Test func `iap apiLinks include submit only when readyToSubmit`() {
        let ready = MockRepositoryFactory.makeInAppPurchase(id: "iap-1", state: .readyToSubmit)
        let missing = MockRepositoryFactory.makeInAppPurchase(id: "iap-2", state: .missingMetadata)
        #expect(ready.apiLinks["submit"]?.href == "/api/v1/iap/iap-1/submit")
        #expect(ready.apiLinks["submit"]?.method == "POST")
        #expect(missing.apiLinks["submit"] == nil)
    }

    @Test func `iap apiLinks include getPriceSchedule under nested parent`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["getPriceSchedule"]?.href == "/api/v1/iap/iap-1/price-schedule")
        #expect(iap.apiLinks["getPriceSchedule"]?.method == "GET")
    }

    @Test func `iap affordances include getPriceSchedule with iap id`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["getPriceSchedule"] == "asc iap-price-schedule get --iap-id iap-1")
    }

    @Test func `iap affordances include setPrice with placeholders`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["setPrice"] == "asc iap prices set --base-territory <territory> --iap-id iap-1 --price-point-id <price-point-id>")
    }

    @Test func `iap apiLinks include setPrice posting to nested prices endpoint`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["setPrice"]?.href == "/api/v1/iap/iap-1/prices/set")
        #expect(iap.apiLinks["setPrice"]?.method == "POST")
    }
}
