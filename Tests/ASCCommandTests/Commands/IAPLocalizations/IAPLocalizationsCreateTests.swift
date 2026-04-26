import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPLocalizationsCreateTests {

    @Test func `creates iap localization with name and description and returns it with affordances`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).createLocalization(iapId: .any, locale: .any, name: .any, description: .any)
            .willReturn(InAppPurchaseLocalization(
                id: "loc-new",
                iapId: "iap-1",
                locale: "en-US",
                name: "Gold Coins",
                description: "In-game currency"
            ))

        let cmd = try IAPLocalizationsCreate.parse([
            "--iap-id", "iap-1",
            "--locale", "en-US",
            "--name", "Gold Coins",
            "--description", "In-game currency",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc iap-localizations delete --localization-id loc-new",
                "listSiblings" : "asc iap-localizations list --iap-id iap-1",
                "update" : "asc iap-localizations update --localization-id loc-new --name <name>"
              },
              "description" : "In-game currency",
              "iapId" : "iap-1",
              "id" : "loc-new",
              "locale" : "en-US",
              "name" : "Gold Coins"
            }
          ]
        }
        """)
    }

    @Test func `creates iap localization without description omits description from json`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).createLocalization(iapId: .any, locale: .any, name: .any, description: .any)
            .willReturn(InAppPurchaseLocalization(
                id: "loc-new",
                iapId: "iap-1",
                locale: "zh-Hans",
                name: "金币"
            ))

        let cmd = try IAPLocalizationsCreate.parse([
            "--iap-id", "iap-1",
            "--locale", "zh-Hans",
            "--name", "金币",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc iap-localizations delete --localization-id loc-new",
                "listSiblings" : "asc iap-localizations list --iap-id iap-1",
                "update" : "asc iap-localizations update --localization-id loc-new --name <name>"
              },
              "iapId" : "iap-1",
              "id" : "loc-new",
              "locale" : "zh-Hans",
              "name" : "金币"
            }
          ]
        }
        """)
    }
}
