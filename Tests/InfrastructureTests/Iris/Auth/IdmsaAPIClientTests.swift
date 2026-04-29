import Foundation
import Testing
@testable import Infrastructure

final class CapturedBody: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Data?
    var value: Data? { lock.lock(); defer { lock.unlock() }; return _value }
    func set(_ data: Data?) { lock.lock(); _value = data; lock.unlock() }
}

final class CapturedRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var _request: URLRequest?
    private var _body: Data?
    var request: URLRequest? { lock.lock(); defer { lock.unlock() }; return _request }
    var body: Data? { lock.lock(); defer { lock.unlock() }; return _body }
    func set(_ request: URLRequest, body: Data?) {
        lock.lock(); _request = request; _body = body; lock.unlock()
    }
}

private func extractBody(from request: URLRequest) -> Data? {
    if let body = request.httpBody { return body }
    guard let stream = request.httpBodyStream else { return nil }
    stream.open()
    defer { stream.close() }
    var collected = Data()
    let bufferSize = 4096
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }
    while stream.hasBytesAvailable {
        let read = stream.read(buffer, maxLength: bufferSize)
        if read > 0 { collected.append(buffer, count: read) } else { break }
    }
    return collected
}

@Suite(.serialized)
struct IdmsaAPIClientTests {

    @Test func `signinInit POSTs body with a accountName and protocols`() async throws {
        let capture = CapturedBody()
        URLProtocolStub.handler = { request in
            capture.set(extractBody(from: request))
            let body = Data("""
            {"iteration":20000,"salt":"YWJjZA==","b":"QQ==","c":"some-cookie","protocol":"s2k"}
            """.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil,
                headerFields: ["scnt": "scnt-token", "X-Apple-ID-Session-Id": "apple-session-id"]
            )!
            return (response, body)
        }

        let client = IdmsaAPIClient(session: URLProtocolStub.makeSession(), serviceKey: "key-1")
        _ = try await client.signinInit(accountName: "user@example.com", A: Data(repeating: 0xAA, count: 256))

        let json = try JSONSerialization.jsonObject(with: capture.value!) as? [String: Any]
        #expect(json?["accountName"] as? String == "user@example.com")
        let protocols = json?["protocols"] as? [String]
        #expect(protocols == ["s2k", "s2k_fo"])
        #expect(json?["a"] is String)  // base64-encoded A
    }

    @Test func `signinInit returns parsed response with salt and B`() async throws {
        URLProtocolStub.handler = { request in
            let body = Data("""
            {"iteration":20000,"salt":"YWJjZA==","b":"QkJCQg==","c":"cookie-1","protocol":"s2k"}
            """.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["scnt": "scnt-1", "X-Apple-ID-Session-Id": "session-1"]
            )!
            return (response, body)
        }

        let client = IdmsaAPIClient(session: URLProtocolStub.makeSession(), serviceKey: "key-1")
        let result = try await client.signinInit(accountName: "u@x.com", A: Data(count: 256))

        #expect(result.iteration == 20000)
        #expect(result.salt == Data([0x61, 0x62, 0x63, 0x64]))  // "abcd" base64-decoded
        #expect(result.b == Data([0x42, 0x42, 0x42, 0x42]))    // "BBBB" base64-decoded
        #expect(result.c == "cookie-1")
        #expect(result.protocolType == .s2k)
        #expect(result.scnt == "scnt-1")
        #expect(result.appleIDSessionID == "session-1")
    }

