import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct ProfilesDeleteTests {

    @Test func `execute deletes profile`() async throws {
        let mockRepo = MockProfileRepository()
        given(mockRepo).deleteProfile(id: .any).willReturn()

        let cmd = try ProfilesDelete.parse(["--profile-id", "prof-42"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteProfile(id: .value("prof-42")).called(.once)
    }
}
