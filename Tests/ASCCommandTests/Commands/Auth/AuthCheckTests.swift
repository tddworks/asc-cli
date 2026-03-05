import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthCheckTests {

    @Test func `auth check shows file source with account name when active account exists`() async throws {
        let mockStorage = MockAuthStorage()
        let mockEnv = MockAuthProvider()
        let credentials = AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: "key")
        let accounts = [ConnectAccount(name: "work", keyID: "KEY123", issuerID: "ISSUER456", isActive: true)]
        given(mockStorage).load(name: .value(nil)).willReturn(credentials)
        given(mockStorage).loadAll().willReturn(accounts)

        let cmd = try AuthCheck.parse(["--pretty"])
        let output = try await cmd.execute(storage: mockStorage, envProvider: mockEnv)

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
              "name" : "work",
              "source" : "file"
            }
          ]
        }
        """)
    }

    @Test func `auth check shows environment source when no active account`() async throws {
        let mockStorage = MockAuthStorage()
        let mockEnv = MockAuthProvider()
        let credentials = AuthCredentials(keyID: "ENV_KEY", issuerID: "ENV_ISSUER", privateKeyPEM: "key")
        given(mockStorage).load(name: .value(nil)).willReturn(nil)
        given(mockEnv).resolve().willReturn(credentials)

        let cmd = try AuthCheck.parse(["--pretty"])
        let output = try await cmd.execute(storage: mockStorage, envProvider: mockEnv)

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
              "issuerID" : "ENV_ISSUER",
              "keyID" : "ENV_KEY",
              "source" : "environment"
            }
          ]
        }
        """)
    }

    @Test func `auth check throws when both storage empty and env provider fails`() async throws {
        let mockStorage = MockAuthStorage()
        let mockEnv = MockAuthProvider()
        given(mockStorage).load(name: .value(nil)).willReturn(nil)
        given(mockEnv).resolve().willThrow(AuthError.missingPrivateKey)

        let cmd = try AuthCheck.parse([])

        await #expect(throws: AuthError.missingPrivateKey) {
            try await cmd.execute(storage: mockStorage, envProvider: mockEnv)
        }
    }
}
