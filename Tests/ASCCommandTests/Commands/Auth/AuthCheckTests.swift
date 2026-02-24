import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AuthCheckTests {

    @Test func `auth check shows file source when file credentials exist`() async throws {
        let mockFile = MockAuthProvider()
        let mockEnv = MockAuthProvider()
        let credentials = AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: "key")
        given(mockFile).resolve().willReturn(credentials)

        let cmd = try AuthCheck.parse(["--pretty"])
        let output = try await cmd.execute(fileProvider: mockFile, envProvider: mockEnv)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "check" : "asc auth check",
                "login" : "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
                "logout" : "asc auth logout"
              },
              "issuerID" : "ISSUER456",
              "keyID" : "KEY123",
              "source" : "file"
            }
          ]
        }
        """)
    }

    @Test func `auth check shows environment source when file provider fails`() async throws {
        let mockFile = MockAuthProvider()
        let mockEnv = MockAuthProvider()
        let credentials = AuthCredentials(keyID: "ENV_KEY", issuerID: "ENV_ISSUER", privateKeyPEM: "key")
        given(mockFile).resolve().willThrow(AuthError.missingKeyID)
        given(mockEnv).resolve().willReturn(credentials)

        let cmd = try AuthCheck.parse(["--pretty"])
        let output = try await cmd.execute(fileProvider: mockFile, envProvider: mockEnv)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "check" : "asc auth check",
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

    @Test func `auth check throws when both providers fail`() async throws {
        let mockFile = MockAuthProvider()
        let mockEnv = MockAuthProvider()
        given(mockFile).resolve().willThrow(AuthError.missingKeyID)
        given(mockEnv).resolve().willThrow(AuthError.missingPrivateKey)

        let cmd = try AuthCheck.parse([])

        await #expect(throws: AuthError.missingPrivateKey) {
            try await cmd.execute(fileProvider: mockFile, envProvider: mockEnv)
        }
    }
}
