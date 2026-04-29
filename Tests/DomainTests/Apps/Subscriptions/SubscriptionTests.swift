import Foundation
import Testing
@testable import Domain

@Suite
struct SubscriptionTests {

    // MARK: - Review note (read-side)

    @Test func `subscription carries reviewNote when set`() {
        let sub = MockRepositoryFactory.makeSubscription(reviewNote: "Use code TEST")
        #expect(sub.reviewNote == "Use code TEST")
    }

    @Test func `subscription reviewNote is nil by default`() {
        let sub = MockRepositoryFactory.makeSubscription()
        #expect(sub.reviewNote == nil)
    }

    @Test func `subscription with nil reviewNote omits it from JSON`() throws {
        let sub = MockRepositoryFactory.makeSubscription(reviewNote: nil)
        let json = String(decoding: try JSONEncoder().encode(sub), as: UTF8.self)
        #expect(!json.contains("reviewNote"))
    }

    @Test func `subscription with reviewNote encodes it in JSON`() throws {
        let sub = MockRepositoryFactory.makeSubscription(reviewNote: "Use code TEST")
        let json = String(decoding: try JSONEncoder().encode(sub), as: UTF8.self)
        #expect(json.contains("\"reviewNote\":\"Use code TEST\""))
    }

    @Test func `subscription roundtrips reviewNote through Codable`() throws {
        let sub = MockRepositoryFactory.makeSubscription(reviewNote: "Use code TEST")
        let data = try JSONEncoder().encode(sub)
        let decoded = try JSONDecoder().decode(Subscription.self, from: data)
        #expect(decoded.reviewNote == "Use code TEST")
    }