    @Test func `signinComplete returns success when status is 200`() async throws {
        URLProtocolStub.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["scnt": "scnt-2", "Set-Cookie": "myacinfo=ABCD; Path=/; Domain=apple.com"]
            )!
            return (response, Data("{}".utf8))
        }

        let client = IdmsaAPIClient(session: URLProtocolStub.makeSession(), serviceKey: "k")
        let result = try await client.signinComplete(
            accountName: "u@x.com", c: "cookie", m1: Data(count: 32), m2: Data(count: 32),
            scnt: "prev-scnt", appleIDSessionID: "prev-session",
            hashcashChallenge: nil, hashcashBits: nil,
            cookies: ""
        )

        if case .success(let scnt, let cookies) = result {
            #expect(scnt == "scnt-2")
            #expect(cookies.contains("myacinfo=ABCD"))
        } else {
            Issue.record("expected .success, got \(result)")
        }
    }

    @Test func `signinInit omits OAuth, Origin, and Referer headers (matches xcodes and rorkai go ref)`() async throws {
        let captured = CapturedRequest()
        URLProtocolStub.handler = { request in
            captured.set(request, body: extractBody(from: request))
            let body = Data("""
            {"iteration":20000,"salt":"YWJjZA==","b":"QQ==","c":"c","protocol":"s2k"}
            """.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["scnt": "s", "X-Apple-ID-Session-Id": "id"]
            )!
            return (response, body)
        }

        let client = IdmsaAPIClient(session: URLProtocolStub.makeSession(), serviceKey: "k")
        _ = try await client.signinInit(accountName: "u@x.com", A: Data(count: 256))

        let req = try #require(captured.request)
        // Apple binds the SRP session to the headers we send. xcodes (XcodesOrg) and the
        // rorkai go reference both omit OAuth-* / Origin / Referer; sending them taints
        // the session and makes the post-409 GET /appleauth/auth return 401 — which
        // rotates scnt server-side and then fails verify/securitycode with another 401.
        #expect(req.value(forHTTPHeaderField: "X-Apple-OAuth-Client-Id") == nil)
        #expect(req.value(forHTTPHeaderField: "X-Apple-OAuth-Redirect-URI") == nil)
        #expect(req.value(forHTTPHeaderField: "X-Apple-OAuth-Response-Mode") == nil)
        #expect(req.value(forHTTPHeaderField: "X-Apple-OAuth-Response-Type") == nil)
        #expect(req.value(forHTTPHeaderField: "Origin") == nil)
        #expect(req.value(forHTTPHeaderField: "Referer") == nil)
        // Headers we still expect — preserved set matches xcodes URLRequest+Apple.swift SRPInit.
        #expect(req.value(forHTTPHeaderField: "X-Requested-With") == "XMLHttpRequest")
        #expect(req.value(forHTTPHeaderField: "X-Apple-Widget-Key") == "k")
        #expect(req.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func `signinComplete posts to isRememberMeEnabled=false with rememberMe false body`() async throws {
        let captured = CapturedRequest()
        URLProtocolStub.handler = { request in
            captured.set(request, body: extractBody(from: request))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 409, httpVersion: nil,
                headerFields: ["scnt": "s", "X-Apple-ID-Session-Id": "id"]
            )!
            return (response, Data("{}".utf8))
        }

        let client = IdmsaAPIClient(session: URLProtocolStub.makeSession(), serviceKey: "k")
        _ = try await client.signinComplete(
            accountName: "u@x.com", c: "c", m1: Data(count: 32), m2: Data(count: 32),
            scnt: "s0", appleIDSessionID: "id0",
            hashcashChallenge: nil, hashcashBits: nil, cookies: ""
        )

        let req = try #require(captured.request)
        let bodyJSON = try JSONSerialization.jsonObject(with: try #require(captured.body)) as? [String: Any]
        // Both xcodes (URL constant) and rorkai go (request URL) use isRememberMeEnabled=false.
        #expect(req.url?.query == "isRememberMeEnabled=false")
        // Body matches: rememberMe=false bypasses Apple's "trust this browser" path, which
        // is the wrong path for a CLI session.
        #expect(bodyJSON?["rememberMe"] as? Bool == false)
        // OAuth/Origin/Referer must not be sent (same reason as signin/init).
        #expect(req.value(forHTTPHeaderField: "X-Apple-OAuth-Client-Id") == nil)
        #expect(req.value(forHTTPHeaderField: "Origin") == nil)
        #expect(req.value(forHTTPHeaderField: "Referer") == nil)
    }

    @Test func `signinComplete returns twoFactorRequired when status is 409`() async throws {
        URLProtocolStub.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 409, httpVersion: nil,
                headerFields: ["scnt": "scnt-3", "X-Apple-ID-Session-Id": "session-3"]
            )!
            return (response, Data("{}".utf8))
        }

        let client = IdmsaAPIClient(session: URLProtocolStub.makeSession(), serviceKey: "k")
        let result = try await client.signinComplete(
            accountName: "u@x.com", c: "cookie", m1: Data(count: 32), m2: Data(count: 32),
            scnt: "prev-scnt", appleIDSessionID: "prev-session",
            hashcashChallenge: nil, hashcashBits: nil,
            cookies: "aasp=existing"
        )

        if case .twoFactorRequired(let scnt, let sessionId, let cookies) = result {
            #expect(scnt == "scnt-3")
            #expect(sessionId == "session-3")
            #expect(cookies.contains("aasp=existing"))
        } else {
            Issue.record("expected .twoFactorRequired, got \(result)")
        }
    }
}
