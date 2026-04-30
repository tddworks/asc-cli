import Mockable
import Testing
@testable import Domain
@testable import Infrastructure

@Suite("FileAuthProvider — resolves credentials from storage")
struct FileAuthProviderTests {

    @Test func `resolve returns active credentials from storage`() throws {
        let storage = MockAuthStorage()
        let saved = AuthCredentials(
            keyID: "KEY123",
            issuerID: "ISSUER456",
            privateKeyPEM: "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----"
        )
        given(storage).load(name: .value(nil)).willReturn(saved)
        let provider = FileAuthProvider(storage: storage)

        let creds = try provider.resolve()

        #expect(creds.keyID == "KEY123")
        #expect(creds.issuerID == "ISSUER456")
        #expect(creds.privateKeyPEM.contains("PRIVATE KEY"))
    }

    @Test func `resolve throws missingKeyID when storage has no active credentials`() throws {
        let storage = MockAuthStorage()
        given(storage).load(name: .value(nil)).willReturn(nil)
        let provider = FileAuthProvider(storage: storage)

        #expect(throws: AuthError.missingKeyID) {
            try provider.resolve()
        }
    }

    @Test func `resolve validates and rejects credentials with empty keyID`() throws {
        let storage = MockAuthStorage()
        let invalid = AuthCredentials(keyID: "", issuerID: "ISSUER456", privateKeyPEM: "key")
        given(storage).load(name: .value(nil)).willReturn(invalid)
        let provider = FileAuthProvider(storage: storage)

        #expect(throws: AuthError.missingKeyID) {
            try provider.resolve()
        }
    }

    @Test func `resolve validates and rejects credentials with empty issuerID`() throws {
        let storage = MockAuthStorage()
        let invalid = AuthCredentials(keyID: "KEY123", issuerID: "", privateKeyPEM: "key")
        given(storage).load(name: .value(nil)).willReturn(invalid)
        let provider = FileAuthProvider(storage: storage)

        #expect(throws: AuthError.missingIssuerID) {
            try provider.resolve()
        }
    }

    @Test func `resolve validates and rejects credentials with empty privateKey`() throws {
        let storage = MockAuthStorage()
        let invalid = AuthCredentials(keyID: "KEY123", issuerID: "ISSUER456", privateKeyPEM: "")
        given(storage).load(name: .value(nil)).willReturn(invalid)
        let provider = FileAuthProvider(storage: storage)

        #expect(throws: AuthError.missingPrivateKey) {
            try provider.resolve()
        }
    }
}
