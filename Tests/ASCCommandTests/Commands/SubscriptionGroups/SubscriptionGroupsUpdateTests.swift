import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionGroupsUpdateTests {

    @Test func `updates subscription group reference name and returns updated record`() async throws {
        let mockRepo = MockSubscriptionGroupRepository()
        given(mockRepo).updateSubscriptionGroup(groupId: .any, referenceName: .any)
            .willReturn(SubscriptionGroup(id: "grp-1", appId: "", referenceName: "Renamed Plans"))

        let cmd = try SubscriptionGroupsUpdate.parse([
            "--group-id", "grp-1",
            "--reference-name", "Renamed Plans",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateSubscriptionGroup(
            groupId: .value("grp-1"), referenceName: .value("Renamed Plans")
        ).called(1)
    }
}
