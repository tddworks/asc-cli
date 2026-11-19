import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionGroupVersionsListTests {

    @Test func `listed subscription group versions show the command to add them to a submission`() async throws {
        let mockRepo = MockProductVersionRepository()
        given(mockRepo).listSubscriptionGroupVersions(groupId: .value("grp-1")).willReturn([
            ProductVersion(id: "gv-1", productId: "grp-1", kind: .subscriptionGroup, version: 1, state: .prepareForSubmission),
        ])

        let cmd = try SubscriptionGroupVersionsList.parse(["--group-id", "grp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "addToSubmission" : "asc review-submissions items add --submission-id <submission-id> --subscription-group-version-id gv-1",
                "listVersions" : "asc subscription-groups versions list --group-id grp-1"
              },
              "id" : "gv-1",
              "kind" : "SUBSCRIPTION_GROUP",
              "productId" : "grp-1",
              "state" : "PREPARE_FOR_SUBMISSION",
              "version" : 1
            }
          ]
        }
        """)
    }
}
