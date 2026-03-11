import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewsGetTests {

    @Test func `get review shows full review details with affordances`() async throws {
        let mockRepo = MockCustomerReviewRepository()
        given(mockRepo).getReview(reviewId: .any).willReturn(
            CustomerReview(
                id: "rev-1",
                appId: "",
                rating: 4,
                title: "Good",
                body: "Nice app",
                reviewerNickname: "reviewer1",
                territory: "GBR"
            )
        )

        let cmd = try ReviewsGet.parse(["--review-id", "rev-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getResponse" : "asc review-responses get --review-id rev-1",
                "listReviews" : "asc reviews list --app-id ",
                "respond" : "asc review-responses create --review-id rev-1 --response-body \\\"\\\""
              },
              "appId" : "",
              "body" : "Nice app",
              "id" : "rev-1",
              "rating" : 4,
              "reviewerNickname" : "reviewer1",
              "territory" : "GBR",
              "title" : "Good"
            }
          ]
        }
        """)
    }
}
