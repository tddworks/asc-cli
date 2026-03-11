import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ReviewsListTests {

    @Test func `listed reviews include rating territory and affordances`() async throws {
        let mockRepo = MockCustomerReviewRepository()
        given(mockRepo).listReviews(appId: .any).willReturn([
            CustomerReview(
                id: "rev-1",
                appId: "app-1",
                rating: 5,
                title: "Amazing",
                reviewerNickname: "user42",
                territory: "USA"
            ),
        ])

        let cmd = try ReviewsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getResponse" : "asc review-responses get --review-id rev-1",
                "listReviews" : "asc reviews list --app-id app-1",
                "respond" : "asc review-responses create --review-id rev-1 --response-body \\\"\\\""
              },
              "appId" : "app-1",
              "id" : "rev-1",
              "rating" : 5,
              "reviewerNickname" : "user42",
              "territory" : "USA",
              "title" : "Amazing"
            }
          ]
        }
        """)
    }
}
