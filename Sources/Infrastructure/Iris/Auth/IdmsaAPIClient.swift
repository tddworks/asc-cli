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

    public init(session: URLSession? = nil, serviceKey: String) {
        // Default to URLSession.shared so HTTPCookieStorage.shared automatically threads
        // cookies. Matches xcodes' working pattern. We *can't* use a private
        // HTTPCookieStorage — Foundation only exposes `HTTPCookieStorage.shared`; the
        // `HTTPCookieStorage()` constructor returns a non-functional instance that
        // silently drops Set-Cookie headers, leaving every continuation request without
        // session cookies and 401-ing on Apple's side.
        //
        // For multi-process flows (`asc iris auth login` then `verify-code` in a
        // separate process), `seedCookiesIfNeeded(_:forURL:in:)` injects persisted
        // cookies into HTTPCookieStorage.shared so the second process picks up where
        // the first left off.
        self.session = session ?? .shared
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
            "rememberMe": false,
        ]
        // Match xcodes (URL constant) and the rorkai/Go reference: `?isRememberMeEnabled=false`
        // with `rememberMe: false` body. `true` puts Apple in the "trust this browser" path,
        // which mismatches the CLI session and makes the post-409 GET /appleauth/auth 401.
        let url = URL(string: "\(Self.baseURL)/signin/complete?isRememberMeEnabled=false")!

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
        Self.seedCookiesIfNeeded(incomingCookies, forURL: url, in: session)

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
    /// Calls `GET /appleauth/auth` to prime Apple's 2FA session state. We deliberately
    /// send a MINIMAL header set here
    /// because the OAuth-* and X-Requested-With headers our other endpoints expect
    /// have been observed to flip 200 → 401 on this specific endpoint.
    public func fetchAuthOptions(
        scnt: String,
        appleIDSessionID: String,
        cookies incomingCookies: String
    ) async throws -> String {
        let url = URL(string: "\(Self.baseURL)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(serviceKey, forHTTPHeaderField: "X-Apple-Widget-Key")
        request.setValue(scnt, forHTTPHeaderField: "scnt")
        request.setValue(appleIDSessionID, forHTTPHeaderField: "X-Apple-ID-Session-Id")
        Self.seedCookiesIfNeeded(incomingCookies, forURL: url, in: session)
        if Self.debugEnabled { dumpRequest(request, body: nil) }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw IrisAuthError.networkFailure(message: "non-HTTP response")
        }
        if Self.debugEnabled { dumpResponse(http, data: data) }
        guard (200..<300).contains(http.statusCode) else {
            FileHandle.standardError.write(
                Data("[idmsa] auth options returned \(http.statusCode); proceeding to verify anyway\n".utf8)
            )
            return incomingCookies
        }
        return Self.accumulateCookies(from: http, into: incomingCookies)
    }

    /// Submits the 6-digit code and returns the updated cookie bag (Apple may set
    /// extra cookies on success). Cookies must be echoed on the subsequent `trust` call.
    ///
    /// **Header set is deliberately minimal** — matching fastlane's spaceship to the byte.
    /// Sending the OAuth-* / Origin / Referer headers our SRP endpoints use here flips
    /// 200 → 401 on Apple's verify endpoint with no useful service error in the body.
    /// The verify endpoint is part of Apple's "continuation" flow and only wants the
    /// scnt + sessionId + widget-key + cookies that bind us to the post-SRP session.
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

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        // Minimal header set — matches XcodesOrg/xcodes byte-for-byte. NO X-Requested-With
        // on verify (xcodes drops it for continuation calls — observed to flip 200 → 401
        // when included), NO OAuth-* / Origin / Referer headers. Cookies are auto-threaded
        // by URLSession's HTTPCookieStorage; the `incomingCookies` parameter is now only
        // used to seed storage when crossing process boundaries (kept for API stability).
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(serviceKey, forHTTPHeaderField: "X-Apple-Widget-Key")
        request.setValue(scnt, forHTTPHeaderField: "scnt")
        request.setValue(appleIDSessionID, forHTTPHeaderField: "X-Apple-ID-Session-Id")
        Self.seedCookiesIfNeeded(incomingCookies, forURL: url, in: session)

        if Self.debugEnabled { dumpRequest(request, body: request.httpBody) }
        let (data, urlResponse) = try await session.data(for: request)
        guard let response = urlResponse as? HTTPURLResponse else {
            throw IrisAuthError.networkFailure(message: "non-HTTP response")
        }
        if Self.debugEnabled { dumpResponse(response, data: data) }
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
        Self.seedCookiesIfNeeded(incomingCookies, forURL: url, in: session)
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

    /// Seeds the URLSession's cookie storage from a persisted `Cookie:` string. Used
    /// when crossing process boundaries — `asc iris auth verify-code` reads cookies
    /// the `login` step persisted, then injects them here so URLSession can thread
    /// them automatically on subsequent requests. Within a single process the auto-
    /// threading already covers everything; this is purely a multi-process aid.
    private static func seedCookiesIfNeeded(
        _ cookieString: String,
        forURL url: URL,
        in session: URLSession
    ) {
        guard !cookieString.isEmpty else { return }
        let storage = session.configuration.httpCookieStorage ?? HTTPCookieStorage.shared
        for pair in cookieString.split(separator: ";") {
            let kv = pair.trimmingCharacters(in: .whitespaces).split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            let name = String(kv[0])
            let value = String(kv[1])
            // Only seed if not already present — avoid clobbering fresher cookies
            // URLSession may have set on a prior in-process request.
            let existing = storage.cookies(for: url) ?? []
            if existing.contains(where: { $0.name == name }) { continue }
            // Apple sets cookies on either `apple.com` (parent) or `idmsa.apple.com`
            // (host). Without a stored Set-Cookie line we can't know — default to the
            // host so cookies match the next idmsa request.
            if let cookie = HTTPCookie(properties: [
                .name: name, .value: value, .domain: url.host ?? "idmsa.apple.com",
                .path: "/", .secure: true,
            ]) {
                storage.setCookie(cookie)
            }
        }
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
        // Header set is intentionally narrow — matches xcodes (URLRequest+Apple.swift
        // SRPInit/SRPComplete) and the rorkai/Go reference (signin.go). Adding
        // OAuth/Origin/Referer here taints the SRP session: signin/complete still works,
        // but the post-409 GET /appleauth/auth then returns 401 with a rotated scnt,
        // and the subsequent verify/securitycode call is rejected as out-of-sequence.
        request.setValue("application/json, text/javascript", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue(serviceKey, forHTTPHeaderField: "X-Apple-Widget-Key")
        if let scnt { request.setValue(scnt, forHTTPHeaderField: "scnt") }
        if let sessionID { request.setValue(sessionID, forHTTPHeaderField: "X-Apple-ID-Session-Id") }
    }

    private func dumpRequest(_ request: URLRequest, body: Data?) {
        var dump = "[idmsa] → \(request.httpMethod ?? "?") \(request.url?.path ?? "?")\n"
        // Print headers we actually thread through the SRP+2FA flow so the dump
        // is self-sufficient. Cookie is shown in full because seeing which cookies
        // are present (aasp, acn01, dslang, site, …) is critical for debugging.
        let interestingHeaders = ["Accept", "Cookie", "scnt", "X-Apple-ID-Session-Id", "X-Apple-HC", "X-Apple-Widget-Key", "X-Requested-With"]
        for name in interestingHeaders {
            if let value = request.value(forHTTPHeaderField: name) {
                let display: Substring
                if name == "X-Apple-Widget-Key" || name == "X-Apple-HC" {
                    display = Substring(value.prefix(40) + (value.count > 40 ? "…" : ""))
                } else {
                    display = Substring(value)
                }
                dump += "  \(name): \(display)\n"
            }
        }
        // URLSession adds Cookie header AT SEND TIME from its storage — these don't
        // appear via `request.value(forHTTPHeaderField:)` above. Query the cookie
        // storage directly so the dump reflects what Apple actually sees.
        if let url = request.url,
           let storage = self.session.configuration.httpCookieStorage ?? HTTPCookieStorage.shared as HTTPCookieStorage?,
           let stored = storage.cookies(for: url), !stored.isEmpty {
            let cookieHeader = stored.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            dump += "  (URLSession will add) Cookie: \(cookieHeader)\n"
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
