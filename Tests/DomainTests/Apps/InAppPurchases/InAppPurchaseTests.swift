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

    @Test func `iap affordances include submit only when readyToSubmit and not first-time`() {
        // Default factory leaves isFirstTimeSubmission=false → public-SDK direct submit
        // is the established-app path.
        let ready = MockRepositoryFactory.makeInAppPurchase(id: "iap-1", state: .readyToSubmit)
        let missing = MockRepositoryFactory.makeInAppPurchase(id: "iap-2", state: .missingMetadata)
        #expect(ready.affordances["submit"] == "asc iap submit --iap-id iap-1")
        #expect(missing.affordances["submit"] == nil)
    }

    @Test func `first-time IAP shows addToNextVersion only (no submit)`() {
        // Apple requires the first IAP for an app to ride along with a new App Store
        // version — only the iris queue path accepts that. There's no public-SDK
        // direct path that works, so submit is hidden.
        let firstTime = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-1", state: .readyToSubmit, isFirstTimeSubmission: true
        )
        #expect(firstTime.affordances["addToNextVersion"] == "asc iris iap-submissions create --iap-id iap-1")
        #expect(firstTime.affordances["submit"] == nil)
    }

    @Test func `subsequent IAP shows both submit and addToNextVersion when ready`() {
        // The app already has shipped IAPs, so first-IAP gate is cleared. Either path
        // works — agent picks based on whether they want this IAP reviewed standalone
        // (submit, public SDK) or attached to next app version (addToNextVersion, iris).
        let subsequent = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-2", state: .readyToSubmit, isFirstTimeSubmission: false
        )
        #expect(subsequent.affordances["submit"] == "asc iap submit --iap-id iap-2")
        #expect(subsequent.affordances["addToNextVersion"] == "asc iris iap-submissions create --iap-id iap-2")
    }

    @Test func `addToNextVersion apiLinks resolve to iris REST path`() {
        let firstTime = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-1", state: .readyToSubmit, isFirstTimeSubmission: true
        )
        let link = firstTime.apiLinks["addToNextVersion"]
        #expect(link?.method == "POST")
        #expect(link?.href.contains("iris") == true)
        #expect(link?.href.contains("iap-1") == true)
    }

    @Test func `removeFromNextVersion affordance fires when IAP is queued for next version`() {
        // Inverse of addToNextVersion. Iris-queued submissions can only be deleted via
        // the iris DELETE — public-SDK DELETE doesn't accept them — so the affordance
        // routes through `asc iris iap-submissions delete`. Submission resource is
        // keyed by parent IAP id in iris, so `--submission-id <iapId>` works.
        let queued = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-7", state: .readyToSubmit, submitWithNextAppStoreVersion: true
        )
        #expect(queued.affordances["removeFromNextVersion"] == "asc iris iap-submissions delete --submission-id iap-7")
    }

    @Test func `removeFromNextVersion apiLinks resolve to iris REST DELETE path`() {
        let queued = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-7", state: .readyToSubmit, submitWithNextAppStoreVersion: true
        )
        let link = queued.apiLinks["removeFromNextVersion"]
        #expect(link?.method == "DELETE")
        #expect(link?.href == "/api/v1/iris/iap-submissions/iap-7")
    }

    @Test func `queued IAP suppresses submit and addToNextVersion`() {
        // Already queued — re-submitting via either path would be rejected. Only
        // the dequeue affordance fires.
        let queued = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-7", state: .readyToSubmit, submitWithNextAppStoreVersion: true
        )
        #expect(queued.affordances["submit"] == nil)
        #expect(queued.affordances["addToNextVersion"] == nil)
        #expect(queued.affordances["removeFromNextVersion"] != nil)
    }

    @Test func `removeFromNextVersion is hidden when not in readyToSubmit`() {
        // Out of caution — if the IAP advances to active review, we don't want to
        // display the "remove from next version" affordance there (different semantic).
        let inReview = MockRepositoryFactory.makeInAppPurchase(
            id: "iap-9", state: .inReview, submitWithNextAppStoreVersion: true
        )
        #expect(inReview.affordances["removeFromNextVersion"] == nil)
    }

    @Test func `iap defaults submitWithNextAppStoreVersion to false`() {
        let iap = MockRepositoryFactory.makeInAppPurchase(id: "iap-1", state: .readyToSubmit)
        #expect(iap.submitWithNextAppStoreVersion == false)
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
