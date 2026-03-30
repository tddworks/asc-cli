import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthUseTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try AuthUse.parse(["work", "--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `auth use switches active account`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).setActive(name: .value("work")).willReturn()

        let cmd = try AuthUse.parse(["work"])
        try await cmd.execute(storage: mockStorage)

        verify(mockStorage).setActive(name: .value("work")).called(.once)
    }

    @Test func `auth use throws when account not found`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).setActive(name: .value("ghost")).willThrow(AuthError.accountNotFound("ghost"))

        let cmd = try AuthUse.parse(["ghost"])

        await #expect(throws: AuthError.accountNotFound("ghost")) {
            try await cmd.execute(storage: mockStorage)
        }
    }
}
