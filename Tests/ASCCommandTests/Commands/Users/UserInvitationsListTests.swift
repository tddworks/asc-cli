import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct UserInvitationsListTests {

    @Test func `listed invitations include email roles and cancel affordance`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).listUserInvitations(role: .any).willReturn([
            UserInvitationRecord(
                id: "inv-1",
                email: "new@example.com",
                firstName: "New",
                lastName: "User",
                roles: [.developer],
                isAllAppsVisible: false,
                isProvisioningAllowed: false
            ),
        ])

        let cmd = try UserInvitationsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\" : \"inv-1\""))
        #expect(output.contains("\"email\" : \"new@example.com\""))
        #expect(output.contains("DEVELOPER"))
        #expect(output.contains("asc user-invitations cancel --invitation-id inv-1"))
    }
}
