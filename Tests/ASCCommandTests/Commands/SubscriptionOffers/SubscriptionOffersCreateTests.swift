import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOffersCreateTests {

    @Test func `creates free trial offer and returns it with affordances`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        given(mockRepo).createIntroductoryOffer(
            subscriptionId: .any, duration: .any, offerMode: .any,
            numberOfPeriods: .any, startDate: .any, endDate: .any,
            territory: .any, pricePointId: .any
        ).willReturn(SubscriptionIntroductoryOffer(
            id: "offer-new",
            subscriptionId: "sub-1",
            duration: .oneMonth,
            offerMode: .freeTrial,
            numberOfPeriods: 1
        ))

        let cmd = try SubscriptionOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--duration", "ONE_MONTH",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc subscription-offers delete --offer-id offer-new",
                "listOffers" : "asc subscription-offers list --subscription-id sub-1"
              },
              "duration" : "ONE_MONTH",
              "id" : "offer-new",
              "numberOfPeriods" : 1,
              "offerMode" : "FREE_TRIAL",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }

    @Test func `throws for invalid duration`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        let cmd = try SubscriptionOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--duration", "DAILY",
            "--mode", "FREE_TRIAL",
            "--periods", "1",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `throws for invalid mode`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        let cmd = try SubscriptionOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--duration", "ONE_MONTH",
            "--mode", "UNKNOWN_MODE",
            "--periods", "1",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `throws when PAY_AS_YOU_GO missing price point id`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        let cmd = try SubscriptionOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--duration", "ONE_MONTH",
            "--mode", "PAY_AS_YOU_GO",
            "--periods", "1",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `throws when PAY_UP_FRONT missing price point id`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        let cmd = try SubscriptionOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--duration", "ONE_MONTH",
            "--mode", "PAY_UP_FRONT",
            "--periods", "1",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `succeeds when PAY_AS_YOU_GO with price point id`() async throws {
        let mockRepo = MockSubscriptionIntroductoryOfferRepository()
        given(mockRepo).createIntroductoryOffer(
            subscriptionId: .any, duration: .any, offerMode: .any,
            numberOfPeriods: .any, startDate: .any, endDate: .any,
            territory: .any, pricePointId: .any
        ).willReturn(SubscriptionIntroductoryOffer(
            id: "offer-paid",
            subscriptionId: "sub-1",
            duration: .oneMonth,
            offerMode: .payAsYouGo,
            numberOfPeriods: 1
        ))

        let cmd = try SubscriptionOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--duration", "ONE_MONTH",
            "--mode", "PAY_AS_YOU_GO",
            "--periods", "1",
            "--price-point-id", "pp-1",
        ])
        let output = try await cmd.execute(repo: mockRepo)
        #expect(output.contains("offer-paid"))
        #expect(output.contains("PAY_AS_YOU_GO"))
    }
}
