import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BetaReviewSubmissionsListTests {

    @Test func `listed submissions show id, buildId, state, and affordances`() async throws {
        let mockRepo = MockBetaAppReviews()
        given(mockRepo).listSubmissions(buildId: .value("build-1"))
            .willReturn([
                BetaAppReviewSubmission(id: "sub-1", buildId: "build-1", state: .waitingForReview),
            ])

        let cmd = try BetaReviewSubmissionsList.parse(["--build-id", "build-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getSubmission" : "asc beta-review submissions get --submission-id sub-1",
                "listSubmissions" : "asc beta-review submissions list --build-id build-1"
              },
              "buildId" : "build-1",
              "id" : "sub-1",
              "state" : "WAITING_FOR_REVIEW"
            }
          ]
        }
        """)
    }

    @Test func `listed submissions show approved state`() async throws {
        let mockRepo = MockBetaAppReviews()
        given(mockRepo).listSubmissions(buildId: .value("build-1"))
            .willReturn([
                BetaAppReviewSubmission(id: "sub-1", buildId: "build-1", state: .approved),
            ])

        let cmd = try BetaReviewSubmissionsList.parse(["--build-id", "build-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"APPROVED\""))
    }
}
