import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionPromotionalOffersListTests {

    @Test func `lists promotional offers with affordances`() async throws {
        let mockRepo = MockSubscriptionPromotionalOfferRepository()
        given(mockRepo).listPromotionalOffers(subscriptionId: .any).willReturn([
            SubscriptionPromotionalOffer(
                id: "po-1", subscriptionId: "sub-1", name: "Winback",
                offerCode: "winback25", duration: .oneMonth, offerMode: .payAsYouGo, numberOfPeriods: 1
            )
        ])

        let cmd = try SubscriptionPromotionalOffersList.parse(["--subscription-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc subscription-promotional-offers delete --offer-id po-1",
                "listOffers" : "asc subscription-promotional-offers list --subscription-id sub-1",
                "listPrices" : "asc subscription-promotional-offers prices list --offer-id po-1"
              },
              "duration" : "ONE_MONTH",
              "id" : "po-1",
              "name" : "Winback",
              "numberOfPeriods" : 1,
              "offerCode" : "winback25",
              "offerMode" : "PAY_AS_YOU_GO",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct SubscriptionPromotionalOffersCreateTests {

    @Test func `parses --price specs into territory and pricePointId`() async throws {
        let mockRepo = MockSubscriptionPromotionalOfferRepository()
        given(mockRepo).createPromotionalOffer(
            subscriptionId: .any, name: .any, offerCode: .any,
            duration: .any, offerMode: .any, numberOfPeriods: .any, prices: .any
        ).willReturn(SubscriptionPromotionalOffer(
            id: "po-new", subscriptionId: "sub-1", name: "Winback",
            offerCode: "wb", duration: .oneMonth, offerMode: .payAsYouGo, numberOfPeriods: 1
        ))

        let cmd = try SubscriptionPromotionalOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "Winback",
            "--offer-code", "wb",
            "--duration", "ONE_MONTH",
            "--mode", "PAY_AS_YOU_GO",
            "--periods", "1",
            "--price", "USA=spp-1",
            "--price", "GBR=spp-2",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createPromotionalOffer(
            subscriptionId: .value("sub-1"),
            name: .value("Winback"),
            offerCode: .value("wb"),
            duration: .value(.oneMonth),
            offerMode: .value(.payAsYouGo),
            numberOfPeriods: .value(1),
            prices: .matching { input in
                input == [
                    PromotionalOfferPriceInput(territory: "USA", pricePointId: "spp-1"),
                    PromotionalOfferPriceInput(territory: "GBR", pricePointId: "spp-2"),
                ]
            }
        ).called(1)
    }

    @Test func `throws when --price spec is malformed`() async throws {
        let mockRepo = MockSubscriptionPromotionalOfferRepository()
        let cmd = try SubscriptionPromotionalOffersCreate.parse([
            "--subscription-id", "sub-1",
            "--name", "Winback",
            "--offer-code", "wb",
            "--duration", "ONE_MONTH",
            "--mode", "PAY_AS_YOU_GO",
            "--periods", "1",
            "--price", "malformed",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}

@Suite
struct SubscriptionPromotionalOffersDeleteTests {

    @Test func `delete calls repo with offer id`() async throws {
        let mockRepo = MockSubscriptionPromotionalOfferRepository()
        given(mockRepo).deletePromotionalOffer(offerId: .any).willReturn(())

        let cmd = try SubscriptionPromotionalOffersDelete.parse(["--offer-id", "po-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deletePromotionalOffer(offerId: .value("po-1")).called(1)
    }
}

@Suite
struct SubscriptionPromotionalOffersPricesListTests {

    @Test func `lists prices with affordances`() async throws {
        let mockRepo = MockSubscriptionPromotionalOfferRepository()
        given(mockRepo).listPrices(offerId: .any).willReturn([
            SubscriptionPromotionalOfferPrice(id: "p-1", offerId: "po-1", territory: "USA", subscriptionPricePointId: "spp-1")
        ])

        let cmd = try SubscriptionPromotionalOffersPricesList.parse(["--offer-id", "po-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPrices" : "asc subscription-promotional-offers prices list --offer-id po-1"
              },
              "id" : "p-1",
              "offerId" : "po-1",
              "subscriptionPricePointId" : "spp-1",
              "territory" : "USA"
            }
          ]
        }
        """)
    }
}
