import Foundation
import Testing
@testable import Domain

@Suite
struct AppStoreVersionLocalizationTests {

    @Test func `localization carries versionId`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-99")
        #expect(loc.versionId == "v-99")
    }

    @Test func `localization carries whatsNew when provided`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", whatsNew: "Bug fixes and improvements")
        #expect(loc.whatsNew == "Bug fixes and improvements")
    }

    @Test func `localization whatsNew is nil by default`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1")
        #expect(loc.whatsNew == nil)
    }

    @Test func `localization carries description when provided`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", description: "A great app")
        #expect(loc.description == "A great app")
    }

    @Test func `localization affordances include updateLocalization command`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
        #expect(loc.affordances["updateLocalization"] == "asc version-localizations update --localization-id loc-1")
    }

    @Test func `localization affordances include listScreenshotSets command`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
        #expect(loc.affordances["listScreenshotSets"] == "asc screenshot-sets list --localization-id loc-1")
    }

    @Test func `localization affordances include listLocalizations command`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
        #expect(loc.affordances["listLocalizations"] == "asc version-localizations list --version-id v-1")
    }

    @Test func `nil optional fields are omitted from JSON`() throws {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
        let json = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(loc)
        ) as! [String: Any]
        #expect(json["whatsNew"] == nil)
        #expect(json["description"] == nil)
        #expect(json["keywords"] == nil)
        #expect(json["marketingUrl"] == nil)
        #expect(json["supportUrl"] == nil)
        #expect(json["promotionalText"] == nil)
    }

    @Test func `localization table headers include locale and description`() {
        #expect(AppStoreVersionLocalization.tableHeaders == ["ID", "Locale", "Description", "Keywords"])
    }

    @Test func `localization table row shows locale and truncated description`() {
        let loc = MockRepositoryFactory.makeLocalization(
            id: "loc-1", locale: "en-US", description: "A great app"
        )
        #expect(loc.tableRow == ["loc-1", "en-US", "A great app", ""])
    }

    @Test func `localization apiLinks include listScreenshotSets under this localization`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
        let link = loc.apiLinks["listScreenshotSets"]
        #expect(link?.href == "/api/v1/version-localizations/loc-1/screenshot-sets")
        #expect(link?.method == "GET")
    }

    @Test func `localization round trips through JSON`() throws {
        let original = MockRepositoryFactory.makeLocalization(
            id: "loc-1",
            versionId: "v-1",
            whatsNew: "New features",
            description: "A great app",
            keywords: "app, tools",
            marketingUrl: "https://example.com",
            supportUrl: "https://support.example.com",
            promotionalText: "Try it free"
        )
        let decoded = try JSONDecoder().decode(
            AppStoreVersionLocalization.self,
            from: JSONEncoder().encode(original)
        )
        #expect(decoded == original)
    }
}
