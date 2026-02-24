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
        #expect(loc.affordances["updateLocalization"] == "asc localizations update --localization-id loc-1")
    }

    @Test func `localization affordances include listScreenshotSets command`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
        #expect(loc.affordances["listScreenshotSets"] == "asc screenshot-sets list --localization-id loc-1")
    }

    @Test func `localization affordances include listLocalizations command`() {
        let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
        #expect(loc.affordances["listLocalizations"] == "asc localizations list --version-id v-1")
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
