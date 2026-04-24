import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsUpdateTests {

    @Test func `updated version returns new version string with editable affordances`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).updateVersion(id: .any, versionString: .any).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-7", versionString: "2.5.0", platform: .iOS, state: .prepareForSubmission)
        )

        let cmd = try VersionsUpdate.parse(["--version-id", "v-1", "--version", "2.5.0", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-1",
                "getReviewDetail" : "asc version-review-detail get --version-id v-1",
                "listLocalizations" : "asc version-localizations list --version-id v-1",
                "listVersions" : "asc versions list --app-id app-7",
                "submitForReview" : "asc versions submit --version-id v-1",
                "updateVersion" : "asc versions update --version-id v-1"
              },
              "appId" : "app-7",
              "id" : "v-1",
              "platform" : "IOS",
              "state" : "PREPARE_FOR_SUBMISSION",
              "versionString" : "2.5.0"
            }
          ]
        }
        """)
    }
}
