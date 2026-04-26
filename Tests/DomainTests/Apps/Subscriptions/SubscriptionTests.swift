import Testing
@testable import Domain

@Suite
struct SubscriptionTests {

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
        #expect(group.affordances["createSubscription"] == "asc subscriptions create --group-id grp-1 --name <name> --product-id <id> --period ONE_MONTH")
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
        #expect(sub.affordances["createLocalization"] == "asc subscription-localizations create --subscription-id sub-1 --locale en-US --name <name>")
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

    @Test func `subscription affordances include update with subscription id`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["update"] == "asc subscriptions update --subscription-id sub-1 --name <name>")
    }

    @Test func `subscription affordances include delete with subscription id`() {
        let sub = MockRepositoryFactory.makeSubscription(id: "sub-1")
        #expect(sub.affordances["delete"] == "asc subscriptions delete --subscription-id sub-1")
    }
}
