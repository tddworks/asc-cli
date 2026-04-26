import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPLocalizationsListTests {

    @Test func `listed iap localizations include iapId, locale, name and affordances`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).listLocalizations(iapId: .any)
            .willReturn([
                InAppPurchaseLocalization(
                    id: "iap-loc-1",
                    iapId: "iap-1",
                    locale: "en-US",
                    name: "Gold Coins",
                    description: nil
                )
            ])

        let cmd = try IAPLocalizationsList.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc iap-localizations delete --localization-id $LOC_ID$",
                "listSiblings" : "asc iap-localizations list --iap-id iap-1",
                "update" : "asc iap-localizations update --localization-id $LOC_ID$ --name <name>"
              },
              "iapId" : "iap-1",
              "id" : "iap-loc-1",
              "locale" : "en-US",
              "name" : "Gold Coins"
            }
          ]
        }
        """)
    }

    @Test func `description is included when present`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).listLocalizations(iapId: .any)
            .willReturn([
                InAppPurchaseLocalization(
                    id: "loc-1",
                    iapId: "iap-1",
                    locale: "en-US",
                    name: "Gold Coins",
                    description: "In-game currency"
                )
            ])

        let cmd = try IAPLocalizationsList.parse(["--iap-id", "iap-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc iap-localizations delete --localization-id $LOC_ID$",
                "listSiblings" : "asc iap-localizations list --iap-id iap-1",
                "update" : "asc iap-localizations update --localization-id $LOC_ID$ --name <name>"
              },
              "description" : "In-game currency",
              "iapId" : "iap-1",
              "id" : "loc-1",
              "locale" : "en-US",
              "name" : "Gold Coins"
            }
          ]
        }
        """)
    }
}
