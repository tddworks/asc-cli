import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct JWTTokenGeneratorTests {

    // A valid EC P-256 private key for testing (not a real production key)
    private static let testPrivateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    @Test
    func `generates a valid JWT token`() throws {
        let generator = JWTTokenGenerator()
        let creds = AuthCredentials(
            keyID: "TEST_KEY_ID",
            issuerID: "TEST_ISSUER_ID",
            privateKeyPEM: Self.testPrivateKeyPEM
        )

        let token = try generator.generateToken(credentials: creds)
        let parts = token.split(separator: ".")
        #expect(parts.count == 3)

        // Decode header
        let headerData = try base64URLDecode(String(parts[0]))
        let header = try JSONDecoder().decode(JWTHeaderDTO.self, from: headerData)
        #expect(header.alg == "ES256")
        #expect(header.kid == "TEST_KEY_ID")
        #expect(header.typ == "JWT")

        // Decode payload
        let payloadData = try base64URLDecode(String(parts[1]))
        let payload = try JSONDecoder().decode(JWTPayloadDTO.self, from: payloadData)
        #expect(payload.iss == "TEST_ISSUER_ID")
        #expect(payload.aud == "appstoreconnect-v1")

        let now = Int(Date().timeIntervalSince1970)
        #expect(payload.iat <= now)
        #expect(payload.exp > now)
        #expect(payload.exp - payload.iat == 600) // 10 minutes
    }

    @Test
    func `throws for invalid private key`() {
        let generator = JWTTokenGenerator()
        let creds = AuthCredentials(
            keyID: "KEY",
            issuerID: "ISSUER",
            privateKeyPEM: "not-a-valid-key"
        )

        #expect(throws: AuthError.self) {
            try generator.generateToken(credentials: creds)
        }
    }

    private func base64URLDecode(_ string: String) throws -> Data {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            throw TestError.decodingFailed
        }
        return data
    }

    enum TestError: Error {
        case decodingFailed
    }
}

// DTOs for decoding in tests
private struct JWTHeaderDTO: Codable {
    let alg: String
    let kid: String
    let typ: String
}

private struct JWTPayloadDTO: Codable {
    let iss: String
    let iat: Int
    let exp: Int
    let aud: String
}
