import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaAppLocalizationsCreateTests {

    @Test func `creates beta app localization with description and feedback email`() async throws {
        let mockRepo = MockBetaAppLocalizationRepository()
        given(mockRepo).createBetaAppLocalization(appId: .any, locale: .any, update: .any)
            .willReturn(BetaAppLocalization(
                id: "bal-new",
                appId: "app-1",
                locale: "en-US",
                description: "Welcome to the beta",
                feedbackEmail: "beta@example.com"
            ))

        let cmd = try BetaAppLocalizationsCreate.parse([
            "--app-id", "app-1",
            "--locale", "en-US",
            "--description", "Welcome to the beta",
            "--feedback-email", "beta@example.com",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc beta-app-localizations delete --localization-id bal-new",
                "get" : "asc beta-app-localizations get --localization-id bal-new",
                "listSiblings" : "asc beta-app-localizations list --app-id app-1",
                "update" : "asc beta-app-localizations update --localization-id bal-new"
              },
              "appId" : "app-1",
              "description" : "Welcome to the beta",
              "feedbackEmail" : "beta@example.com",
              "id" : "bal-new",
              "locale" : "en-US"
            }
          ]
        }
        """)
    }
}
