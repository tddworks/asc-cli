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
                "createIntroductoryOffer" : "asc subscription-offers create --duration ONE_MONTH --mode FREE_TRIAL --periods 1 --subscription-id sub-new",
                "createLocalization" : "asc subscription-localizations create --locale en-US --name <name> --subscription-id sub-new",
                "createPromotionalOffer" : "asc subscription-promotional-offers create --duration ONE_MONTH --mode PAY_AS_YOU_GO --name <name> --offer-code <code> --periods 1 --subscription-id sub-new",
                "delete" : "asc subscriptions delete --subscription-id sub-new",
                "getAvailability" : "asc subscription-availability get --subscription-id sub-new",
                "getPriceSchedule" : "asc subscription-price-schedule get --subscription-id sub-new",
                "getReviewScreenshot" : "asc subscription-review-screenshot get --subscription-id sub-new",
                "listIntroductoryOffers" : "asc subscription-offers list --subscription-id sub-new",
                "listLocalizations" : "asc subscription-localizations list --subscription-id sub-new",
                "listOfferCodes" : "asc subscription-offer-codes list --subscription-id sub-new",
                "listPricePoints" : "asc subscriptions price-points list --subscription-id sub-new",
                "listPromotionalOffers" : "asc subscription-promotional-offers list --subscription-id sub-new",
                "listWinBackOffers" : "asc win-back-offers list --subscription-id sub-new",
                "update" : "asc subscriptions update --name <name> --subscription-id sub-new"
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
