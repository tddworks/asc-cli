import Domain
import Foundation

/// Drives the full Apple ID SRP login + olympus session lookup, conforming to
/// `Domain.IrisAuthRepository`. Composition root for all the Apple-specific bits:
/// `AppleSRPClient` for crypto, `IdmsaAPIClient` for `idmsa.apple.com`, `OlympusClient`
/// for ASC team metadata.
public struct IrisAuthSDKRepository: IrisAuthRepository, @unchecked Sendable {
    private let idmsa: IdmsaAPIClient
    private let olympus: OlympusClient

    /// App Store Connect's widget key — long-stable. Apple's web UI fetches this
    /// dynamically; we hardcode the observed value as a constant. If Apple ever rotates
    /// it, login will fail with `invalidCredentials` and we'll need to re-fetch.
    public static let ascServiceKey = "e0b80c3bf78523bfe80974d320935bfa30add02e1bff88ec2166c6bd5a706c42"

    public init(
        session: URLSession = .shared,
        serviceKey: String = ascServiceKey
    ) {
        self.idmsa = IdmsaAPIClient(session: session, serviceKey: serviceKey)
        self.olympus = OlympusClient(session: session)
    }

    public func login(credentials: IrisAuthCredentials) async throws -> IrisAuthSession {
        let srp = AppleSRPClient()
        let A = srp.generatePublicEphemeral()

        let initResponse = try await idmsa.signinInit(accountName: credentials.appleId, A: A)

        let completion = try AppleSRPClient.Completion.compute(
            srp: srp, init: initResponse, password: credentials.password, accountName: credentials.appleId
        )

        let result = try await idmsa.signinComplete(
            accountName: credentials.appleId,
            c: initResponse.c,
            m1: completion.m1,
            m2: completion.m2Expected,
            scnt: initResponse.scnt,
            appleIDSessionID: initResponse.appleIDSessionID,
            hashcashChallenge: initResponse.hashcashChallenge,
            hashcashBits: initResponse.hashcashBits,
            cookies: initResponse.cookies
        )

        switch result {
        case .twoFactorRequired(let scnt, let sessionID, let cookies):
            // The cookie bag is the LIFELINE for the next CLI invocation: `verify-code`
            // runs in a separate process, so HTTPCookieStorage is wiped. We persist the
            // accumulated `aasp` (and friends) here and re-send them as Cookie header
            // on the verify and trust requests.
            let pending = PendingTwoFactorState(
                credentials: credentials,
                scnt: scnt, serviceKey: Self.ascServiceKey,
                appleIDSessionID: sessionID,
                twoFactorCookieBag: cookies,
                challenge: TwoFactorChallenge(method: .trustedDevice, maskedDestination: "Trusted devices", codeLength: 6)
            )
            throw IrisAuthError.twoFactorRequired(pending)

        case .success(let scnt, let cookies):
            return try await buildSession(
                cookies: cookies, scnt: scnt, sessionID: initResponse.appleIDSessionID,
                userEmail: credentials.appleId
            )
        }
    }

    public func submitTwoFactorCode(_ code: String, pending: PendingTwoFactorState) async throws -> IrisAuthSession {
        let cookiesAfterVerify: String
        do {
            cookiesAfterVerify = try await idmsa.submitTwoFactorCode(
                code, method: mapMethod(pending.challenge.method),
                scnt: pending.scnt, appleIDSessionID: pending.appleIDSessionID,
                cookies: pending.twoFactorCookieBag
            )
        } catch let e as IrisAuthError where e == .twoFactorCodeRejected(remainingAttempts: nil) {
            throw e
        }
        let cookies = try await idmsa.trust(
            scnt: pending.scnt, appleIDSessionID: pending.appleIDSessionID,
            cookies: cookiesAfterVerify
        )
        return try await buildSession(
            cookies: cookies, scnt: pending.scnt, sessionID: pending.appleIDSessionID,
            userEmail: pending.credentials.appleId
        )
    }

    private func buildSession(
        cookies: String, scnt: String, sessionID: String, userEmail: String
    ) async throws -> IrisAuthSession {
        let olympusSession = try await olympus.fetchSession(cookies: cookies)
        // Best-guess expiry — iris cookies typically last ~30 days. We rebuild on
        // expiry since iris exposes no refresh endpoint.
        let expiresAt = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return IrisAuthSession(
            cookies: cookies,
            scnt: scnt,
            serviceKey: Self.ascServiceKey,
            appleIDSessionID: sessionID,
            providerID: olympusSession.providerID,
            teamId: olympusSession.teamId,
            userEmail: olympusSession.userEmail.isEmpty ? userEmail : olympusSession.userEmail,
            expiresAt: expiresAt
        )
    }

    private func mapMethod(_ method: TwoFactorChallenge.Method) -> IdmsaAPIClient.TwoFactorMethod {
        switch method {
        case .trustedDevice: return .trustedDevice
        case .phone: return .phone
        }
    }
}

extension AppleSRPClient.Completion {
    /// Internal helper — composes the full SRP `complete` step from the `signin/init` response.
    static func compute(
        srp: AppleSRPClient,
        init initResponse: IdmsaAPIClient.SigninInitResponse,
        password: String,
        accountName: String
    ) throws -> AppleSRPClient.Completion {
        try srp.completeWith(
            salt: initResponse.salt,
            serverPublicKey: initResponse.b,
            iterations: initResponse.iteration,
            protocol: initResponse.protocolType,
            password: password,
            accountName: accountName
        )
    }
}
