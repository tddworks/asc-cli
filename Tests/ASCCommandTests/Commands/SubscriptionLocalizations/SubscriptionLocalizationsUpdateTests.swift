import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionLocalizationsUpdateTests {

    @Test func `updates subscription localization name and description and returns updated record with affordances`() async throws {
        let mockRepo = MockSubscriptionLocalizationRepository()
        given(mockRepo).updateLocalization(localizationId: .any, name: .any, description: .any)
            .willReturn(SubscriptionLocalization(
                id: "loc-1",
                subscriptionId: "",
                locale: "en-US",
                name: "Monthly Premium Updated",
                description: "Updated description"
            ))

        let cmd = try SubscriptionLocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--name", "Monthly Premium Updated",
            "--description", "Updated description",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc subscription-localizations delete --localization-id loc-1",
                "listSiblings" : "asc subscription-localizations list --subscription-id ",
                "update" : "asc subscription-localizations update --localization-id loc-1 --name <name>"
              },
              "description" : "Updated description",
              "id" : "loc-1",
              "locale" : "en-US",
              "name" : "Monthly Premium Updated",
              "subscriptionId" : ""
            }
          ]
        }
        """)
        verify(mockRepo).updateLocalization(
            localizationId: .value("loc-1"),
            name: .value("Monthly Premium Updated"),
            description: .value("Updated description")
        ).called(1)
    }
}
