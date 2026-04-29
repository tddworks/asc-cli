import Foundation

/// Snapshot of a login that's halfway through — SRP succeeded, 2FA still owed.
///
/// Persisted between `asc iris auth login` (which returns this when 2FA is required)
/// and `asc iris auth verify-code` (which consumes it to complete the flow). Holding
/// the credentials here is a deliberate trade-off: we need them for the 2FA step's
/// session continuation, but the file lives in the same protected location as the
/// final session and is wiped on success / failure.
public struct PendingTwoFactorState: Sendable, Equatable, Codable {
    public let credentials: IrisAuthCredentials
    public let scnt: String
    public let serviceKey: String
    public let appleIDSessionID: String
    public let twoFactorCookieBag: String
    public let challenge: TwoFactorChallenge

    public init(
        credentials: IrisAuthCredentials,
        scnt: String,
        serviceKey: String,
        appleIDSessionID: String,
        twoFactorCookieBag: String,
        challenge: TwoFactorChallenge
    ) {
        self.credentials = credentials
        self.scnt = scnt
        self.serviceKey = serviceKey
        self.appleIDSessionID = appleIDSessionID
        self.twoFactorCookieBag = twoFactorCookieBag
        self.challenge = challenge
    }
}
