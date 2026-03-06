import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct UserInvitationsInviteTests {

    @Test func `invite returns invitation record with affordances`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).inviteUser(
            email: .any,
            firstName: .any,
            lastName: .any,
            roles: .any,
            allAppsVisible: .any
        ).willReturn(
            UserInvitationRecord(
                id: "inv-1",
                email: "new@example.com",
                firstName: "New",
                lastName: "User",
                roles: [.developer],
                isAllAppsVisible: false,
                isProvisioningAllowed: false
            )
        )

        let cmd = try UserInvitationsInvite.parse([
            "--email", "new@example.com",
            "--first-name", "New",
            "--last-name", "User",
            "--role", "DEVELOPER",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("inv-1"))
        #expect(output.contains("new@example.com"))
        #expect(output.contains("asc user-invitations cancel --invitation-id inv-1"))
    }

    @Test func `invite rejects invalid role`() async throws {
        let mockRepo = MockUserRepository()

        let cmd = try UserInvitationsInvite.parse([
            "--email", "x@example.com",
            "--first-name", "X",
            "--last-name", "Y",
            "--role", "SUPERUSER",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
