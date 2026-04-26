import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionOfferCodesPricesListTests {

    @Test func `lists subscription offer code prices with affordances`() async throws {
        let mockRepo = MockSubscriptionOfferCodeRepository()
        given(mockRepo).listPrices(offerCodeId: .any).willReturn([
            SubscriptionOfferCodePrice(id: "p-1", offerCodeId: "oc-1", territory: "USA", subscriptionPricePointId: "spp-7")
        ])

        let cmd = try SubscriptionOfferCodesPricesList.parse(["--offer-code-id", "oc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPrices" : "asc subscription-offer-codes prices list --offer-code-id oc-1"
              },
              "id" : "p-1",
              "offerCodeId" : "oc-1",
              "subscriptionPricePointId" : "spp-7",
              "territory" : "USA"
            }
          ]
        }
        """)
        verify(mockRepo).listPrices(offerCodeId: .value("oc-1")).called(1)
    }
}
