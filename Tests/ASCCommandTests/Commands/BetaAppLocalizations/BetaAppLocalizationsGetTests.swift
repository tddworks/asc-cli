import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BetaAppLocalizationsGetTests {

    @Test func `get returns single beta app localization with all fields and affordances`() async throws {
        let mockRepo = MockBetaAppLocalizationRepository()
        given(mockRepo).getBetaAppLocalization(localizationId: .any)
            .willReturn(BetaAppLocalization(
                id: "bal-1",
                appId: "app-1",
                locale: "en-US",
                description: "Welcome",
                feedbackEmail: "beta@example.com",
                marketingUrl: "https://example.com",
                privacyPolicyUrl: "https://example.com/privacy"
            ))

        let cmd = try BetaAppLocalizationsGet.parse(["--localization-id", "bal-1", "--pretty"])
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
              "description" : "Welcome",
              "feedbackEmail" : "beta@example.com",
              "id" : "bal-1",
              "locale" : "en-US",
              "marketingUrl" : "https:\\/\\/example.com",
              "privacyPolicyUrl" : "https:\\/\\/example.com\\/privacy"
            }
          ]
        }
        """)
    }
}
