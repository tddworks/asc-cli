import Foundation
import Mockable

/// Apple's identity service (idmsa.apple.com): the SRP sign-in and the two-factor steps.
/// `IdmsaAPIClient` plays it over HTTP.
@Mockable
protocol AppleIDSignIn: Sendable {
    func signinInit(accountName: String, A: Data) async throws -> IdmsaAPIClient.SigninInitResponse
    func signinComplete(
        accountName: String, c: String, m1: Data, m2: Data,
        scnt: String, appleIDSessionID: String,
        hashcashChallenge: String?, hashcashBits: Int?,
        cookies: String
    ) async throws -> IdmsaAPIClient.SigninCompleteResult
    func fetchAuthOptions(scnt: String, appleIDSessionID: String, cookies: String) async throws -> String
    func submitTwoFactorCode(
        _ code: String, method: IdmsaAPIClient.TwoFactorMethod,
        scnt: String, appleIDSessionID: String, cookies: String
    ) async throws -> String
    func trust(scnt: String, appleIDSessionID: String, cookies: String) async throws -> String
}

/// The App Store Connect account a signed-in session belongs to (olympus): its
/// provider, team and email. `OlympusClient` plays it over HTTP.
@Mockable
protocol AppStoreConnectAccounts: Sendable {
    func fetchSession(cookies: String) async throws -> OlympusClient.OlympusSession
}

extension IdmsaAPIClient: AppleIDSignIn {}
extension OlympusClient: AppStoreConnectAccounts {}
