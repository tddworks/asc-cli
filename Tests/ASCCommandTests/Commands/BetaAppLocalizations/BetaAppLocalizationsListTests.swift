import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaAppLocalizationsListTests {

    @Test func `listed beta app localizations show appId, locale, description and affordances`() async throws {
        let mockRepo = MockBetaAppLocalizationRepository()
        given(mockRepo).listBetaAppLocalizations(appId: .any)
            .willReturn([
                BetaAppLocalization(
                    id: "bal-1",
                    appId: "app-1",
                    locale: "en-US",
                    description: "Welcome to the beta",
                    feedbackEmail: "beta@example.com"
                )
            ])

        let cmd = try BetaAppLocalizationsList.parse(["--app-id", "app-1", "--pretty"])
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
              "description" : "Welcome to the beta",
              "feedbackEmail" : "beta@example.com",
              "id" : "bal-1",
              "locale" : "en-US"
            }
          ]
        }
        """)
    }
}
