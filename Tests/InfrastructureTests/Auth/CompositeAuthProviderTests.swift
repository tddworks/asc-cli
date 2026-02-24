import Mockable
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct CompositeAuthProviderTests {

    @Test func `resolves from file provider when file credentials exist`() throws {
        let mockFile = MockAuthProvider()
        let mockEnv = MockAuthProvider()
        let expected = AuthCredentials(keyID: "FILE_KEY", issuerID: "FILE_ISSUER", privateKeyPEM: "key")
        given(mockFile).resolve().willReturn(expected)

        let composite = CompositeAuthProvider(fileProvider: mockFile, environmentProvider: mockEnv)
        let resolved = try composite.resolve()

        #expect(resolved == expected)
    }

    @Test func `falls back to environment when file provider throws`() throws {
        let mockFile = MockAuthProvider()
        let mockEnv = MockAuthProvider()
        let expected = AuthCredentials(keyID: "ENV_KEY", issuerID: "ENV_ISSUER", privateKeyPEM: "key")
        given(mockFile).resolve().willThrow(AuthError.missingKeyID)
        given(mockEnv).resolve().willReturn(expected)

        let composite = CompositeAuthProvider(fileProvider: mockFile, environmentProvider: mockEnv)
        let resolved = try composite.resolve()

        #expect(resolved == expected)
    }

    @Test func `throws environment error when both providers fail`() throws {
        let mockFile = MockAuthProvider()
        let mockEnv = MockAuthProvider()
        given(mockFile).resolve().willThrow(AuthError.missingKeyID)
        given(mockEnv).resolve().willThrow(AuthError.missingIssuerID)

        let composite = CompositeAuthProvider(fileProvider: mockFile, environmentProvider: mockEnv)

        #expect(throws: AuthError.missingIssuerID) {
            try composite.resolve()
        }
    }
}
