import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionsSubmitTests {

    @Test func `submitted subscription includes id, subscriptionId and affordances`() async throws {
        let mockRepo = MockSubscriptionSubmissionRepository()
        given(mockRepo).submitSubscription(subscriptionId: .any)
            .willReturn(SubscriptionSubmission(id: "submit-1", subscriptionId: "sub-1"))

        let cmd = try SubscriptionsSubmit.parse(["--subscription-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listLocalizations" : "asc subscription-localizations list --subscription-id sub-1",
                "unsubmit" : "asc subscriptions unsubmit --submission-id submit-1"
              },
              "id" : "submit-1",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }
}
