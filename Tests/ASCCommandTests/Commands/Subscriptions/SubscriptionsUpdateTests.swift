import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionsUpdateTests {

    @Test func `updates subscription name and review note and returns updated record`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).updateSubscription(
            subscriptionId: .any, name: .any, isFamilySharable: .any, groupLevel: .any, subscriptionPeriod: .any, reviewNote: .any
        ).willReturn(Subscription(
            id: "sub-1", groupId: "", name: "Renamed",
            productId: "com.app.monthly", subscriptionPeriod: .oneMonth,
            isFamilySharable: false, state: .missingMetadata
        ))

        let cmd = try SubscriptionsUpdate.parse([
            "--subscription-id", "sub-1",
            "--name", "Renamed",
            "--review-note", "For app review",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateSubscription(
            subscriptionId: .value("sub-1"),
            name: .value("Renamed"),
            isFamilySharable: .value(nil),
            groupLevel: .value(nil),
            subscriptionPeriod: .value(nil),
            reviewNote: .value("For app review")
        ).called(1)
    }

    @Test func `family-sharable flag passes true to repo`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).updateSubscription(
            subscriptionId: .any, name: .any, isFamilySharable: .any, groupLevel: .any, subscriptionPeriod: .any, reviewNote: .any
        ).willReturn(Subscription(
            id: "sub-1", groupId: "", name: "X", productId: "com.x", subscriptionPeriod: .oneMonth,
            isFamilySharable: true, state: .missingMetadata
        ))

        let cmd = try SubscriptionsUpdate.parse(["--subscription-id", "sub-1", "--family-sharable"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateSubscription(
            subscriptionId: .value("sub-1"), name: .value(nil),
            isFamilySharable: .value(true), groupLevel: .value(nil),
            subscriptionPeriod: .value(nil), reviewNote: .value(nil)
        ).called(1)
    }

    @Test func `group-level passes through to repo`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).updateSubscription(
            subscriptionId: .any, name: .any, isFamilySharable: .any, groupLevel: .any, subscriptionPeriod: .any, reviewNote: .any
        ).willReturn(Subscription(
            id: "sub-1", groupId: "", name: "X", productId: "com.x", subscriptionPeriod: .oneMonth,
            isFamilySharable: false, state: .missingMetadata, groupLevel: 3
        ))

        let cmd = try SubscriptionsUpdate.parse(["--subscription-id", "sub-1", "--group-level", "3"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateSubscription(
            subscriptionId: .value("sub-1"), name: .value(nil),
            isFamilySharable: .value(nil), groupLevel: .value(3),
            subscriptionPeriod: .value(nil), reviewNote: .value(nil)
        ).called(1)
    }

    @Test func `period passes through to repo`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).updateSubscription(
            subscriptionId: .any, name: .any, isFamilySharable: .any, groupLevel: .any, subscriptionPeriod: .any, reviewNote: .any
        ).willReturn(Subscription(
            id: "sub-1", groupId: "", name: "X", productId: "com.x", subscriptionPeriod: .oneYear,
            isFamilySharable: false, state: .missingMetadata
        ))

        let cmd = try SubscriptionsUpdate.parse(["--subscription-id", "sub-1", "--period", "ONE_YEAR"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateSubscription(
            subscriptionId: .value("sub-1"), name: .value(nil),
            isFamilySharable: .value(nil), groupLevel: .value(nil),
            subscriptionPeriod: .value(.oneYear), reviewNote: .value(nil)
        ).called(1)
    }
}
