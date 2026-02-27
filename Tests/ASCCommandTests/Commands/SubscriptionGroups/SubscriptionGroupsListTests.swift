import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionGroupsListTests {

    @Test func `listed subscription groups include appId, referenceName and affordances`() async throws {
        let mockRepo = MockSubscriptionGroupRepository()
        given(mockRepo).listSubscriptionGroups(appId: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [
                SubscriptionGroup(id: "grp-1", appId: "app-1", referenceName: "Premium Plans")
            ], nextCursor: nil))

        let cmd = try SubscriptionGroupsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createSubscription" : "asc subscriptions create --group-id grp-1 --name <name> --product-id <id> --period ONE_MONTH",
                "listSubscriptions" : "asc subscriptions list --group-id grp-1"
              },
              "appId" : "app-1",
              "id" : "grp-1",
              "referenceName" : "Premium Plans"
            }
          ]
        }
        """)
    }
}
