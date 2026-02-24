public struct AuthStatus: Sendable, Equatable, Codable, Identifiable {
    public let keyID: String
    public let issuerID: String
    public let source: CredentialSource

    public var id: String { keyID }

    public init(keyID: String, issuerID: String, source: CredentialSource) {
        self.keyID = keyID
        self.issuerID = issuerID
        self.source = source
    }
}

extension AuthStatus: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "check": "asc auth check",
            "login": "asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>",
            "logout": "asc auth logout",
        ]
    }
}
