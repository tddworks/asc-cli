import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewResponsesCreateTests {

    @Test func `create response returns new response with pending state`() async throws {
        let mockRepo = MockCustomerReviewRepository()
        given(mockRepo).createResponse(reviewId: .any, responseBody: .any).willReturn(
            CustomerReviewResponse(
                id: "resp-new",
                reviewId: "rev-42",
                responseBody: "Thank you!",
                state: .pendingPublish
            )
        )

        let cmd = try ReviewResponsesCreate.parse(["--review-id", "rev-42", "--response-body", "Thank you!", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc review-responses delete --response-id resp-new",
                "getReview" : "asc reviews get --review-id rev-42"
              },
              "id" : "resp-new",
              "responseBody" : "Thank you!",
              "reviewId" : "rev-42",
              "state" : "PENDING_PUBLISH"
            }
          ]
        }
        """)
    }
}
