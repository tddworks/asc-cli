import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsCreateTests {

    @Test func `created iOS version is returned in prepare for submission state`() async throws {
        let mockRepo = MockVersionRepository()
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
                "checkReadiness" : "asc versions check-readiness --version-id v-new",
                "getReviewDetail" : "asc version-review-detail get --version-id v-new",
                "listLocalizations" : "asc version-localizations list --version-id v-new",
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

    @Test func `created macOS version returns version with macOS platform`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).createVersion(appId: .any, versionString: .any, platform: .any).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-42", versionString: "3.1.0", platform: .macOS, state: .prepareForSubmission)
        )

        let cmd = try VersionsCreate.parse(["--app-id", "app-42", "--version", "3.1.0", "--platform", "macos", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-1",
                "getReviewDetail" : "asc version-review-detail get --version-id v-1",
                "listLocalizations" : "asc version-localizations list --version-id v-1",
                "listVersions" : "asc versions list --app-id app-42",
                "submitForReview" : "asc versions submit --version-id v-1"
              },
              "appId" : "app-42",
              "id" : "v-1",
              "platform" : "MAC_OS",
              "state" : "PREPARE_FOR_SUBMISSION",
              "versionString" : "3.1.0"
            }
          ]
        }
        """)
    }
}
