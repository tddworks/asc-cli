import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct UsersRemoveTests {

    @Test func `remove calls repository with user id`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).removeUser(id: .value("u-1")).willReturn()

        let cmd = try UsersRemove.parse(["--user-id", "u-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).removeUser(id: .value("u-1")).called(1)
    }
}
