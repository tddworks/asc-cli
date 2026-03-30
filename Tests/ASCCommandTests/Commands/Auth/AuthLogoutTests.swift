import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthLogoutTests {

    @Test func `accepts global options including pretty`() throws {
        let cmd = try AuthLogout.parse(["--pretty"])
        #expect(cmd.globals.pretty == true)
    }

    @Test func `logout calls delete with nil name when no name provided`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).delete(name: .any).willReturn()

        let cmd = try AuthLogout.parse([])
        try await cmd.execute(storage: mockStorage)

        verify(mockStorage).delete(name: .value(nil)).called(.once)
    }

    @Test func `logout calls delete with specified name`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).delete(name: .any).willReturn()

        let cmd = try AuthLogout.parse(["--name", "work"])
        try await cmd.execute(storage: mockStorage)

        verify(mockStorage).delete(name: .value("work")).called(.once)
    }
}
