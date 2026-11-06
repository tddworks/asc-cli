import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthLoginTests {

    @Test func `login without name defaults to default account name`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).save(.any, name: .value("default")).willReturn()
        given(mockStorage).setActive(name: .value("default")).willReturn()

        var cmd = try AuthLogin.parse([
            "--key-id", "KEY123",
            "--issuer-id", "ISSUER456",
            "--private-key", "fake-private-key-content",
            "--pretty",
        ])
        let output = try await cmd.execute(storage: mockStorage)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "check" : "asc auth check",
                "list" : "asc auth list",
                "login" : "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
                "logout" : "asc auth logout"
              },
              "issuerID" : "ISSUER456",
              "keyID" : "KEY123",
              "name" : "default",
              "source" : "file"
            }
          ]
        }
        """)
    }

    @Test func `should save an individual key when no issuer ID is given`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).save(.any, name: .value("default")).willReturn()
        given(mockStorage).setActive(name: .value("default")).willReturn()

        var cmd = try AuthLogin.parse([
            "--key-id", "KEY123",
            "--private-key", "fake-private-key-content",
            "--pretty",
        ])
        let output = try await cmd.execute(storage: mockStorage)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "check" : "asc auth check",
                "list" : "asc auth list",
                "login" : "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
                "logout" : "asc auth logout"
              },
              "keyID" : "KEY123",
              "name" : "default",
              "source" : "file"
            }
          ]
        }
        """)
    }

    @Test func `login saves credentials under custom name when provided`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).save(.any, name: .value("myorg")).willReturn()
        given(mockStorage).setActive(name: .value("myorg")).willReturn()

        var cmd = try AuthLogin.parse([
            "--key-id", "KEY123",
            "--issuer-id", "ISSUER456",
            "--private-key", "fake-private-key-content",
            "--name", "myorg",
            "--pretty",
        ])
        let output = try await cmd.execute(storage: mockStorage)

        #expect(output.contains("\"name\" : \"myorg\""))
    }

    @Test func `login throws when name contains whitespace`() async throws {
        let mockStorage = MockAuthStorage()

        var cmd = try AuthLogin.parse([
            "--key-id", "KEY123",
            "--issuer-id", "ISSUER456",
            "--private-key", "fake-private-key-content",
            "--name", "my org",
        ])

        await #expect(throws: (any Error).self) {
            try await cmd.execute(storage: mockStorage)
        }
    }

    @Test func `login throws when private key and path are both missing`() async throws {
        let mockStorage = MockAuthStorage()

        var cmd = try AuthLogin.parse([
            "--key-id", "KEY123",
            "--issuer-id", "ISSUER456",
        ])

        await #expect(throws: (any Error).self) {
            try await cmd.execute(storage: mockStorage)
        }
    }
}
