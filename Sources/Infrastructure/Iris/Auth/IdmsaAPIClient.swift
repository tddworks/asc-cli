import Domain
import Foundation

/// HTTP client for `https://idmsa.apple.com/appleauth/auth/...`. Knows nothing about
/// SRP — it carries bytes, threads headers, and parses Apple's JSON shapes.
///
/// Injectable `URLSession` so tests can swap in `URLProtocolStub`. `ASC_IRIS_DEBUG=1`
/// dumps every request and response body to stderr (with `m1`/`a` redacted) so the
/// first failed real-world login self-captures the test data we need.
public struct IdmsaAPIClient: Sendable {
    private let session: URLSession
    private let serviceKey: String
    private static let baseURL = "https://idmsa.apple.com/appleauth/auth"
    private static let debugEnabled = ProcessInfo.processInfo.environment["ASC_IRIS_DEBUG"] == "1"

    public init(session: URLSession = .shared, serviceKey: String) {
        self.session = session
        self.serviceKey = serviceKey
    }

    // MARK: - signin/init

    public struct SigninInitResponse: Sendable, Equatable {
        public let iteration: Int
        public let salt: Data
        public let b: Data
        public let c: String
        public let protocolType: AppleSRPClient.AppleProtocol
        public let scnt: String
        public let appleIDSessionID: String
    }

    public func signinInit(accountName: String, A: Data) async throws -> SigninInitResponse {
        let body: [String: Any] = [
            "a": A.base64EncodedString(),
            "accountName": accountName,
            "protocols": ["s2k", "s2k_fo"],
        ]
        let url = URL(string: "\(Self.baseURL)/signin/init")!
        let (data, response) = try await postJSON(url: url, body: body, scnt: nil, sessionID: nil)
        guard response.statusCode == 200 else {
            throw IrisAuthError.networkFailure(message: "signin/init HTTP \(response.statusCode)")
        }
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let iteration = json["iteration"] as? Int,
            let saltB64 = json["salt"] as? String, let salt = Data(base64Encoded: saltB64),
            let bB64 = json["b"] as? String, let b = Data(base64Encoded: bB64),
            let c = json["c"] as? String,
            let protoRaw = json["protocol"] as? String,
            let proto = AppleSRPClient.AppleProtocol(rawValue: protoRaw)
        else {
            throw IrisAuthError.networkFailure(message: "signin/init response missing required fields")
        }
        let scnt = response.value(forHTTPHeaderField: "scnt") ?? ""
        let sessionID = response.value(forHTTPHeaderField: "X-Apple-ID-Session-Id") ?? ""
        return SigninInitResponse(
            iteration: iteration, salt: salt, b: b, c: c,
            protocolType: proto, scnt: scnt, appleIDSessionID: sessionID
        )
    }

    // MARK: - signin/complete

    public enum SigninCompleteResult: Sendable, Equatable {
        /// 200 OK — login succeeded without 2FA. `cookies` is the Set-Cookie payload.
        case success(scnt: String, cookies: String)
        /// 409 Conflict — 2FA gate. Caller must run the 2FA flow with the new scnt + sessionID.
        case twoFactorRequired(scnt: String, appleIDSessionID: String)
    }

    public func signinComplete(
        accountName: String, c: String, m1: Data, m2: Data,
        scnt: String, appleIDSessionID: String
    ) async throws -> SigninCompleteResult {
        let body: [String: Any] = [
            "accountName": accountName,
            "c": c,
            "m1": m1.base64EncodedString(),
            "m2": m2.base64EncodedString(),
            "rememberMe": true,
        ]
        let url = URL(string: "\(Self.baseURL)/signin/complete?isRememberMeEnabled=true")!
        let (_, response) = try await postJSON(url: url, body: body, scnt: scnt, sessionID: appleIDSessionID)

        let respScnt = response.value(forHTTPHeaderField: "scnt") ?? scnt
        let respSession = response.value(forHTTPHeaderField: "X-Apple-ID-Session-Id") ?? appleIDSessionID

        switch response.statusCode {
        case 200:
            let cookies = (response.allHeaderFields["Set-Cookie"] as? String) ?? ""
            return .success(scnt: respScnt, cookies: cookies)
        case 409:
            return .twoFactorRequired(scnt: respScnt, appleIDSessionID: respSession)
        case 401, 403:
            throw IrisAuthError.invalidCredentials
        default:
            throw IrisAuthError.networkFailure(message: "signin/complete HTTP \(response.statusCode)")
        }
    }

    // MARK: - 2FA

    public enum TwoFactorMethod: String, Sendable {
        case trustedDevice
        case phone
    }

