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
        /// Apple bundles the hashcash challenge in the `signin/init` response headers
        /// (`X-Apple-HC-Challenge` + `X-Apple-HC-Bits`). The challenge is bound to the
        /// same session as the `scnt` / `appleIDSessionID` returned here — using a
        /// challenge from any *other* request will fail `signin/complete` with 401.
        public let hashcashChallenge: String?
        public let hashcashBits: Int?
        /// Accumulated `name=value; name=value` cookie bag from `Set-Cookie`. Must be
        /// echoed on every subsequent idmsa call in this login flow — including 2FA
        /// verification and trust — or Apple sees the calls as out-of-session and
        /// rejects them. Crucial for surviving across CLI process boundaries (between
        /// `asc iris auth login` and `asc iris auth verify-code`).
        public let cookies: String
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
        let hashcashChallenge = response.value(forHTTPHeaderField: "X-Apple-HC-Challenge")
        let hashcashBits = response.value(forHTTPHeaderField: "X-Apple-HC-Bits").flatMap(Int.init)
        let cookies = Self.accumulateCookies(from: response, into: "")
        return SigninInitResponse(
            iteration: iteration, salt: salt, b: b, c: c,
            protocolType: proto, scnt: scnt, appleIDSessionID: sessionID,
            hashcashChallenge: hashcashChallenge, hashcashBits: hashcashBits,
            cookies: cookies
        )
    }

    // MARK: - signin/complete

    public enum SigninCompleteResult: Sendable, Equatable {
        /// 200 OK — login succeeded without 2FA. `cookies` is the accumulated bag.
        case success(scnt: String, cookies: String)
        /// 409 Conflict — 2FA gate. Caller must run the 2FA flow with the new scnt + sessionID
        /// and the accumulated cookie bag (which will include `aasp` from init plus anything
        /// the complete-409 response adds).
        case twoFactorRequired(scnt: String, appleIDSessionID: String, cookies: String)
    }

    public func signinComplete(
        accountName: String, c: String, m1: Data, m2: Data,
        scnt: String, appleIDSessionID: String,
        hashcashChallenge: String?, hashcashBits: Int?,
        cookies incomingCookies: String
    ) async throws -> SigninCompleteResult {
        let body: [String: Any] = [
            "accountName": accountName,
            "c": c,
            "m1": m1.base64EncodedString(),
            "m2": m2.base64EncodedString(),
            "rememberMe": true,
        ]
        let url = URL(string: "\(Self.baseURL)/signin/complete?isRememberMeEnabled=true")!

        // The hashcash challenge MUST come from the same `signin/init` response that
        // produced our `scnt` and `appleIDSessionID`. Computing one from any other
        // request opens a different Apple session, and `signin/complete` will return
        // 401 with code -20101 ("Incorrect Apple Account email or password").
        let hashcash: String?
        if let challenge = hashcashChallenge, let bits = hashcashBits {
            hashcash = AppleHashcash.compute(challenge: challenge, bits: bits)
        } else {
            hashcash = nil
        }

        var extraHeaders: [String: String] = [:]
        if let hashcash { extraHeaders["X-Apple-HC"] = hashcash }
        if !incomingCookies.isEmpty { extraHeaders["Cookie"] = incomingCookies }

        let (_, response) = try await postJSON(
            url: url, body: body, scnt: scnt, sessionID: appleIDSessionID,
            extraHeaders: extraHeaders
        )

        let respScnt = response.value(forHTTPHeaderField: "scnt") ?? scnt
        let respSession = response.value(forHTTPHeaderField: "X-Apple-ID-Session-Id") ?? appleIDSessionID
        let updatedCookies = Self.accumulateCookies(from: response, into: incomingCookies)

        switch response.statusCode {
        case 200:
            return .success(scnt: respScnt, cookies: updatedCookies)
        case 409:
            return .twoFactorRequired(scnt: respScnt, appleIDSessionID: respSession, cookies: updatedCookies)
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
    /// Submits the 6-digit code and returns the updated cookie bag (Apple may set
    /// extra cookies on success). Cookies must be echoed on the subsequent `trust` call.
    public func submitTwoFactorCode(
        _ code: String,
        method: TwoFactorMethod,
        scnt: String,
        appleIDSessionID: String,
        cookies incomingCookies: String
    ) async throws -> String {
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

        var extraHeaders: [String: String] = [:]
        if !incomingCookies.isEmpty { extraHeaders["Cookie"] = incomingCookies }

        let (data, response) = try await postJSON(
            url: url, body: body, scnt: scnt, sessionID: appleIDSessionID,
            extraHeaders: extraHeaders
        )
        switch response.statusCode {
        case 200, 204:
            return Self.accumulateCookies(from: response, into: incomingCookies)
        case 400, 401, 403:
            // Apple's response body carries a specific code in `serviceErrors[].code`:
            // -21669 = code expired / out of attempts
            // -22421 = wrong code typed
            // anything else = session-state mismatch or protocol regression
            // Surfacing the code in the error message turns "code rejected" into
            // actionable signal for the user.
            let serviceError = Self.extractServiceError(from: data)
            throw IrisAuthError.networkFailure(
                message: "verify/securitycode HTTP \(response.statusCode)\(serviceError)"
            )
        default:
            throw IrisAuthError.networkFailure(message: "verify/securitycode HTTP \(response.statusCode)")
        }
    }

    private static func extractServiceError(from data: Data) -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let errors = json["serviceErrors"] as? [[String: Any]],
            let first = errors.first
        else { return "" }
        let code = (first["code"] as? String) ?? ""
        let message = (first["message"] as? String) ?? ""
        return " (Apple \(code): \(message))"
    }

    /// Calls `2sv/trust` to finalize `myacinfo` after a successful 2FA submission.
    /// Returns the merged cookie bag including the trust-set cookies.
    public func trust(
        scnt: String,
        appleIDSessionID: String,
        cookies incomingCookies: String
    ) async throws -> String {
        let url = URL(string: "\(Self.baseURL)/2sv/trust")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // trust endpoint is a GET in observed flows
        applyHeaders(to: &request, scnt: scnt, sessionID: appleIDSessionID)
        if !incomingCookies.isEmpty {
            request.setValue(incomingCookies, forHTTPHeaderField: "Cookie")
        }
        if Self.debugEnabled { dumpRequest(request, body: nil) }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw IrisAuthError.networkFailure(message: "non-HTTP response")
        }
        if Self.debugEnabled { dumpResponse(http, data: data) }
        guard (200..<300).contains(http.statusCode) else {
            throw IrisAuthError.networkFailure(message: "2sv/trust HTTP \(http.statusCode)")
        }
        return Self.accumulateCookies(from: http, into: incomingCookies)
    }

    /// Parses `Set-Cookie` headers from `response`, merges them into the existing cookie
    /// bag (newer values overwrite older), and returns a `name=value; name=value` string
    /// suitable for the `Cookie` request header.
    private static func accumulateCookies(from response: HTTPURLResponse, into existing: String) -> String {
        var jar: [String: String] = [:]
        // Parse existing first.
        for pair in existing.split(separator: ";") {
            let kv = pair.trimmingCharacters(in: .whitespaces).split(separator: "=", maxSplits: 1)
            if kv.count == 2 { jar[String(kv[0])] = String(kv[1]) }
        }
        // Layer Set-Cookie on top — newest wins.
        if let url = response.url {
            let cookies = HTTPCookie.cookies(
                withResponseHeaderFields: response.allHeaderFields as? [String: String] ?? [:],
                for: url
            )
            for cookie in cookies { jar[cookie.name] = cookie.value }
        }
        return jar.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    }

    // MARK: - Helpers

    private func postJSON(
        url: URL,
        body: [String: Any],
        scnt: String?,
        sessionID: String?,
        extraHeaders: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        applyHeaders(to: &request, scnt: scnt, sessionID: sessionID)
        for (name, value) in extraHeaders { request.setValue(value, forHTTPHeaderField: name) }

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
        // `XMLHttpRequest` is the Origin signal Apple's idmsa expects for web flows;
        // missing this header has been observed to flip 200 → 401 on edge cases.
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
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
        // Print the headers we actually thread through the SRP+2FA flow so the dump
        // is self-sufficient for debugging session-mismatch issues.
        let interestingHeaders = ["Cookie", "scnt", "X-Apple-ID-Session-Id", "X-Apple-HC", "X-Apple-Widget-Key"]
        for name in interestingHeaders {
            if let value = request.value(forHTTPHeaderField: name) {
                let display = name == "X-Apple-Widget-Key" || name == "Cookie" || name == "X-Apple-HC"
                    ? value.prefix(40) + (value.count > 40 ? "…" : "") : Substring(value)
                dump += "  \(name): \(display)\n"
            }
        }
        if let body, var json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
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
        // Print the headers we actually care about for the SRP+hashcash flow so the
        // dump is self-sufficient when sharing for debugging.
        let interestingHeaders = [
            "X-Apple-HC-Challenge", "X-Apple-HC-Bits", "scnt", "X-Apple-ID-Session-Id",
            "Set-Cookie", "Content-Type",
        ]
        for name in interestingHeaders {
            if let value = response.value(forHTTPHeaderField: name) {
                dump += "  \(name): \(value)\n"
            }
        }
        if let pretty = try? JSONSerialization.jsonObject(with: data),
           let formatted = try? JSONSerialization.data(withJSONObject: pretty, options: [.prettyPrinted]) {
            dump += String(decoding: formatted, as: UTF8.self) + "\n"
        } else if !data.isEmpty, data.count < 4096 {
            // Avoid dumping multi-KB HTML pages; clip if needed.
            dump += String(decoding: data, as: UTF8.self) + "\n"
        } else if !data.isEmpty {
            dump += "<\(data.count)-byte body, suppressed>\n"
        }
        FileHandle.standardError.write(Data(dump.utf8))
    }
}
