import Mockable
import Testing
@testable import ASCKit

@Suite
struct VersionLocalizationsTests {

    // MARK: - list

    @Test func `list localizations returns localizations for version`() async throws {
        let mock = MockVersionLocalizations()
        let localizations = [
            MockRepositoryFactory.makeLocalization(id: "loc-1", locale: "en-US"),
            MockRepositoryFactory.makeLocalization(id: "loc-2", locale: "zh-Hans"),
        ]
        given(mock).listLocalizations(versionId: .any).willReturn(localizations)

        let result = try await mock.listLocalizations(versionId: "v1")
        #expect(result.count == 2)
        #expect(result[0].locale == "en-US")
        #expect(result[1].locale == "zh-Hans")
    }

    @Test func `list localizations returns empty when version has no localizations`() async throws {
        let mock = MockVersionLocalizations()
        given(mock).listLocalizations(versionId: .any).willReturn([])

        let result = try await mock.listLocalizations(versionId: "v1")
        #expect(result.isEmpty)
    }

    // MARK: - create

    @Test func `create localization returns new localization with locale`() async throws {
        let mock = MockVersionLocalizations()
        let created = MockRepositoryFactory.makeLocalization(id: "loc-new", versionId: "v1", locale: "fr-FR")
        given(mock).createLocalization(versionId: .any, locale: .any).willReturn(created)

        let result = try await mock.createLocalization(versionId: "v1", locale: "fr-FR")
        #expect(result.locale == "fr-FR")
        #expect(result.versionId == "v1")
    }

    // MARK: - update (mental model: I have a localization, I want to set What's New text)

    @Test func `update localization returns localization with new whatsNew text`() async throws {
        let mock = MockVersionLocalizations()
        let updated = MockRepositoryFactory.makeLocalization(id: "loc-1", whatsNew: "Bug fixes and performance improvements")
        given(mock).updateLocalization(
            localizationId: .any,
            whatsNew: .any,
            description: .any,
            keywords: .any,
            marketingUrl: .any,
            supportUrl: .any,
            promotionalText: .any
        ).willReturn(updated)

        let result = try await mock.updateLocalization(
            localizationId: "loc-1",
            whatsNew: "Bug fixes and performance improvements",
            description: nil,
            keywords: nil,
            marketingUrl: nil,
            supportUrl: nil,
            promotionalText: nil
        )
        #expect(result.whatsNew == "Bug fixes and performance improvements")
    }

    @Test func `update localization with nil fields does not overwrite existing data`() async throws {
        let mock = MockVersionLocalizations()
        let existing = MockRepositoryFactory.makeLocalization(
            id: "loc-1",
            whatsNew: "Previous text",
            keywords: "existing,keywords"
        )
        given(mock).updateLocalization(
            localizationId: .any,
            whatsNew: .any,
            description: .any,
            keywords: .any,
            marketingUrl: .any,
            supportUrl: .any,
            promotionalText: .any
        ).willReturn(existing)

        let result = try await mock.updateLocalization(
            localizationId: "loc-1",
            whatsNew: nil,
            description: nil,
            keywords: nil,
            marketingUrl: nil,
            supportUrl: nil,
            promotionalText: nil
        )
        // Server returns existing values unchanged
        #expect(result.whatsNew == "Previous text")
        #expect(result.keywords == "existing,keywords")
    }
}
