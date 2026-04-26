import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionsDeleteTests {

    @Test func `delete subscription calls repo with subscription id`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).deleteSubscription(subscriptionId: .any).willReturn(())

        let cmd = try SubscriptionsDelete.parse(["--subscription-id", "sub-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteSubscription(subscriptionId: .value("sub-1")).called(1)
    }
}
