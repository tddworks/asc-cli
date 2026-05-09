import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaAppLocalizationsUpdateTests {

    @Test func `update returns the updated beta app localization with affordances`() async throws {
        let mockRepo = MockBetaAppLocalizationRepository()
        given(mockRepo).updateBetaAppLocalization(localizationId: .any, update: .any)
            .willReturn(BetaAppLocalization(
                id: "bal-1",
                appId: "app-1",
                locale: "en-US",
                description: "Updated beta description",
                feedbackEmail: "beta@example.com"
            ))

        let cmd = try BetaAppLocalizationsUpdate.parse([
            "--localization-id", "bal-1",
            "--description", "Updated beta description",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc beta-app-localizations delete --localization-id bal-1",
                "get" : "asc beta-app-localizations get --localization-id bal-1",
                "listSiblings" : "asc beta-app-localizations list --app-id app-1",
                "update" : "asc beta-app-localizations update --localization-id bal-1"
              },
              "appId" : "app-1",
              "description" : "Updated beta description",
              "feedbackEmail" : "beta@example.com",
              "id" : "bal-1",
              "locale" : "en-US"
            }
          ]
        }
        """)
    }
}
