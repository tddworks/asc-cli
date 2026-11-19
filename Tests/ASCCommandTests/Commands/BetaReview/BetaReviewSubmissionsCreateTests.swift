import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BetaReviewSubmissionsCreateTests {

    @Test func `created submission shows waiting for review state`() async throws {
        let mockRepo = MockBetaAppReviews()
        given(mockRepo).createSubmission(buildId: .value("build-1"))
            .willReturn(
                BetaAppReviewSubmission(id: "sub-new", buildId: "build-1", state: .waitingForReview)
            )

        let cmd = try BetaReviewSubmissionsCreate.parse(["--build-id", "build-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc beta-review submissions get --submission-id sub-new",
                "listSubmissions" : "asc beta-review submissions list --build-id build-1"
              },
              "buildId" : "build-1",
              "id" : "sub-new",
              "state" : "WAITING_FOR_REVIEW"
            }
          ]
        }
        """)
    }
}
