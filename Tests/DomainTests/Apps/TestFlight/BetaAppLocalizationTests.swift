import Foundation
import Testing
@testable import Domain

@Suite
struct BetaAppLocalizationTests {

    @Test func `beta app localization carries appId`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-99")
        #expect(loc.appId == "app-99")
    }

    @Test func `beta app localization carries locale and description`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(
            id: "bal-1",
            appId: "app-1",
            locale: "en-US",
            description: "Welcome to the beta — please test the new dashboard."
        )
        #expect(loc.locale == "en-US")
        #expect(loc.description == "Welcome to the beta — please test the new dashboard.")
    }

    @Test func `beta app localization carries optional contact and marketing fields`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(
            id: "bal-1",
            appId: "app-1",
            feedbackEmail: "beta@example.com",
            marketingUrl: "https://example.com",
            privacyPolicyUrl: "https://example.com/privacy",
            tvOsPrivacyPolicy: "tvOS-specific privacy"
        )
        #expect(loc.feedbackEmail == "beta@example.com")
        #expect(loc.marketingUrl == "https://example.com")
        #expect(loc.privacyPolicyUrl == "https://example.com/privacy")
        #expect(loc.tvOsPrivacyPolicy == "tvOS-specific privacy")
    }

    @Test func `beta app localization affordances include update command`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-1")
        #expect(loc.affordances["update"] == "asc beta-app-localizations update --localization-id bal-1")
    }

    @Test func `beta app localization affordances include delete command`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-1")
        #expect(loc.affordances["delete"] == "asc beta-app-localizations delete --localization-id bal-1")
    }

    @Test func `beta app localization affordances include listSiblings command`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-7")
        #expect(loc.affordances["listSiblings"] == "asc beta-app-localizations list --app-id app-7")
    }

    @Test func `beta app localization apiLinks include listSiblings under parent app`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-7")
        let link = loc.apiLinks["listSiblings"]
        #expect(link?.href == "/api/v1/apps/app-7/beta-app-localizations")
        #expect(link?.method == "GET")
    }

    @Test func `beta app localization apiLinks include update on the localization itself`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-1")
        let link = loc.apiLinks["update"]
        #expect(link?.href == "/api/v1/beta-app-localizations/bal-1")
        #expect(link?.method == "PATCH")
    }

    @Test func `beta app localization table headers include locale and description`() {
        #expect(BetaAppLocalization.tableHeaders == ["ID", "Locale", "Description", "Feedback Email"])
    }

    @Test func `beta app localization table row shows locale and feedback email`() {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(
            id: "bal-1",
            locale: "en-US",
            description: "Beta description",
            feedbackEmail: "beta@example.com"
        )
        #expect(loc.tableRow == ["bal-1", "en-US", "Beta description", "beta@example.com"])
    }

    @Test func `nil optional fields are omitted from JSON`() throws {
        let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-1", locale: "en-US")
        let json = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(loc)
        ) as! [String: Any]
        #expect(json["description"] == nil)
        #expect(json["feedbackEmail"] == nil)
        #expect(json["marketingUrl"] == nil)
        #expect(json["privacyPolicyUrl"] == nil)
        #expect(json["tvOsPrivacyPolicy"] == nil)
    }

    @Test func `beta app localization round trips through JSON`() throws {
        let original = MockRepositoryFactory.makeBetaAppLocalization(
            id: "bal-1",
            appId: "app-1",
            locale: "en-US",
            description: "Beta desc",
            feedbackEmail: "beta@example.com",
            marketingUrl: "https://example.com",
            privacyPolicyUrl: "https://example.com/privacy",
            tvOsPrivacyPolicy: "tvOS privacy"
        )
        let decoded = try JSONDecoder().decode(
            BetaAppLocalization.self,
            from: JSONEncoder().encode(original)
        )
        #expect(decoded == original)
    }
}
