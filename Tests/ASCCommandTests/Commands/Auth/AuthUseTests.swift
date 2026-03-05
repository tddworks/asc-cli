import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthUseTests {

    @Test func `auth use switches active account`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).setActive(name: .value("work")).willReturn()

        var cmd = try AuthUse.parse(["work"])
        try await cmd.execute(storage: mockStorage)

        verify(mockStorage).setActive(name: .value("work")).called(.once)
    }

    @Test func `auth use throws when account not found`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).setActive(name: .value("ghost")).willThrow(AuthError.accountNotFound("ghost"))

        var cmd = try AuthUse.parse(["ghost"])

        await #expect(throws: AuthError.accountNotFound("ghost")) {
            try await cmd.execute(storage: mockStorage)
        }
    }
}
