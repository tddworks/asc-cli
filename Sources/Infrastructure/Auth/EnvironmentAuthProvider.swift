import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct EnvironmentAuthProvider: AuthProvider {
    private let environment: [String: String]

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    public func resolve() throws -> AuthCredentials {
        guard let keyID = environment["ASC_KEY_ID"], !keyID.isEmpty else {
            throw AuthError.missingKeyID
        }
        // No issuer ID means an individual API key.
        let issuerID = environment["ASC_ISSUER_ID"].flatMap { $0.isEmpty ? nil : $0 }

        let privateKeyPEM: String

        if let keyPath = environment["ASC_PRIVATE_KEY_PATH"], !keyPath.isEmpty {
            let expandedPath = NSString(string: keyPath).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            privateKeyPEM = try String(contentsOf: url, encoding: .utf8)
        } else if let keyBase64 = environment["ASC_PRIVATE_KEY_B64"], !keyBase64.isEmpty {
            guard let data = Data(base64Encoded: keyBase64),
                  let pem = String(data: data, encoding: .utf8) else {
                throw AuthError.invalidPrivateKey("Invalid base64 encoding")
            }
            privateKeyPEM = pem
        } else if let keyDirect = environment["ASC_PRIVATE_KEY"], !keyDirect.isEmpty {
            privateKeyPEM = keyDirect
        } else {
            throw AuthError.missingPrivateKey
        }

        let credentials = AuthCredentials(keyID: keyID, issuerID: issuerID, privateKeyPEM: privateKeyPEM)
        try credentials.validate()
        return credentials
    }
}
