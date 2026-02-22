import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsCreateTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).createVersion(appId: .any, versionString: .any, platform: .any).willReturn(
            AppStoreVersion(id: "v-new", appId: "app-1", versionString: "2.0.0", platform: .iOS, state: .prepareForSubmission)
        )

        let cmd = try VersionsCreate.parse(["--app-id", "app-1", "--version", "2.0.0", "--platform", "ios", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc localizations list --version-id v-new",
                "listVersions" : "asc versions list --app-id app-1",
                "submitForReview" : "asc versions submit --version-id v-new"
              },
              "appId" : "app-1",
              "id" : "v-new",
              "platform" : "IOS",
              "state" : "PREPARE_FOR_SUBMISSION",
              "versionString" : "2.0.0"
            }
          ]
        }
        """)
    }

    @Test func `execute passes correct arguments to repository`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).createVersion(appId: .value("app-42"), versionString: .value("3.1.0"), platform: .value(.macOS)).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-42", versionString: "3.1.0", platform: .macOS, state: .prepareForSubmission)
        )

        let cmd = try VersionsCreate.parse(["--app-id", "app-42", "--version", "3.1.0", "--platform", "macos"])
        _ = try await cmd.execute(repo: mockRepo)
    }
}
