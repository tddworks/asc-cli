import Testing
@testable import Domain

@Suite
struct SubscriptionGroupLocalizationTests {

    @Test func `localization carries groupId`() {
        let loc = SubscriptionGroupLocalization(id: "loc-1", groupId: "grp-1", locale: "en-US", name: "Premium")
        #expect(loc.groupId == "grp-1")
    }

    @Test func `affordances include listSiblings`() {
        let loc = SubscriptionGroupLocalization(id: "loc-1", groupId: "grp-1", locale: "en-US", name: "Premium")
        #expect(loc.affordances["listSiblings"] == "asc subscription-group-localizations list --group-id grp-1")
    }

    @Test func `affordances include update with localization id`() {
        let loc = SubscriptionGroupLocalization(id: "loc-1", groupId: "grp-1", locale: "en-US")
        #expect(loc.affordances["update"] == "asc subscription-group-localizations update --localization-id loc-1 --name <name>")
    }

    @Test func `affordances include delete with localization id`() {
        let loc = SubscriptionGroupLocalization(id: "loc-1", groupId: "grp-1", locale: "en-US")
        #expect(loc.affordances["delete"] == "asc subscription-group-localizations delete --localization-id loc-1")
    }
}
