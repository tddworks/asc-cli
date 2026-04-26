import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionGroupsCreateTests {

    @Test func `creates subscription group and returns it with affordances`() async throws {
        let mockRepo = MockSubscriptionGroupRepository()
        given(mockRepo).createSubscriptionGroup(appId: .any, referenceName: .any)
            .willReturn(SubscriptionGroup(
                id: "grp-new",
                appId: "app-1",
                referenceName: "Premium Plans"
            ))

        let cmd = try SubscriptionGroupsCreate.parse([
            "--app-id", "app-1",
            "--reference-name", "Premium Plans",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createSubscription" : "asc subscriptions create --group-id grp-new --name <name> --product-id <id> --period ONE_MONTH",
                "delete" : "asc subscription-groups delete --group-id grp-new",
                "listSubscriptions" : "asc subscriptions list --group-id grp-new",
                "update" : "asc subscription-groups update --group-id grp-new --reference-name <name>"
              },
              "appId" : "app-1",
              "id" : "grp-new",
              "referenceName" : "Premium Plans"
            }
          ]
        }
        """)
    }
}
