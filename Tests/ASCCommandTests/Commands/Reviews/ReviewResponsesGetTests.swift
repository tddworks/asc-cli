import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewResponsesGetTests {

    @Test func `get response shows response body state and affordances`() async throws {
        let mockRepo = MockCustomerReviewRepository()
        given(mockRepo).getResponse(reviewId: .any).willReturn(
            CustomerReviewResponse(
                id: "resp-1",
                reviewId: "rev-42",
                responseBody: "Thanks for your feedback!",
                state: .published
            )
        )

        let cmd = try ReviewResponsesGet.parse(["--review-id", "rev-42", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc review-responses delete --response-id resp-1",
                "getReview" : "asc reviews get --review-id rev-42"
              },
              "id" : "resp-1",
              "responseBody" : "Thanks for your feedback!",
              "reviewId" : "rev-42",
              "state" : "PUBLISHED"
            }
          ]
        }
        """)
    }
}
