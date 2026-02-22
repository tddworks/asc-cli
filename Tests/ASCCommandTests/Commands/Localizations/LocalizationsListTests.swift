import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct LocalizationsListTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v-1", locale: "en-US"),
            AppStoreVersionLocalization(id: "loc-2", versionId: "v-1", locale: "zh-Hans"),
        ])

        let cmd = try LocalizationsList.parse(["--version-id", "v-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-1",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-1"
              },
              "id" : "loc-1",
              "locale" : "en-US",
              "versionId" : "v-1"
            },
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-1",
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-2"
              },
              "id" : "loc-2",
              "locale" : "zh-Hans",
              "versionId" : "v-1"
            }
          ]
        }
        """)
    }

    @Test func `execute passes versionId to repository`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listLocalizations(versionId: .value("v-42")).willReturn([])

        let cmd = try LocalizationsList.parse(["--version-id", "v-42"])
        _ = try await cmd.execute(repo: mockRepo)
    }
}
