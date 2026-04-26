import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionsListTests {

    @Test func `listed subscriptions include groupId, period, state and affordances`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).listSubscriptions(groupId: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [
                Subscription(
                    id: "sub-1",
                    groupId: "grp-1",
                    name: "Monthly Premium",
                    productId: "com.app.monthly",
                    subscriptionPeriod: .oneMonth,
                    isFamilySharable: false,
                    state: .missingMetadata
                )
            ], nextCursor: nil))

        let cmd = try SubscriptionsList.parse(["--group-id", "grp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createIntroductoryOffer" : "asc subscription-offers create --subscription-id sub-1 --duration ONE_MONTH --mode FREE_TRIAL --periods 1",
                "createLocalization" : "asc subscription-localizations create --subscription-id sub-1 --locale en-US --name <name>",
                "delete" : "asc subscriptions delete --subscription-id sub-1",
                "getAvailability" : "asc subscription-availability get --subscription-id sub-1",
                "listIntroductoryOffers" : "asc subscription-offers list --subscription-id sub-1",
                "listLocalizations" : "asc subscription-localizations list --subscription-id sub-1",
                "listOfferCodes" : "asc subscription-offer-codes list --subscription-id sub-1",
                "update" : "asc subscriptions update --subscription-id sub-1 --name <name>"
              },
              "groupId" : "grp-1",
              "id" : "sub-1",
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

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockSubscriptionRepository()
        given(mockRepo).listSubscriptions(groupId: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [
                Subscription(
                    id: "sub-1",
                    groupId: "grp-1",
                    name: "Monthly",
                    productId: "com.app.monthly",
                    subscriptionPeriod: .oneMonth,
                    state: .missingMetadata
                )
            ], nextCursor: nil))

        let cmd = try SubscriptionsList.parse(["--group-id", "grp-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("sub-1"))
        #expect(output.contains("Monthly"))
        #expect(output.contains("1 Month"))
    }
}
