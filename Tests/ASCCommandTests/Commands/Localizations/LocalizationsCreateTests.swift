import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct LocalizationsCreateTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockScreenshotRepository()
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
                "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-new"
              },
              "id" : "loc-new",
              "locale" : "en-US",
              "versionId" : "v-1"
            }
          ]
        }
        """)
    }

    @Test func `execute passes correct arguments to repository`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).createLocalization(versionId: .value("v-99"), locale: .value("zh-Hans")).willReturn(
            AppStoreVersionLocalization(id: "loc-1", versionId: "v-99", locale: "zh-Hans")
        )

        let cmd = try LocalizationsCreate.parse(["--version-id", "v-99", "--locale", "zh-Hans"])
        _ = try await cmd.execute(repo: mockRepo)
    }
}
