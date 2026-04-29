import Foundation
import Testing
@testable import Domain

@Suite
struct InAppPurchaseTests {

    // MARK: - Review note (read-side)

    @Test func `iap carries reviewNote when set`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(reviewNote: "Use code TEST")
        #expect(iap.reviewNote == "Use code TEST")
    }

    @Test func `iap reviewNote is nil by default`() {
        let iap = MockRepositoryFactory.makeInAppPurchase()
        #expect(iap.reviewNote == nil)
    }

    @Test func `iap with nil reviewNote omits it from JSON`() throws {
        let iap = MockRepositoryFactory.makeInAppPurchase(reviewNote: nil)
        let json = String(decoding: try JSONEncoder().encode(iap), as: UTF8.self)
        #expect(!json.contains("reviewNote"))
    }

    @Test func `iap with reviewNote encodes it in JSON`() throws {
        let iap = MockRepositoryFactory.makeInAppPurchase(reviewNote: "Use code TEST")
        let json = String(decoding: try JSONEncoder().encode(iap), as: UTF8.self)
        #expect(json.contains("\"reviewNote\":\"Use code TEST\""))
    }

    @Test func `iap roundtrips reviewNote through Codable`() throws {
        let iap = MockRepositoryFactory.makeInAppPurchase(reviewNote: "Use code TEST")
        let data = try JSONEncoder().encode(iap)
        let decoded = try JSONDecoder().decode(InAppPurchase.self, from: data)
        #expect(decoded.reviewNote == "Use code TEST")
    }

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

    @Test func `submit affordance routes to iris when isFirstTimeSubmission`() {
        // Apple requires the first IAP for an app to be submitted alongside a new
        // App Store version — only `POST /iris/v1/inAppPurchaseSubmissions` accepts
        // `submitWithNextAppStoreVersion`. The IAP affordance auto-dispatches to that
        // path so the user never has to know iris-vs-sdk exists.
        let firstTime = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-1", state: .readyToSubmit, isFirstTimeSubmission: true
        )
        #expect(firstTime.affordances["submit"] == "asc iris iap-submissions create --iap-id iap-1")
    }

    @Test func `submit affordance routes to sdk when not first-time`() {
        let subsequent = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-2", state: .readyToSubmit, isFirstTimeSubmission: false
        )
        #expect(subsequent.affordances["submit"] == "asc iap submit --iap-id iap-2")
    }

    @Test func `submit apiLinks resolve to iris path for first-time IAPs`() {
        let firstTime = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-1", state: .readyToSubmit, isFirstTimeSubmission: true
        )
        // The iris route isn't registered with the path resolver yet (it's a fresh
        // CLI command), so the resolver falls back to the default `/api/v1/{command}/{action}`
        // shape. Both CLI and REST renderers stay in sync because both go through
        // `Affordance` — what matters is that the resolved REST path is iris-flavored
        // and not the legacy `/api/v1/iap/iap-1/submit`.
        let link = firstTime.apiLinks["submit"]
        #expect(link?.method == "POST")
        #expect(link?.href.contains("iris") == true)
        #expect(link?.href.contains("iap-1") == true)
    }

    @Test func `iap defaults isFirstTimeSubmission to false`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1", state: .readyToSubmit)
        #expect(iap.isFirstTimeSubmission == false)
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

    @Test func `iap affordances include uploadReviewScreenshot with file placeholder`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["uploadReviewScreenshot"] == "asc iap-review-screenshot upload --file <path> --iap-id iap-1")
    }

    @Test func `iap affordances include uploadImage with file placeholder`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.affordances["uploadImage"] == "asc iap-images upload --file <path> --iap-id iap-1")
    }

    @Test func `iap apiLinks include uploadReviewScreenshot as POST on collection path`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["uploadReviewScreenshot"]?.href == "/api/v1/iap/iap-1/review-screenshot")
        #expect(iap.apiLinks["uploadReviewScreenshot"]?.method == "POST")
    }

    @Test func `iap apiLinks include uploadImage as POST on collection path`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1")
        #expect(iap.apiLinks["uploadImage"]?.href == "/api/v1/iap/iap-1/images")
        #expect(iap.apiLinks["uploadImage"]?.method == "POST")
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
