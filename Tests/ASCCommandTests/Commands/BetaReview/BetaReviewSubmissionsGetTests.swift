import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BetaReviewSubmissionsGetTests {

    @Test func `get submission shows details with affordances`() async throws {
        let mockRepo = MockBetaAppReviews()
        given(mockRepo).getSubmission(id: .value("sub-1"))
            .willReturn(
                BetaAppReviewSubmission(id: "sub-1", buildId: "build-42", state: .approved)
            )

        let cmd = try BetaReviewSubmissionsGet.parse(["--submission-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc beta-review submissions get --submission-id sub-1",
                "listSubmissions" : "asc beta-review submissions list --build-id build-42"
              },
              "buildId" : "build-42",
              "id" : "sub-1",
              "state" : "APPROVED"
            }
          ]
        }
        """)
    }
}
