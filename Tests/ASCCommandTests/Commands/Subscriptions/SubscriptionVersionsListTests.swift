import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionVersionsListTests {

    @Test func `listed subscription versions in review do not offer adding them to a submission`() async throws {
        let mockRepo = MockProductVersions()
        given(mockRepo).listSubscriptionVersions(subscriptionId: .value("sub-1")).willReturn([
            ProductVersion(id: "sv-1", productId: "sub-1", kind: .subscription, version: 2, state: .waitingForReview),
        ])

        let cmd = try SubscriptionVersionsList.parse(["--subscription-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listVersions" : "asc subscriptions versions list --subscription-id sub-1"
              },
              "id" : "sv-1",
              "kind" : "SUBSCRIPTION",
              "productId" : "sub-1",
              "state" : "WAITING_FOR_REVIEW",
              "version" : 2
            }
          ]
        }
        """)
    }
}