    @Test func `subscription group carries appId`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1", appId: "app-1")
        #expect(group.appId == "app-1")
        #expect(group.referenceName == "Premium Plans")
    }

    @Test func `subscription group affordances include listSubscriptions`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
        #expect(group.affordances["listSubscriptions"] == "asc subscriptions list --group-id grp-1")
    }

    @Test func `subscription group affordances include createSubscription`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
        #expect(group.affordances["createSubscription"] == "asc subscriptions create --group-id grp-1 --name <name> --period ONE_MONTH --product-id <id>")
    }

    @Test func `subscription group apiLinks include listSubscriptions under nested parent`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
        #expect(group.apiLinks["listSubscriptions"]?.href == "/api/v1/subscription-groups/grp-1/subscriptions")
        #expect(group.apiLinks["listSubscriptions"]?.method == "GET")
    }

    @Test func `subscription group apiLinks include listLocalizations under nested parent`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
        #expect(group.apiLinks["listLocalizations"]?.href == "/api/v1/subscription-groups/grp-1/subscription-group-localizations")
    }

    @Test func `subscription group apiLinks include update and delete on flat resource`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
        #expect(group.apiLinks["update"]?.href == "/api/v1/subscription-groups/grp-1")
        #expect(group.apiLinks["update"]?.method == "PATCH")
        #expect(group.apiLinks["delete"]?.href == "/api/v1/subscription-groups/grp-1")
        #expect(group.apiLinks["delete"]?.method == "DELETE")
    }

    @Test func `subscription group affordances include update with group id`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
        #expect(group.affordances["update"] == "asc subscription-groups update --group-id grp-1 --reference-name <name>")
    }

    @Test func `subscription group affordances include delete with group id`() {
        let group = MockRepositoryFactory.makeSubscriptionGroup(id: "grp-1")
        #expect(group.affordances["delete"] == "asc subscription-groups delete --group-id grp-1")
    }

    @Test func `subscription carries groupId`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1", groupId: "grp-1")
        #expect(sub.groupId == "grp-1")
    }

    @Test func `subscription state isEditable for missingMetadata`() {
        let sub = MockRepositoryFactory.makeSubscription(state: .missingMetadata)
        #expect(sub.state.isEditable == true)
        #expect(sub.state.isApproved == false)
    }

    @Test func `subscription state isApproved for approved`() {
        let sub = MockRepositoryFactory.makeSubscription(state: .approved)
        #expect(sub.state.isApproved == true)
        #expect(sub.state.isLive == true)
        #expect(sub.state.isEditable == false)
    }

    @Test func `subscription affordances include listLocalizations`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["listLocalizations"] == "asc subscription-localizations list --subscription-id sub-1")
    }

    @Test func `subscription affordances include createLocalization`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["createLocalization"] == "asc subscription-localizations create --locale en-US --name <name> --subscription-id sub-1")
    }

    @Test func `subscription localization affordances include listSiblings`() {
        let loc = MockRepositoryFactory.makeSubscriptionLocalization(id: "loc-1", subscriptionId: "sub-1")
        #expect(loc.affordances["listSiblings"] == "asc subscription-localizations list --subscription-id sub-1")
    }

    @Test func `subscription localization affordances include update with localization id`() {
        let loc = MockRepositoryFactory.makeSubscriptionLocalization(id: "loc-1", subscriptionId: "sub-1")
        #expect(loc.affordances["update"] == "asc subscription-localizations update --localization-id loc-1 --name <name>")
    }

    @Test func `subscription localization affordances include delete with localization id`() {
        let loc = MockRepositoryFactory.makeSubscriptionLocalization(id: "loc-1", subscriptionId: "sub-1")
        #expect(loc.affordances["delete"] == "asc subscription-localizations delete --localization-id loc-1")
    }

    @Test func `subscription period displayName`() {
        #expect(SubscriptionPeriod.oneWeek.displayName == "1 Week")
        #expect(SubscriptionPeriod.oneMonth.displayName == "1 Month")
        #expect(SubscriptionPeriod.oneYear.displayName == "1 Year")
    }

    @Test func `subscription groupLevel is nil by default`() {
        let sub = MockRepositoryFactory.makeSubscription()
        #expect(sub.groupLevel == nil)
    }

    @Test func `subscription with groupLevel encodes it`() {
        let sub = MockRepositoryFactory.makeSubscription(groupLevel: 1)
        #expect(sub.groupLevel == 1)
    }

    @Test func `subscription affordances include listOfferCodes`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["listOfferCodes"] == "asc subscription-offer-codes list --subscription-id sub-1")
    }

    @Test func `subscription affordances include createOfferCode`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["createOfferCode"] != nil)
        #expect(sub.affordances["createOfferCode"]!.contains("asc subscription-offer-codes create"))
        #expect(sub.affordances["createOfferCode"]!.contains("--subscription-id sub-1"))
    }

    @Test func `subscription apiLinks include createOfferCode as POST under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["createOfferCode"]?.href == "/api/v1/subscriptions/sub-1/offer-codes")
        #expect(sub.apiLinks["createOfferCode"]?.method == "POST")
    }

    @Test func `subscription affordances include update with subscription id`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["update"] == "asc subscriptions update --name <name> --subscription-id sub-1")
    }

    @Test func `subscription affordances include delete with subscription id`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["delete"] == "asc subscriptions delete --subscription-id sub-1")
    }

    // MARK: - REST navigation links (HATEOAS)

    @Test func `subscription apiLinks include listLocalizations under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["listLocalizations"]?.href == "/api/v1/subscriptions/sub-1/localizations")
        #expect(sub.apiLinks["listLocalizations"]?.method == "GET")
    }

    @Test func `subscription apiLinks include listIntroductoryOffers under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["listIntroductoryOffers"]?.href == "/api/v1/subscriptions/sub-1/introductory-offers")
        #expect(sub.apiLinks["listIntroductoryOffers"]?.method == "GET")
    }

    @Test func `subscription apiLinks include listOfferCodes under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["listOfferCodes"]?.href == "/api/v1/subscriptions/sub-1/offer-codes")
        #expect(sub.apiLinks["listOfferCodes"]?.method == "GET")
    }

    @Test func `subscription apiLinks include listPromotionalOffers under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["listPromotionalOffers"]?.href == "/api/v1/subscriptions/sub-1/subscription-promotional-offers")
        #expect(sub.apiLinks["listPromotionalOffers"]?.method == "GET")
    }

    @Test func `subscription apiLinks include listWinBackOffers under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["listWinBackOffers"]?.href == "/api/v1/subscriptions/sub-1/win-back-offers")
        #expect(sub.apiLinks["listWinBackOffers"]?.method == "GET")
    }

    @Test func `subscription apiLinks include getAvailability under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["getAvailability"]?.href == "/api/v1/subscriptions/sub-1/availability")
        #expect(sub.apiLinks["getAvailability"]?.method == "GET")
    }

    @Test func `subscription apiLinks include getReviewScreenshot under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["getReviewScreenshot"]?.href == "/api/v1/subscriptions/sub-1/review-screenshot")
        #expect(sub.apiLinks["getReviewScreenshot"]?.method == "GET")
    }

    @Test func `subscription apiLinks include listPricePoints under nested parent`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["listPricePoints"]?.href == "/api/v1/subscriptions/sub-1/price-points")
        #expect(sub.apiLinks["listPricePoints"]?.method == "GET")
    }

    @Test func `subscription apiLinks include update and delete on flat resource`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["update"]?.href == "/api/v1/subscriptions/sub-1")
        #expect(sub.apiLinks["update"]?.method == "PATCH")
        #expect(sub.apiLinks["delete"]?.href == "/api/v1/subscriptions/sub-1")
        #expect(sub.apiLinks["delete"]?.method == "DELETE")
    }

    @Test func `subscription affordances include setPrices batch with placeholders`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["setPrices"] == "asc subscriptions prices set-batch --price <territory>=<price-point-id> --subscription-id sub-1")
    }

    @Test func `subscription apiLinks include setPrices posting to nested prices endpoint`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.apiLinks["setPrices"]?.href == "/api/v1/subscriptions/sub-1/prices/set-batch")
        #expect(sub.apiLinks["setPrices"]?.method == "POST")
    }

    @Test func `subscription apiLinks include submit only when readyToSubmit`() {
        let ready = MockRepositoryFactory.makeSubscription(id: "sub-1", state: .readyToSubmit)
        let missing = MockRepositoryFactory.makeSubscription(id: "sub-2", state: .missingMetadata)
        #expect(ready.apiLinks["submit"]?.href == "/api/v1/subscriptions/sub-1/submit")
        #expect(ready.apiLinks["submit"]?.method == "POST")
        #expect(missing.apiLinks["submit"] == nil)
    }
}
