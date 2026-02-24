import Testing
@testable import Domain

@Suite
struct AppInfoLocalizationTests {

    @Test func `localization carries appInfoId`() {
        let loc = AppInfoLocalization(id: "loc-1", appInfoId: "info-42", locale: "en-US")
        #expect(loc.appInfoId == "info-42")
    }

    @Test func `localization carries locale`() {
        let loc = AppInfoLocalization(id: "loc-1", appInfoId: "info-1", locale: "zh-Hans")
        #expect(loc.locale == "zh-Hans")
    }

    @Test func `localization optional fields default to nil`() {
        let loc = AppInfoLocalization(id: "loc-1", appInfoId: "info-1", locale: "en-US")
        #expect(loc.name == nil)
        #expect(loc.subtitle == nil)
        #expect(loc.privacyPolicyUrl == nil)
        #expect(loc.privacyChoicesUrl == nil)
        #expect(loc.privacyPolicyText == nil)
    }

    @Test func `localization stores name and subtitle`() {
        let loc = AppInfoLocalization(
            id: "loc-1",
            appInfoId: "info-1",
            locale: "en-US",
            name: "My App",
            subtitle: "Do things faster"
        )
        #expect(loc.name == "My App")
        #expect(loc.subtitle == "Do things faster")
    }

    @Test func `localization affordances include listLocalizations command`() {
        let loc = AppInfoLocalization(id: "loc-1", appInfoId: "info-42", locale: "en-US")
        #expect(loc.affordances["listLocalizations"] == "asc app-info-localizations list --app-info-id info-42")
    }

    @Test func `localization affordances include updateLocalization command`() {
        let loc = AppInfoLocalization(id: "loc-1", appInfoId: "info-42", locale: "en-US")
        #expect(loc.affordances["updateLocalization"] == "asc app-info-localizations update --localization-id loc-1")
    }
}
