import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewSubmissionsGetTests {

    @Test func `get submission shows id, appId, state, and affordances`() async throws {
        let mockRepo = MockSubmissionRepository()
        given(mockRepo).getSubmission(id: .value("sub-1")).willReturn(
            ReviewSubmission(id: "sub-1", appId: "app-42", platform: .iOS, state: .unresolvedIssues)
        )

        let cmd = try ReviewSubmissionsGet.parse(["--submission-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc review-submissions get --submission-id sub-1",
                "listItems" : "asc review-submissions items list --submission-id sub-1",
                "listRejectedItems" : "asc review-submissions items list --state REJECTED --submission-id sub-1",
                "listVersions" : "asc versions list --app-id app-42"
              },
              "appId" : "app-42",
              "id" : "sub-1",
              "platform" : "IOS",
              "state" : "UNRESOLVED_ISSUES"
            }
          ]
        }
        """)
    }
}
