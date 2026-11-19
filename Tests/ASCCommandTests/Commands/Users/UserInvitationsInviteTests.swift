import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

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

    @Test func `invite with all-apps-visible passes flag to repository`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).inviteUser(
            email: .any,
            firstName: .any,
            lastName: .any,
            roles: .any,
            allAppsVisible: .value(true)
        ).willReturn(
            UserInvitationRecord(
                id: "inv-2",
                email: "admin@example.com",
                firstName: "Admin",
                lastName: "User",
                roles: [.admin],
                isAllAppsVisible: true,
                isProvisioningAllowed: false
            )
        )

        let cmd = try UserInvitationsInvite.parse([
            "--email", "admin@example.com",
            "--first-name", "Admin",
            "--last-name", "User",
            "--role", "ADMIN",
            "--all-apps-visible",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("inv-2"))
        #expect(output.contains("ADMIN"))
    }

    @Test func `invite role filter applied to invitations list`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).listUserInvitations(role: .value(.developer)).willReturn([
            UserInvitationRecord(
                id: "inv-3",
                email: "dev@example.com",
                firstName: "Dev",
                lastName: "User",
                roles: [.developer],
                isAllAppsVisible: false,
                isProvisioningAllowed: false
            ),
        ])

        let cmd = try UserInvitationsList.parse(["--role", "DEVELOPER", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("dev@example.com"))
        #expect(output.contains("DEVELOPER"))
    }
}
