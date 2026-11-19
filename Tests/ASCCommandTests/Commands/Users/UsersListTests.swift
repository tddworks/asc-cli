import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct UsersListTests {

    @Test func `listed users include roles and affordances`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).listUsers(role: .any).willReturn([
            TeamMember(
                id: "u-1",
                username: "jdoe@example.com",
                firstName: "Jane",
                lastName: "Doe",
                roles: [.developer, .appManager],
                isAllAppsVisible: false,
                isProvisioningAllowed: true
            ),
        ])

        let cmd = try UsersList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\" : \"u-1\""))
        #expect(output.contains("\"username\" : \"jdoe@example.com\""))
        #expect(output.contains("DEVELOPER"))
        #expect(output.contains("APP_MANAGER"))
        #expect(output.contains("asc users remove --user-id u-1"))
        #expect(output.contains("asc users update --user-id u-1"))
    }

    @Test func `table output includes username and roles`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).listUsers(role: .any).willReturn([
            TeamMember(
                id: "u-1",
                username: "jdoe@example.com",
                firstName: "Jane",
                lastName: "Doe",
                roles: [.admin],
                isAllAppsVisible: true,
                isProvisioningAllowed: false
            ),
        ])

        let cmd = try UsersList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("u-1"))
        #expect(output.contains("jdoe@example.com"))
        #expect(output.contains("ADMIN"))
    }

    @Test func `role filter is passed to repository`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).listUsers(role: .value(.developer)).willReturn([
            TeamMember(
                id: "u-2",
                username: "dev@example.com",
                firstName: "Dev",
                lastName: "User",
                roles: [.developer],
                isAllAppsVisible: false,
                isProvisioningAllowed: false
            ),
        ])

        let cmd = try UsersList.parse(["--role", "DEVELOPER", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("DEVELOPER"))
        #expect(output.contains("dev@example.com"))
    }
}
