import Foundation
import Testing
@testable import Domain

@Suite
struct IrisAuthTypesTests {

    // MARK: - IrisAuthCredentials

    @Test func `iris auth credentials carry apple id and password`() {
        let creds = IrisAuthCredentials(appleId: "user@example.com", password: "secret")
        #expect(creds.appleId == "user@example.com")
        #expect(creds.password == "secret")
    }

    // MARK: - IrisAuthSession

    @Test func `iris auth session roundtrips through codable`() throws {
        let session = IrisAuthSession(
            cookies: "myacinfo=A1B2; dqsid=DQ",
            scnt: "scnt-token",
            serviceKey: "service-key-1",
            appleIDSessionID: "apple-session-1",
            providerID: 12345,
            teamId: "TEAM123",
            userEmail: "user@example.com",
            expiresAt: Date(timeIntervalSince1970: 1_900_000_000)
        )
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(IrisAuthSession.self, from: data)
        #expect(decoded == session)
    }

    @Test func `iris auth session optional team metadata is omitted from JSON when nil`() throws {
        let session = IrisAuthSession(
            cookies: "myacinfo=A1B2",
            scnt: "scnt",
            serviceKey: "key",
            appleIDSessionID: "apple-session",
            providerID: nil,
            teamId: nil,
            userEmail: "user@example.com",
            expiresAt: Date(timeIntervalSince1970: 1_900_000_000)
        )
        let json = String(decoding: try JSONEncoder().encode(session), as: UTF8.self)
        #expect(!json.contains("providerID"))
        #expect(!json.contains("teamId"))
    }

    // MARK: - TwoFactorChallenge

    @Test func `two factor challenge for trusted device carries masked destination`() {
        let challenge = TwoFactorChallenge(
            method: .trustedDevice,
            maskedDestination: "Trusted devices",
            codeLength: 6
        )
        #expect(challenge.method == .trustedDevice)
        #expect(challenge.maskedDestination == "Trusted devices")
        #expect(challenge.codeLength == 6)
    }

    @Test func `two factor challenge for phone carries masked phone number`() {
        let challenge = TwoFactorChallenge(
            method: .phone,
            maskedDestination: "(•••) •••-1234",
            codeLength: 6
        )
        #expect(challenge.method == .phone)
        #expect(challenge.maskedDestination == "(•••) •••-1234")
    }

    // MARK: - PendingTwoFactorState

    @Test func `pending two factor state roundtrips through codable`() throws {
        let state = PendingTwoFactorState(
            credentials: IrisAuthCredentials(appleId: "user@example.com", password: "secret"),
            scnt: "scnt-token",
            serviceKey: "service-key-1",
            appleIDSessionID: "apple-session-1",
            twoFactorCookieBag: "aidsp=ABC; dssid2=DEF",
            challenge: TwoFactorChallenge(method: .trustedDevice, maskedDestination: "Trusted devices", codeLength: 6)
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PendingTwoFactorState.self, from: data)
        #expect(decoded == state)
    }

    // MARK: - IrisAuthError

    @Test func `iris auth error invalid credentials has descriptive message`() {
        let error = IrisAuthError.invalidCredentials
        #expect(error.errorDescription?.contains("Apple") == true)
    }

    @Test func `iris auth error two factor required carries pending state`() {
        let pending = PendingTwoFactorState(
            credentials: IrisAuthCredentials(appleId: "user@example.com", password: "secret"),
            scnt: "scnt", serviceKey: "key", appleIDSessionID: "session", twoFactorCookieBag: "",
            challenge: TwoFactorChallenge(method: .trustedDevice, maskedDestination: "Trusted devices", codeLength: 6)
        )
        let error = IrisAuthError.twoFactorRequired(pending)
        if case .twoFactorRequired(let state) = error {
            #expect(state.credentials.appleId == "user@example.com")
        } else {
            Issue.record("expected twoFactorRequired")
        }
    }
}
