import Foundation
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
    func `should pass validation when the key is an individual key without an issuer ID`() throws {
        let creds = AuthCredentials(keyID: "KEY123", issuerID: nil, privateKeyPEM: "pem")
        try creds.validate()
    }

    @Test
    func `should leave the issuer ID out of the saved JSON when the key is an individual key`() throws {
        let creds = AuthCredentials(keyID: "KEY123", issuerID: nil, privateKeyPEM: "pem")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(creds), as: UTF8.self)
        #expect(json == #"{"keyID":"KEY123","privateKeyPEM":"pem"}"#)
    }

    @Test
    func `should read saved credentials without an issuer ID as an individual key`() throws {
        let json = #"{"keyID":"KEY123","privateKeyPEM":"pem"}"#
        let creds = try JSONDecoder().decode(AuthCredentials.self, from: Data(json.utf8))
        #expect(creds == AuthCredentials(keyID: "KEY123", issuerID: nil, privateKeyPEM: "pem"))
    }

    @Test
    func `missing private key throws error`() {
        let creds = AuthCredentials(keyID: "key", issuerID: "issuer", privateKeyPEM: "")
        #expect(throws: AuthError.missingPrivateKey) {
            try creds.validate()
        }
    }

    @Test
    func `credentials with vendor number preserves it`() {
        let creds = AuthCredentials(keyID: "key", issuerID: "issuer", privateKeyPEM: "pem", vendorNumber: "88012345")
        #expect(creds.vendorNumber == "88012345")
    }

    @Test
    func `credentials without vendor number defaults to nil`() {
        let creds = AuthCredentials(keyID: "key", issuerID: "issuer", privateKeyPEM: "pem")
        #expect(creds.vendorNumber == nil)
    }

    @Test
    func `credentials vendor number is omitted from JSON when nil`() throws {
        let creds = AuthCredentials(keyID: "key", issuerID: "issuer", privateKeyPEM: "pem")
        let data = try JSONEncoder().encode(creds)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("vendorNumber"))
    }

    @Test
    func `credentials vendor number is included in JSON when set`() throws {
        let creds = AuthCredentials(keyID: "key", issuerID: "issuer", privateKeyPEM: "pem", vendorNumber: "88012345")
        let data = try JSONEncoder().encode(creds)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("88012345"))
    }
}