    /// Submits a 6-digit 2FA code. 200 = accepted; non-2xx surfaces as `twoFactorCodeRejected`
    /// or `networkFailure` depending on Apple's status.
    public func submitTwoFactorCode(
        _ code: String,
        method: TwoFactorMethod,
        scnt: String,
        appleIDSessionID: String
    ) async throws {
        let url: URL
        let body: [String: Any]
        switch method {
        case .trustedDevice:
            url = URL(string: "\(Self.baseURL)/verify/trusteddevice/securitycode")!
            body = ["securityCode": ["code": code]]
        case .phone:
            url = URL(string: "\(Self.baseURL)/verify/phone/securitycode")!
            // phoneNumber.id is selected during 2FA challenge negotiation; default 1 works for
            // most accounts that have a single phone number. We surface this as a known caveat
            // and let real-world testing iterate on it.
            body = ["securityCode": ["code": code], "phoneNumber": ["id": 1], "mode": "sms"]
        }
        let (_, response) = try await postJSON(url: url, body: body, scnt: scnt, sessionID: appleIDSessionID)
        switch response.statusCode {
        case 200, 204: return
        case 400, 401, 403:
            throw IrisAuthError.twoFactorCodeRejected(remainingAttempts: nil)
        default:
            throw IrisAuthError.networkFailure(message: "verify/securitycode HTTP \(response.statusCode)")
        }
    }

    /// Calls `2sv/trust` to finalize the `myacinfo` cookie after a successful 2FA submission.
    /// Returns the cookies the trust step set.
    public func trust(scnt: String, appleIDSessionID: String) async throws -> String {
        let url = URL(string: "\(Self.baseURL)/2sv/trust")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // trust endpoint is a GET in observed flows
        applyHeaders(to: &request, scnt: scnt, sessionID: appleIDSessionID)
        if Self.debugEnabled { dumpRequest(request, body: nil) }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw IrisAuthError.networkFailure(message: "non-HTTP response")
        }
        if Self.debugEnabled { dumpResponse(http, data: data) }
        guard (200..<300).contains(http.statusCode) else {
            throw IrisAuthError.networkFailure(message: "2sv/trust HTTP \(http.statusCode)")
        }
        return (http.allHeaderFields["Set-Cookie"] as? String) ?? ""
    }

    // MARK: - Helpers

    private func postJSON(
        url: URL,
        body: [String: Any],
        scnt: String?,
        sessionID: String?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        applyHeaders(to: &request, scnt: scnt, sessionID: sessionID)

        if Self.debugEnabled { dumpRequest(request, body: request.httpBody) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw IrisAuthError.networkFailure(message: "non-HTTP response")
        }

        if Self.debugEnabled { dumpResponse(http, data: data) }
        return (data, http)
    }

    private func applyHeaders(to request: inout URLRequest, scnt: String?, sessionID: String?) {
        request.setValue("application/json, text/javascript", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(serviceKey, forHTTPHeaderField: "X-Apple-Widget-Key")
        request.setValue(serviceKey, forHTTPHeaderField: "X-Apple-OAuth-Client-Id")
        request.setValue("https://idmsa.apple.com", forHTTPHeaderField: "X-Apple-OAuth-Redirect-URI")
        request.setValue("WebKit", forHTTPHeaderField: "X-Apple-OAuth-Response-Mode")
        request.setValue("code", forHTTPHeaderField: "X-Apple-OAuth-Response-Type")
        request.setValue("https://appstoreconnect.apple.com", forHTTPHeaderField: "Origin")
        request.setValue("https://appstoreconnect.apple.com/", forHTTPHeaderField: "Referer")
        if let scnt { request.setValue(scnt, forHTTPHeaderField: "scnt") }
        if let sessionID { request.setValue(sessionID, forHTTPHeaderField: "X-Apple-ID-Session-Id") }
    }

    private func dumpRequest(_ request: URLRequest, body: Data?) {
        var dump = "[idmsa] → \(request.httpMethod ?? "?") \(request.url?.path ?? "?")\n"
        if let body, var json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            // Redact long base64 fields so dumps are safe to share.
            if json["a"] is String { json["a"] = "<redacted>" }
            if json["m1"] is String { json["m1"] = "<redacted>" }
            if json["m2"] is String { json["m2"] = "<redacted>" }
            if let redacted = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .prettyPrinted]) {
                dump += String(decoding: redacted, as: UTF8.self) + "\n"
            }
        }
        FileHandle.standardError.write(Data(dump.utf8))
    }

    private func dumpResponse(_ response: HTTPURLResponse, data: Data) {
        var dump = "[idmsa] ← \(response.statusCode) \(response.url?.path ?? "?")\n"
        if let pretty = try? JSONSerialization.jsonObject(with: data),
           let formatted = try? JSONSerialization.data(withJSONObject: pretty, options: [.prettyPrinted]) {
            dump += String(decoding: formatted, as: UTF8.self) + "\n"
        } else if !data.isEmpty {
            dump += String(decoding: data, as: UTF8.self) + "\n"
        }
        FileHandle.standardError.write(Data(dump.utf8))
    }
}
