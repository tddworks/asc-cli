import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionsCreateTests {

    @Test func `creates subscription and returns it with affordances`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).createSubscription(groupId: .any, name: .any, productId: .any, period: .any, isFamilySharable: .any, groupLevel: .any)
            .willReturn(Subscription(
                id: "sub-new",
                groupId: "grp-1",
                name: "Monthly Premium",
                productId: "com.app.monthly",
                subscriptionPeriod: .oneMonth,
                isFamilySharable: false,
                state: .missingMetadata
            ))

        let cmd = try SubscriptionsCreate.parse([
            "--group-id", "grp-1",
            "--name", "Monthly Premium",
            "--product-id", "com.app.monthly",
            "--period", "ONE_MONTH",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createLocalization" : "asc subscription-localizations create --subscription-id sub-new --locale en-US --name <name>",
                "listLocalizations" : "asc subscription-localizations list --subscription-id sub-new"
              },
              "groupId" : "grp-1",
              "id" : "sub-new",
              "isFamilySharable" : false,
              "name" : "Monthly Premium",
              "productId" : "com.app.monthly",
              "state" : "MISSING_METADATA",
              "subscriptionPeriod" : "ONE_MONTH"
            }
          ]
        }
        """)
    }

    @Test func `throws for invalid subscription period`() async throws {
        let mockRepo = MockSubscriptionRepository()
        let cmd = try SubscriptionsCreate.parse([
            "--group-id", "grp-1",
            "--name", "Monthly",
            "--product-id", "com.app.monthly",
            "--period", "WEEKLY",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
