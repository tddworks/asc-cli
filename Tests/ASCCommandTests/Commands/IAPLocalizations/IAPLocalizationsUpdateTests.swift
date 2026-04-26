import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPLocalizationsUpdateTests {

    @Test func `updates iap localization name and description and returns updated record with affordances`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).updateLocalization(localizationId: .any, name: .any, description: .any)
            .willReturn(InAppPurchaseLocalization(
                id: "loc-1",
                iapId: "",
                locale: "en-US",
                name: "Gold Coins Updated",
                description: "Updated description"
            ))

        let cmd = try IAPLocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--name", "Gold Coins Updated",
            "--description", "Updated description",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc iap-localizations delete --localization-id loc-1",
                "listSiblings" : "asc iap-localizations list --iap-id ",
                "update" : "asc iap-localizations update --localization-id loc-1 --name <name>"
              },
              "description" : "Updated description",
              "iapId" : "",
              "id" : "loc-1",
              "locale" : "en-US",
              "name" : "Gold Coins Updated"
            }
          ]
        }
        """)
        verify(mockRepo).updateLocalization(
            localizationId: .value("loc-1"),
            name: .value("Gold Coins Updated"),
            description: .value("Updated description")
        ).called(1)
    }

    @Test func `updates with only name passes nil description to repo`() async throws {
        let mockRepo = MockInAppPurchaseLocalizationRepository()
        given(mockRepo).updateLocalization(localizationId: .any, name: .any, description: .any)
            .willReturn(InAppPurchaseLocalization(id: "loc-1", iapId: "", locale: "en-US", name: "Just Name"))

        let cmd = try IAPLocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--name", "Just Name",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateLocalization(
            localizationId: .value("loc-1"),
            name: .value("Just Name"),
            description: .value(nil)
        ).called(1)
    }
}
