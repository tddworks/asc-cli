import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPListTests {

    @Test func `listed iaps include appId, productId, type, state and affordances`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        given(mockRepo).listInAppPurchases(appId: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [
                InAppPurchase(
                    id: "iap-1",
                    appId: "app-1",
                    referenceName: "Gold Coins",
                    productId: "com.app.gold",
                    type: .consumable,
                    state: .missingMetadata
                )
            ], nextCursor: nil))

        let cmd = try IAPList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createLocalization" : "asc iap-localizations create --iap-id iap-1 --locale en-US --name <name>",
                "createOfferCode" : "asc iap-offer-codes create --eligibility <NON_SPENDER|ACTIVE_SPENDER|CHURNED_SPENDER> --iap-id iap-1 --name <name>",
                "delete" : "asc iap delete --iap-id iap-1",
                "getAvailability" : "asc iap-availability get --iap-id iap-1",
                "getPriceSchedule" : "asc iap-price-schedule get --iap-id iap-1",
                "getReviewScreenshot" : "asc iap-review-screenshot get --iap-id iap-1",
                "listImages" : "asc iap-images list --iap-id iap-1",
                "listLocalizations" : "asc iap-localizations list --iap-id iap-1",
                "listOfferCodes" : "asc iap-offer-codes list --iap-id iap-1",
                "listPricePoints" : "asc iap price-points list --iap-id iap-1",
                "setPrice" : "asc iap prices set --base-territory <territory> --iap-id iap-1 --price-point-id <price-point-id>",
                "update" : "asc iap update --iap-id iap-1 --reference-name <name>"
              },
              "appId" : "app-1",
              "id" : "iap-1",
              "productId" : "com.app.gold",
              "referenceName" : "Gold Coins",
              "state" : "MISSING_METADATA",
              "type" : "CONSUMABLE"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        given(mockRepo).listInAppPurchases(appId: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [
                InAppPurchase(
                    id: "iap-1",
                    appId: "app-1",
                    referenceName: "Gold Coins",
                    productId: "com.app.gold",
                    type: .consumable,
                    state: .missingMetadata
                )
            ], nextCursor: nil))

        let cmd = try IAPList.parse(["--app-id", "app-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("iap-1"))
        #expect(output.contains("com.app.gold"))
        #expect(output.contains("Consumable"))
    }
}
