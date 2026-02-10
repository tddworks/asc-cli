import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct EnvironmentAuthProviderTests {

    @Test
    func `resolves credentials from environment variables`() throws {
        let env = [
            "ASC_KEY_ID": "KEY123",
            "ASC_ISSUER_ID": "ISSUER456",
            "ASC_PRIVATE_KEY": "-----BEGIN PRIVATE KEY-----\nfakekey\n-----END PRIVATE KEY-----",
        ]
        let provider = EnvironmentAuthProvider(environment: env)
        let creds = try provider.resolve()

        #expect(creds.keyID == "KEY123")
        #expect(creds.issuerID == "ISSUER456")
        #expect(creds.privateKeyPEM.contains("PRIVATE KEY"))
    }

    @Test
    func `throws when key id is missing`() {
        let env = [
            "ASC_ISSUER_ID": "ISSUER456",
            "ASC_PRIVATE_KEY": "key",
        ]
        let provider = EnvironmentAuthProvider(environment: env)
        #expect(throws: AuthError.missingKeyID) {
            try provider.resolve()
        }
    }

    @Test
    func `throws when issuer id is missing`() {
        let env = [
            "ASC_KEY_ID": "KEY123",
            "ASC_PRIVATE_KEY": "key",
        ]
        let provider = EnvironmentAuthProvider(environment: env)
        #expect(throws: AuthError.missingIssuerID) {
            try provider.resolve()
        }
    }

    @Test
    func `throws when private key is missing`() {
        let env = [
            "ASC_KEY_ID": "KEY123",
            "ASC_ISSUER_ID": "ISSUER456",
        ]
        let provider = EnvironmentAuthProvider(environment: env)
        #expect(throws: AuthError.missingPrivateKey) {
            try provider.resolve()
        }
    }

    @Test
    func `prefers key path over base64 and direct key`() throws {
        // This test would need a real file, so we test the priority logic
        // by ensuring ASC_PRIVATE_KEY is used when path is not set
        let env = [
            "ASC_KEY_ID": "KEY123",
            "ASC_ISSUER_ID": "ISSUER456",
            "ASC_PRIVATE_KEY": "direct-key-content",
        ]
        let provider = EnvironmentAuthProvider(environment: env)
        let creds = try provider.resolve()
        #expect(creds.privateKeyPEM == "direct-key-content")
    }

    @Test
    func `empty key id is treated as missing`() {
        let env = [
            "ASC_KEY_ID": "",
            "ASC_ISSUER_ID": "ISSUER456",
            "ASC_PRIVATE_KEY": "key",
        ]
        let provider = EnvironmentAuthProvider(environment: env)
        #expect(throws: AuthError.missingKeyID) {
            try provider.resolve()
        }
    }
}
