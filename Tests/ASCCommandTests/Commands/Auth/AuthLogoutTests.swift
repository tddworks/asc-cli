import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthLogoutTests {

    @Test func `logout calls delete on storage`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).delete().willReturn()

        let cmd = try AuthLogout.parse([])
        try await cmd.execute(storage: mockStorage)

        verify(mockStorage).delete().called(.once)
    }
}
