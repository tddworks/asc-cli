import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionLocalizationsListTests {

    @Test func `listed localizations include affordances for navigation`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v-1", locale: "en-US"),
            AppStoreVersionLocalization(id: "loc-2", versionId: "v-1", locale: "zh-Hans"),
        ])

        let cmd = try VersionLocalizationsList.parse(["--version-id", "v-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc version-localizations list --version-id v-1",
                "listPlacements" : "asc asset-placements list --localization-id loc-1",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-1",
                "updateLocalization" : "asc version-localizations update --localization-id loc-1"
              },
              "id" : "loc-1",
              "locale" : "en-US",
              "versionId" : "v-1"
            },
            {
              "affordances" : {
                "listLocalizations" : "asc version-localizations list --version-id v-1",
                "listPlacements" : "asc asset-placements list --localization-id loc-2",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-2",
                "updateLocalization" : "asc version-localizations update --localization-id loc-2"
              },
              "id" : "loc-2",
              "locale" : "zh-Hans",
              "versionId" : "v-1"
            }
          ]
        }
        """)
    }
}
