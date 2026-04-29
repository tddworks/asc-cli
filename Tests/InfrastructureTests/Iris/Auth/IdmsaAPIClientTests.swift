import Foundation
import Testing
@testable import Infrastructure

final class CapturedBody: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Data?
    var value: Data? { lock.lock(); defer { lock.unlock() }; return _value }
    func set(_ data: Data?) { lock.lock(); _value = data; lock.unlock() }
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
