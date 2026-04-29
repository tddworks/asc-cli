import Foundation
import Testing
@testable import Infrastructure

/// Private URLProtocol subclass — see `IrisSDKInAppPurchaseSubmissionRepositoryTests`
/// for the rationale (avoids racing the shared `URLProtocolStub.handler` static used
/// by `IdmsaAPIClientTests` when suites run in parallel).
final class OlympusURLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (HTTPURLResponse, Data))?

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [OlympusURLProtocolStub.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = OlympusURLProtocolStub.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Suite(.serialized)
struct OlympusClientTests {

    @Test func `fetchSession parses providerID, teamId, and emailAddress`() async throws {
        OlympusURLProtocolStub.handler = { _ in
            let body = Data(#"""
            {
              "user": { "emailAddress": "alice@example.com", "fullName": "Alice" },
              "provider": { "providerId": 12345, "publicProviderId": "T-ABC" }
            }
            """#.utf8)
            return (
                HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                body
            )
        }
        let client = OlympusClient(session: OlympusURLProtocolStub.makeSession())
        let session = try await client.fetchSession(cookies: "myacinfo=1")
        #expect(session.userEmail == "alice@example.com")
        #expect(session.providerID == 12345)
        #expect(session.teamId == "T-ABC")
    }

    @Test func `fetchSession sends Cookie header verbatim`() async throws {
        let captured = CapturedCookies()
        OlympusURLProtocolStub.handler = { request in
            captured.set(request.value(forHTTPHeaderField: "Cookie"))
            let body = Data(#"{"user":{"emailAddress":"x@y.com"},"provider":{}}"#.utf8)
            return (
                HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                body
            )
        }
        let client = OlympusClient(session: OlympusURLProtocolStub.makeSession())
        _ = try await client.fetchSession(cookies: "myacinfo=ABCD; itctx=EFGH")
        #expect(captured.value == "myacinfo=ABCD; itctx=EFGH")
    }

    @Test func `fetchSession falls back to fullName when emailAddress is absent`() async throws {
        OlympusURLProtocolStub.handler = { _ in
            let body = Data(#"{"user":{"fullName":"Just Alice"},"provider":{}}"#.utf8)
            return (
                HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                body
            )
        }
        let client = OlympusClient(session: OlympusURLProtocolStub.makeSession())
        let session = try await client.fetchSession(cookies: "x=1")
        #expect(session.userEmail == "Just Alice")
    }

    @Test func `fetchSession throws httpFailure on non-2xx status`() async throws {
        OlympusURLProtocolStub.handler = { _ in
            (
                HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 401, httpVersion: nil, headerFields: nil)!,
                Data()
            )
        }
        let client = OlympusClient(session: OlympusURLProtocolStub.makeSession())
        await #expect(throws: OlympusClient.OlympusError.self) {
            _ = try await client.fetchSession(cookies: "x=1")
        }
    }

    @Test func `fetchSession throws malformedResponse when JSON is not a dictionary`() async throws {
        OlympusURLProtocolStub.handler = { _ in
            // Valid JSON, wrong shape — JSONSerialization succeeds, the dict cast fails,
            // and OlympusClient surfaces malformedResponse rather than the raw NSError.
            (
                HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Data("[]".utf8)
            )
        }
        let client = OlympusClient(session: OlympusURLProtocolStub.makeSession())
        await #expect(throws: OlympusClient.OlympusError.self) {
            _ = try await client.fetchSession(cookies: "x=1")
        }
    }
}

private final class CapturedCookies: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String?
    var value: String? { lock.lock(); defer { lock.unlock() }; return _value }
    func set(_ s: String?) { lock.lock(); _value = s; lock.unlock() }
}
