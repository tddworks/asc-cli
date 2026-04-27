import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPPricePointsListTests {

    @Test func `listed price points include iapId, territory, price and affordances`() async throws {
        let mockRepo = MockInAppPurchasePriceRepository()
        given(mockRepo).listPricePoints(iapId: .any, territory: .any)
            .willReturn([InAppPurchasePricePoint(
                id: "pp-1", iapId: "iap-1", territory: "USA",
                customerPrice: "0.99", proceeds: "0.70"
            )])

        let cmd = try IAPPricePointsList.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPricePoints" : "asc iap price-points list --iap-id iap-1",
                "setPrice" : "asc iap prices set --base-territory USA --iap-id iap-1 --price-point-id pp-1"
              },
              "customerPrice" : "0.99",
              "iapId" : "iap-1",
              "id" : "pp-1",
              "proceeds" : "0.70",
              "territory" : "USA"
            }
          ]
        }
        """)
    }

    @Test func `price point without territory omits setPrice affordance and nil fields`() async throws {
        let mockRepo = MockInAppPurchasePriceRepository()
        given(mockRepo).listPricePoints(iapId: .any, territory: .any)
            .willReturn([InAppPurchasePricePoint(
                id: "pp-2", iapId: "iap-1",
                territory: nil, customerPrice: nil, proceeds: nil
            )])

        let cmd = try IAPPricePointsList.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPricePoints" : "asc iap price-points list --iap-id iap-1"
              },
              "iapId" : "iap-1",
              "id" : "pp-2"
            }
          ]
        }
        """)
    }
}
