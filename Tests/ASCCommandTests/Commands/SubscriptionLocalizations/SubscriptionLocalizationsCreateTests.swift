import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionLocalizationsCreateTests {

    @Test func `creates subscription localization with name and description and returns it with affordances`() async throws {
        let mockRepo = MockSubscriptionLocalizationRepository()
        given(mockRepo).createLocalization(subscriptionId: .any, locale: .any, name: .any, description: .any)
            .willReturn(SubscriptionLocalization(
                id: "loc-new",
                subscriptionId: "sub-1",
                locale: "en-US",
                name: "Monthly Premium",
                description: "Full access to all features"
            ))

        let cmd = try SubscriptionLocalizationsCreate.parse([
            "--subscription-id", "sub-1",
            "--locale", "en-US",
            "--name", "Monthly Premium",
            "--description", "Full access to all features",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc subscription-localizations list --subscription-id sub-1"
              },
              "description" : "Full access to all features",
              "id" : "loc-new",
              "locale" : "en-US",
              "name" : "Monthly Premium",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }

    @Test func `creates subscription localization without description omits description from json`() async throws {
        let mockRepo = MockSubscriptionLocalizationRepository()
        given(mockRepo).createLocalization(subscriptionId: .any, locale: .any, name: .any, description: .any)
            .willReturn(SubscriptionLocalization(
                id: "loc-new",
                subscriptionId: "sub-1",
                locale: "zh-Hans",
                name: "月度高级版"
            ))

        let cmd = try SubscriptionLocalizationsCreate.parse([
            "--subscription-id", "sub-1",
            "--locale", "zh-Hans",
            "--name", "月度高级版",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc subscription-localizations list --subscription-id sub-1"
              },
              "id" : "loc-new",
              "locale" : "zh-Hans",
              "name" : "月度高级版",
              "subscriptionId" : "sub-1"
            }
          ]
        }
        """)
    }
}
