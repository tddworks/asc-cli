import Foundation
import Mockable

/// Drives the iris SRP login + 2FA flow against `idmsa.apple.com`.
///
/// Implementations live in Infrastructure (`IrisAuthSDKRepository`). The protocol stays
/// here so commands and tests don't have to know about Apple's HTTP shape.
@Mockable
public protocol IrisAuthRepository: Sendable {
    /// Drives `signin/init` + `signin/complete`.
    /// - Returns: a fully-formed `IrisAuthSession` when no 2FA is required.
    /// - Throws: `IrisAuthError.twoFactorRequired(_)` carrying the state needed to resume,
    ///           `IrisAuthError.invalidCredentials`, `.applePromptRequired`, `.networkFailure`.
    func login(credentials: IrisAuthCredentials) async throws -> IrisAuthSession

    /// Submits the 6-digit 2FA code, hits the trust endpoint, then `olympus/v1/session`.
    func submitTwoFactorCode(_ code: String, pending: PendingTwoFactorState) async throws -> IrisAuthSession
}
