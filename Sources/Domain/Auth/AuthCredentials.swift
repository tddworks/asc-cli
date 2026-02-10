public struct AuthCredentials: Sendable, Equatable {
    public let keyID: String
    public let issuerID: String
    public let privateKeyPEM: String

    public init(keyID: String, issuerID: String, privateKeyPEM: String) {
        self.keyID = keyID
        self.issuerID = issuerID
        self.privateKeyPEM = privateKeyPEM
    }

    public func validate() throws {
        guard !keyID.isEmpty else {
            throw AuthError.missingKeyID
        }
        guard !issuerID.isEmpty else {
            throw AuthError.missingIssuerID
        }
        guard !privateKeyPEM.isEmpty else {
            throw AuthError.missingPrivateKey
        }
    }
}
