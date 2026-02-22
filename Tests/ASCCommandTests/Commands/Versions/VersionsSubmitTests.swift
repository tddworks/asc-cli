import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsSubmitTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).submitVersion(versionId: .any).willReturn(
            ReviewSubmission(
                id: "sub-1",
                appId: "app-42",
                platform: .iOS,
                state: .waitingForReview
            )
        )

        let cmd = try VersionsSubmit.parse(["--version-id", "v-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listVersions" : "asc versions list --app-id app-42"
              },
              "appId" : "app-42",
              "id" : "sub-1",
              "platform" : "IOS",
              "state" : "WAITING_FOR_REVIEW"
            }
          ]
        }
        """)
    }
}
