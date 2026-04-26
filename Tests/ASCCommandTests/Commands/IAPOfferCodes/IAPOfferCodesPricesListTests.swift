import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPOfferCodesPricesListTests {

    @Test func `lists prices and returns them with affordances`() async throws {
        let mockRepo = MockInAppPurchaseOfferCodeRepository()
        given(mockRepo).listPrices(offerCodeId: .any).willReturn([
            InAppPurchaseOfferCodePrice(id: "p-1", offerCodeId: "oc-1", territory: "USA", pricePointId: "pp-9")
        ])

        let cmd = try IAPOfferCodesPricesList.parse(["--offer-code-id", "oc-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPrices" : "asc iap-offer-codes prices list --offer-code-id oc-1"
              },
              "id" : "p-1",
              "offerCodeId" : "oc-1",
              "pricePointId" : "pp-9",
              "territory" : "USA"
            }
          ]
        }
        """)
        verify(mockRepo).listPrices(offerCodeId: .value("oc-1")).called(1)
    }
}
