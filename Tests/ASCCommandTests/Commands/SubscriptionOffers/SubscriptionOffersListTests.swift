import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOffersListTests {

    @Test func `listed offers include subscriptionId duration mode and affordances`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        given(mockRepo).listIntroductoryOffers(subscriptionId: .any)
            .willReturn([
                SubscriptionIntroductoryOffer(
                    id: "offer-1",
                    subscriptionId: "sub-1",
                    duration: .oneMonth,
                    offerMode: .freeTrial,
                    numberOfPeriods: 1
                )
            ])

        let cmd = try SubscriptionOffersList.parse(["--subscription-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc subscription-offers delete --offer-id offer-1",
                "listOffers" : "asc subscription-offers list --subscription-id sub-1"
              },
              "duration" : "ONE_MONTH",
              "id" : "offer-1",
              "numberOfPeriods" : 1,
              "offerMode" : "FREE_TRIAL",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        given(mockRepo).listIntroductoryOffers(subscriptionId: .any)
            .willReturn([
                SubscriptionIntroductoryOffer(
                    id: "offer-1",
                    subscriptionId: "sub-1",
                    duration: .threeMonths,
                    offerMode: .payAsYouGo,
                    numberOfPeriods: 3,
                    territory: "USA"
                )
            ])

        let cmd = try SubscriptionOffersList.parse(["--subscription-id", "sub-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("offer-1"))
        #expect(output.contains("THREE_MONTHS"))
        #expect(output.contains("PAY_AS_YOU_GO"))
        #expect(output.contains("USA"))
    }
}
