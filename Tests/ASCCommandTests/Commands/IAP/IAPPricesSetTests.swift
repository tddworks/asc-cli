import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPPricesSetTests {

    @Test func `set price returns schedule id, iapId and affordances`() async throws {
        let mockRepo = MockInAppPurchasePriceRepository()
        given(mockRepo).setPriceSchedule(iapId: .any, baseTerritory: .any, pricePointId: .any)
            .willReturn(InAppPurchasePriceSchedule(id: "sched-1", iapId: "iap-1"))

        let cmd = try IAPPricesSet.parse([
            "--iap-id", "iap-1",
            "--base-territory", "USA",
            "--price-point-id", "pp-1",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getIAP" : "asc iap get --iap-id iap-1",
                "listPricePoints" : "asc iap price-points list --iap-id iap-1"
              },
              "iapId" : "iap-1",
              "id" : "sched-1"
            }
          ]
        }
        """)
    }
}
