import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct LocalizationsCreateTests {

    @Test func `created localization is returned with affordances`() async throws {
        let mockRepo = MockVersionLocalizationRepository()
        given(mockRepo).createLocalization(versionId: .any, locale: .any).willReturn(
            AppStoreVersionLocalization(id: "loc-new", versionId: "v-1", locale: "en-US")
        )

        let cmd = try LocalizationsCreate.parse(["--version-id", "v-1", "--locale", "en-US", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-1",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-new",
                "updateLocalization" : "asc localizations update --localization-id loc-new"
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

        let cmd = try LocalizationsCreate.parse(["--version-id", "v-99", "--locale", "zh-Hans", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-99",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-new",
                "updateLocalization" : "asc localizations update --localization-id loc-new"
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
