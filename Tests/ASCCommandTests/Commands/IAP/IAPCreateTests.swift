import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPCreateTests {

    @Test func `creates iap and returns it with affordances`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        given(mockRepo).createInAppPurchase(appId: .any, referenceName: .any, productId: .any, type: .any)
            .willReturn(InAppPurchase(
                id: "iap-new",
                appId: "app-1",
                referenceName: "Extra Lives",
                productId: "com.app.lives",
                type: .consumable,
                state: .missingMetadata
            ))

        let cmd = try IAPCreate.parse([
            "--app-id", "app-1",
            "--reference-name", "Extra Lives",
            "--product-id", "com.app.lives",
            "--type", "consumable",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createLocalization" : "asc iap-localizations create --iap-id iap-new --locale en-US --name <name>",
                "listLocalizations" : "asc iap-localizations list --iap-id iap-new"
              },
              "appId" : "app-1",
              "id" : "iap-new",
              "productId" : "com.app.lives",
              "referenceName" : "Extra Lives",
              "state" : "MISSING_METADATA",
              "type" : "CONSUMABLE"
            }
          ]
        }
        """)
    }

    @Test func `throws for invalid iap type`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        let cmd = try IAPCreate.parse([
            "--app-id", "app-1",
            "--reference-name", "Upgrade",
            "--product-id", "com.app.upgrade",
            "--type", "subscription",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
