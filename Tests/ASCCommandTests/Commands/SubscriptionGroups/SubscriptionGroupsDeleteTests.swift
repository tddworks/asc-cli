import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct SubscriptionGroupsDeleteTests {

    @Test func `delete subscription group calls repo with group id`() async throws {
        let mockRepo = MockSubscriptionGroups()
        given(mockRepo).deleteSubscriptionGroup(groupId: .any).willReturn(())

        let cmd = try SubscriptionGroupsDelete.parse(["--group-id", "grp-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteSubscriptionGroup(groupId: .value("grp-1")).called(1)
    }
}
