import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct UserInvitationsCancelTests {

    @Test func `cancel calls repository with invitation id`() async throws {
        let mockRepo = MockUserRepository()
        given(mockRepo).cancelUserInvitation(id: .value("inv-1")).willReturn()

        let cmd = try UserInvitationsCancel.parse(["--invitation-id", "inv-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).cancelUserInvitation(id: .value("inv-1")).called(1)
    }
}
