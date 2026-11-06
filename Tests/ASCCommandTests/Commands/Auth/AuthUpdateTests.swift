import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthUpdateTests {

    @Test func `update adds vendor number to active account`() async throws {
        let mockStorage = MockAuthStorage()
        let credentials = AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: "pem")
        let accounts = [ConnectAccount(name: "default", keyID: "KEY123", issuerID: "ISSUER456", isActive: true)]
        given(mockStorage).loadAll().willReturn(accounts)
        given(mockStorage).load(name: .value("default")).willReturn(credentials)
        given(mockStorage).save(.any, name: .value("default")).willReturn()

        let cmd = try AuthUpdate.parse(["--vendor-number", "88012345", "--pretty"])
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
              "source" : "file",
              "vendorNumber" : "88012345"
            }
          ]
        }
        """)
    }

    @Test func `should keep the account an individual key when adding a vendor number`() async throws {
        let mockStorage = MockAuthStorage()
        let credentials = AuthCredentials(keyID: "KEY123", issuerID: nil, privateKeyPEM: "pem")
        given(mockStorage).load(name: .value("me")).willReturn(credentials)
        given(mockStorage).save(.any, name: .value("me")).willReturn()

        let cmd = try AuthUpdate.parse(["--name", "me", "--vendor-number", "88012345", "--pretty"])
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
              "name" : "me",
              "source" : "file",
              "vendorNumber" : "88012345"
            }
          ]
        }
        """)
    }

    @Test func `update adds vendor number to named account`() async throws {
        let mockStorage = MockAuthStorage()
        let credentials = AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: "pem")
        given(mockStorage).load(name: .value("work")).willReturn(credentials)
        given(mockStorage).save(.any, name: .value("work")).willReturn()

        let cmd = try AuthUpdate.parse(["--name", "work", "--vendor-number", "88012345", "--pretty"])
        let output = try await cmd.execute(storage: mockStorage)

        #expect(output.contains("\"vendorNumber\" : \"88012345\""))
    }

    @Test func `update throws when account not found`() async throws {
        let mockStorage = MockAuthStorage()
        given(mockStorage).load(name: .value("ghost")).willReturn(nil)

        let cmd = try AuthUpdate.parse(["--name", "ghost", "--vendor-number", "88012345"])

        await #expect(throws: AuthError.self) {
            try await cmd.execute(storage: mockStorage)
        }
    }

    @Test func `update throws when no flags provided`() async throws {
        let mockStorage = MockAuthStorage()
        let accounts = [ConnectAccount(name: "default", keyID: "KEY123", issuerID: "ISSUER456", isActive: true)]
        given(mockStorage).loadAll().willReturn(accounts)

        let cmd = try AuthUpdate.parse([])

        await #expect(throws: (any Error).self) {
            try await cmd.execute(storage: mockStorage)
        }
    }
}
