import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct UsersUpdateTests {

    @Test func `update returns team member with new roles`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).updateUser(id: .any, roles: .any).willReturn(
            TeamMember(
                id: "u-1",
                username: "jdoe@example.com",
                firstName: "Jane",
                lastName: "Doe",
                roles: [.admin],
                isAllAppsVisible: false,
                isProvisioningAllowed: false
            )
        )

        let cmd = try UsersUpdate.parse(["--user-id", "u-1", "--role", "ADMIN", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("ADMIN"))
        #expect(output.contains("u-1"))
    }

    @Test func `update rejects invalid role`() async throws {
        let mockRepo = MockUserRepository()

        let cmd = try UsersUpdate.parse(["--user-id", "u-1", "--role", "INVALID"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
