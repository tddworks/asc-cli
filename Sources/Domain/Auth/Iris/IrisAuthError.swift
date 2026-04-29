import Foundation

/// Outcomes of an iris login that callers (CLI / REST) need to react to differently.
public enum IrisAuthError: LocalizedError, Equatable {
    case invalidCredentials
    case twoFactorRequired(PendingTwoFactorState)
    case twoFactorCodeRejected(remainingAttempts: Int?)
    /// Apple wants the user to acknowledge a privacy / 2FA-upgrade prompt that only a
    /// real browser can render. We can't bypass it programmatically — point the user
    /// at Safari, then retry login.
    case applePromptRequired
    case sessionExpired
    case networkFailure(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Incorrect Apple Account email or password."
        case .twoFactorRequired:
            return "Two-factor authentication required. Run `asc iris auth verify-code <code>` after retrieving the code."
        case .twoFactorCodeRejected(let remaining):
            if let remaining {
                return "Two-factor code rejected (\(remaining) attempt\(remaining == 1 ? "" : "s") remaining)."
            }
            return "Two-factor code rejected."
        case .applePromptRequired:
            return "Apple needs you to complete a prompt in a browser. Sign in to appstoreconnect.apple.com once, then retry."
        case .sessionExpired:
            return "Iris session expired. Re-run `asc iris auth login`."
        case .networkFailure(let message):
            return "Network failure talking to idmsa.apple.com: \(message)"
        }
    }
}
