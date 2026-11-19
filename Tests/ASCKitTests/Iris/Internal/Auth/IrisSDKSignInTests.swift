import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct IrisSDKSignInTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let credentials = IrisAuthCredentials(appleId: "dev@example.com", password: "secret")
    private let trustedDevice = TwoFactorChallenge(method: .trustedDevice, maskedDestination: "Trusted devices", codeLength: 6)

    private var pending: PendingTwoFactorState {
        PendingTwoFactorState(
            credentials: credentials, scnt: "scnt-1", serviceKey: IrisSDKSignIn.ascServiceKey,
            appleIDSessionID: "session-1", twoFactorCookieBag: "aasp=1", challenge: trustedDevice
        )
    }

    private func signInStartedByApple() -> MockAppleIDSignIn {
        let signIn = MockAppleIDSignIn()
        given(signIn).signinInit(accountName: .any, A: .any).willReturn(IdmsaAPIClient.SigninInitResponse(
            iteration: 1000, salt: Data(repeating: 7, count: 16), b: Data(repeating: 9, count: 256), c: "c-1",
            protocolType: .s2k, scnt: "scnt-0", appleIDSessionID: "session-1",
            hashcashChallenge: nil, hashcashBits: nil, cookies: "aasp=1"
        ))
        return signIn
    }

    private func accounts(email: String, teamId: String?) -> MockAppStoreConnectAccounts {
        let accounts = MockAppStoreConnectAccounts()
        given(accounts).fetchSession(cookies: .any)
            .willReturn(OlympusClient.OlympusSession(providerID: 42, teamId: teamId, userEmail: email))
        return accounts
    }

    @Test func `should ask for a code from a trusted device when Apple wants two-factor`() async throws {
        let signIn = signInStartedByApple()
        given(signIn).signinComplete(
            accountName: .any, c: .any, m1: .any, m2: .any, scnt: .any, appleIDSessionID: .any,
            hashcashChallenge: .any, hashcashBits: .any, cookies: .any
        ).willReturn(.twoFactorRequired(scnt: "scnt-2fa", appleIDSessionID: "session-1", cookies: "aasp=1; dslang=GB"))
        let repo = IrisSDKSignIn(signIn: signIn, accounts: accounts(email: "", teamId: nil), now: { now })

        do {
            _ = try await repo.login(credentials: credentials)
            Issue.record("expected two-factor to be required")
        } catch IrisAuthError.twoFactorRequired(let state) {
            #expect(state == PendingTwoFactorState(
                credentials: credentials, scnt: "scnt-2fa", serviceKey: IrisSDKSignIn.ascServiceKey,
                appleIDSessionID: "session-1", twoFactorCookieBag: "aasp=1; dslang=GB", challenge: trustedDevice
            ))
        }
    }

    @Test func `should sign in for thirty days when Apple needs no second factor`() async throws {
        let signIn = signInStartedByApple()
        given(signIn).signinComplete(
            accountName: .any, c: .any, m1: .any, m2: .any, scnt: .any, appleIDSessionID: .any,
            hashcashChallenge: .any, hashcashBits: .any, cookies: .any
        ).willReturn(.success(scnt: "scnt-ok", cookies: "myacinfo=a"))
        let repo = IrisSDKSignIn(signIn: signIn, accounts: accounts(email: "team@example.com", teamId: "TEAM1"), now: { now })

        let session = try await repo.login(credentials: credentials)

        #expect(session == IrisAuthSession(
            cookies: "myacinfo=a", scnt: "scnt-ok", serviceKey: IrisSDKSignIn.ascServiceKey,
            appleIDSessionID: "session-1", providerID: 42, teamId: "TEAM1", userEmail: "team@example.com",
            expiresAt: now.addingTimeInterval(30 * 24 * 60 * 60)
        ))
    }

    @Test func `should sign in with the team olympus names after a correct code`() async throws {
        let signIn = MockAppleIDSignIn()
        given(signIn).fetchAuthOptions(scnt: .any, appleIDSessionID: .any, cookies: .any).willReturn("aasp=1")
        given(signIn).submitTwoFactorCode(.any, method: .any, scnt: .any, appleIDSessionID: .any, cookies: .any).willReturn("aasp=1; verified=1")
        given(signIn).trust(scnt: .any, appleIDSessionID: .any, cookies: .any).willReturn("myacinfo=a; trusted=1")
        let repo = IrisSDKSignIn(signIn: signIn, accounts: accounts(email: "team@example.com", teamId: "TEAM1"), now: { now })

        let session = try await repo.submitTwoFactorCode("123456", pending: pending)

        #expect(session == IrisAuthSession(
            cookies: "myacinfo=a; trusted=1", scnt: "scnt-1", serviceKey: IrisSDKSignIn.ascServiceKey,
            appleIDSessionID: "session-1", providerID: 42, teamId: "TEAM1", userEmail: "team@example.com",
            expiresAt: now.addingTimeInterval(30 * 24 * 60 * 60)
        ))
    }

    @Test func `should name the session after the Apple ID when olympus gives no email`() async throws {
        let signIn = MockAppleIDSignIn()
        given(signIn).fetchAuthOptions(scnt: .any, appleIDSessionID: .any, cookies: .any).willReturn("aasp=1")
        given(signIn).submitTwoFactorCode(.any, method: .any, scnt: .any, appleIDSessionID: .any, cookies: .any).willReturn("aasp=1")
        given(signIn).trust(scnt: .any, appleIDSessionID: .any, cookies: .any).willReturn("myacinfo=a")
        let repo = IrisSDKSignIn(signIn: signIn, accounts: accounts(email: "", teamId: nil), now: { now })

        let session = try await repo.submitTwoFactorCode("123456", pending: pending)

        #expect(session.userEmail == "dev@example.com")
        #expect(session.teamId == nil)
    }

    @Test func `should not sign in when Apple rejects the code`() async {
        let signIn = MockAppleIDSignIn()
        given(signIn).fetchAuthOptions(scnt: .any, appleIDSessionID: .any, cookies: .any).willReturn("aasp=1")
        given(signIn).submitTwoFactorCode(.any, method: .any, scnt: .any, appleIDSessionID: .any, cookies: .any)
            .willThrow(IrisAuthError.twoFactorCodeRejected(remainingAttempts: nil))
        let repo = IrisSDKSignIn(signIn: signIn, accounts: accounts(email: "", teamId: nil), now: { now })

        await #expect(throws: IrisAuthError.twoFactorCodeRejected(remainingAttempts: nil)) {
            try await repo.submitTwoFactorCode("000000", pending: pending)
        }
    }
}
