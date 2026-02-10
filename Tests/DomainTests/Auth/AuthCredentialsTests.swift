import Testing
@testable import Domain

@Suite
struct AuthCredentialsTests {

    @Test
    func `valid credentials pass validation`() throws {
        let creds = AuthCredentials(
            keyID: "ABC123",
            issuerID: "issuer-uuid",
            privateKeyPEM: "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----"
        )
        try creds.validate()
    }

    @Test
    func `missing key id throws error`() {
        let creds = AuthCredentials(keyID: "", issuerID: "issuer", privateKeyPEM: "key")
        #expect(throws: AuthError.missingKeyID) {
            try creds.validate()
        }
    }

    @Test
    func `missing issuer id throws error`() {
        let creds = AuthCredentials(keyID: "key", issuerID: "", privateKeyPEM: "key")
        #expect(throws: AuthError.missingIssuerID) {
            try creds.validate()
        }
    }

    @Test
    func `missing private key throws error`() {
        let creds = AuthCredentials(keyID: "key", issuerID: "issuer", privateKeyPEM: "")
        #expect(throws: AuthError.missingPrivateKey) {
            try creds.validate()
        }
    }

    @Test
    func `credentials are equatable`() {
        let a = AuthCredentials(keyID: "k", issuerID: "i", privateKeyPEM: "p")
        let b = AuthCredentials(keyID: "k", issuerID: "i", privateKeyPEM: "p")
        #expect(a == b)
    }
}
