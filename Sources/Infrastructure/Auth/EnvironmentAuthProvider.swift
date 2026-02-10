import Domain
import Foundation

public struct EnvironmentAuthProvider: AuthProvider {
    private let environment: [String: String]
    private let keyLoader: PrivateKeyLoader

    public init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        keyLoader: PrivateKeyLoader = PrivateKeyLoader()
    ) {
        self.environment = environment
        self.keyLoader = keyLoader
    }

    public func resolve() throws -> AuthCredentials {
        guard let keyID = environment["ASC_KEY_ID"], !keyID.isEmpty else {
            throw AuthError.missingKeyID
        }
        guard let issuerID = environment["ASC_ISSUER_ID"], !issuerID.isEmpty else {
            throw AuthError.missingIssuerID
        }

        let privateKeyPEM: String

        if let keyPath = environment["ASC_PRIVATE_KEY_PATH"], !keyPath.isEmpty {
            privateKeyPEM = try keyLoader.loadFromFile(path: keyPath)
        } else if let keyBase64 = environment["ASC_PRIVATE_KEY_B64"], !keyBase64.isEmpty {
            privateKeyPEM = try keyLoader.loadFromBase64(keyBase64)
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
