public enum AuthError: Error, Equatable, Sendable {
    case missingKeyID
    case missingIssuerID
    case missingPrivateKey
    case invalidPrivateKey(String)
    case tokenGenerationFailed(String)
}
