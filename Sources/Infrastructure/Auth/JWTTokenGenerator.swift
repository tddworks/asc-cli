import Crypto
import Foundation

public struct JWTTokenGenerator: Sendable {
    private static let tokenLifetime: TimeInterval = 10 * 60 // 10 minutes

    public init() {}

    public func generateToken(credentials: Domain.AuthCredentials) throws -> String {
        let privateKey = try loadPrivateKey(pem: credentials.privateKeyPEM)
        let now = Date()

        let header = JWTHeader(alg: "ES256", kid: credentials.keyID, typ: "JWT")
        let payload = JWTPayload(
            iss: credentials.issuerID,
            iat: Int(now.timeIntervalSince1970),
            exp: Int(now.addingTimeInterval(Self.tokenLifetime).timeIntervalSince1970),
            aud: "appstoreconnect-v1"
        )

        let headerData = try JSONEncoder().encode(header)
        let payloadData = try JSONEncoder().encode(payload)

        let headerBase64 = headerData.base64URLEncoded()
        let payloadBase64 = payloadData.base64URLEncoded()

        let signingInput = "\(headerBase64).\(payloadBase64)"

        guard let signingData = signingInput.data(using: .utf8) else {
            throw Domain.AuthError.tokenGenerationFailed("Failed to encode signing input")
        }

        let signature = try privateKey.signature(for: signingData)
        let signatureBase64 = signature.rawRepresentation.base64URLEncoded()

        return "\(signingInput).\(signatureBase64)"
    }

    private func loadPrivateKey(pem: String) throws -> P256.Signing.PrivateKey {
        let stripped = pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let keyData = Data(base64Encoded: stripped) else {
            throw Domain.AuthError.invalidPrivateKey("Failed to decode base64 key data")
        }

        do {
            return try P256.Signing.PrivateKey(derRepresentation: keyData)
        } catch {
            do {
                return try P256.Signing.PrivateKey(x963Representation: keyData)
            } catch {
                throw Domain.AuthError.invalidPrivateKey("Invalid EC private key format")
            }
        }
    }
}

struct JWTHeader: Codable {
    let alg: String
    let kid: String
    let typ: String
}

struct JWTPayload: Codable {
    let iss: String
    let iat: Int
    let exp: Int
    let aud: String
}

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
