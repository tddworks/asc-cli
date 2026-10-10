import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionLocalizationsCreateTests {

    @Test func `created localization is returned with affordances`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).createLocalization(versionId: .any, locale: .any).willReturn(
            AppStoreVersionLocalization(id: "loc-new", versionId: "v-1", locale: "en-US")
        )

        let cmd = try VersionLocalizationsCreate.parse(["--version-id", "v-1", "--locale", "en-US", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc version-localizations list --version-id v-1",
                "listPlacements" : "asc asset-placements list --localization-id loc-new",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-new",
                "updateLocalization" : "asc version-localizations update --localization-id loc-new"
              },
              "id" : "loc-new",
              "locale" : "en-US",
              "versionId" : "v-1"
            }
          ]
        }
        """)
    }

    @Test func `created zh-Hans localization returns correct locale`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).createLocalization(versionId: .any, locale: .any).willReturn(
            AppStoreVersionLocalization(id: "loc-new", versionId: "v-99", locale: "zh-Hans")
        )

        let cmd = try VersionLocalizationsCreate.parse(["--version-id", "v-99", "--locale", "zh-Hans", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc version-localizations list --version-id v-99",
                "listPlacements" : "asc asset-placements list --localization-id loc-new",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-new",
                "updateLocalization" : "asc version-localizations update --localization-id loc-new"
              },
              "id" : "loc-new",
              "locale" : "zh-Hans",
              "versionId" : "v-99"
            }
          ]
        }
        """)
    }
}
