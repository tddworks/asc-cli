import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionLocalizationsListTests {

    @Test func `listed subscription localizations include subscriptionId, locale, name and affordances`() async throws {
        let mockRepo = MockSubscriptionLocalizationRepository()
        given(mockRepo).listLocalizations(subscriptionId: .any)
            .willReturn([
                SubscriptionLocalization(
                    id: "sub-loc-1",
                    subscriptionId: "sub-1",
                    locale: "en-US",
                    name: "Monthly Premium",
                    description: nil
                )
            ])

        let cmd = try SubscriptionLocalizationsList.parse(["--subscription-id", "sub-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc subscription-localizations list --subscription-id sub-1"
              },
              "id" : "sub-loc-1",
              "locale" : "en-US",
              "name" : "Monthly Premium",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }
}
