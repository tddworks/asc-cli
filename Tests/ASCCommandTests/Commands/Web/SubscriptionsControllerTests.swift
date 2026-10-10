import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionsControllerTests {

    /// Stubs App Store Connect so the saved subscription echoes the attributes it was sent.
    private func echoingRepo() -> MockSubscriptionRepository {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).updateSubscription(
            subscriptionId: .any, name: .any, isFamilySharable: .any, groupLevel: .any, subscriptionPeriod: .any, reviewNote: .any,
            multiSeatStatus: .any, marketSettings: .any
        ).willProduce { id, name, isFamilySharable, groupLevel, period, reviewNote, multiSeatStatus, marketSettings in
            Subscription(
                id: id, groupId: "", name: name ?? "Team Plan",
                productId: "com.example.team", subscriptionPeriod: period ?? .oneMonth,
                isFamilySharable: isFamilySharable ?? false, state: .missingMetadata,
                groupLevel: groupLevel, reviewNote: reviewNote,
                multiSeatStatus: multiSeatStatus, marketSettings: marketSettings
            )
        }
        return mockRepo
    }

    @Test func `should save multi-seat status and markets sent over REST`() async throws {
        let updated = try await SubscriptionsController.update(
            subscriptionId: "sub-1",
            json: ["multiSeatStatus": "ENABLED", "marketSetting": ["APP_STORE", "APPLE_SCHOOL"]],
            repo: echoingRepo()
        )

        #expect(updated == Subscription(
            id: "sub-1", groupId: "", name: "Team Plan",
            productId: "com.example.team", subscriptionPeriod: .oneMonth,
            isFamilySharable: false, state: .missingMetadata,
            multiSeatStatus: .enabled, marketSettings: [.appStore, .appleSchool]
        ))
    }

    @Test func `should save the same fields over REST as the CLI update command`() async throws {
        let updated = try await SubscriptionsController.update(
            subscriptionId: "sub-1",
            json: ["name": "Renamed", "familySharable": true, "groupLevel": 2, "period": "ONE_YEAR", "reviewNote": "Sign in with demo account"],
            repo: echoingRepo()
        )

        #expect(updated == Subscription(
            id: "sub-1", groupId: "", name: "Renamed",
            productId: "com.example.team", subscriptionPeriod: .oneYear,
            isFamilySharable: true, state: .missingMetadata,
            groupLevel: 2, reviewNote: "Sign in with demo account"
        ))
    }
}
