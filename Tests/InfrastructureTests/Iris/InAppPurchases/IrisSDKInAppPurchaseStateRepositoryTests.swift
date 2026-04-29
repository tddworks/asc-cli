import Domain
import Foundation
import Testing
@testable import Infrastructure

/// Private URLProtocol subclass — see `IrisSDKInAppPurchaseSubmissionRepositoryTests`
/// for why we don't share `URLProtocolStub` between iris suites.
final class IrisStateURLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (HTTPURLResponse, Data))?

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [IrisStateURLProtocolStub.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = IrisStateURLProtocolStub.handler else {
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

private final class CapturedURL: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: URL?
    var value: URL? { lock.lock(); defer { lock.unlock() }; return _value }
    func set(_ u: URL?) { lock.lock(); _value = u; lock.unlock() }
}

@Suite(.serialized)
struct IrisSDKInAppPurchaseStateRepositoryTests {

    @Test func `fetchSubmitFlags returns map of iapId to submitWithNextAppStoreVersion`() async throws {
        IrisStateURLProtocolStub.handler = { _ in
            let body = Data(#"""
            {
              "data": [
                {
                  "type": "inAppPurchases",
                  "id": "iap-1",
                  "attributes": {
                    "submitWithNextAppStoreVersion": true
                  }
                },
                {
                  "type": "inAppPurchases",
                  "id": "iap-2",
                  "attributes": {
                    "submitWithNextAppStoreVersion": false
                  }
                }
              ]
            }
            """#.utf8)
            return (
                HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                body
            )
        }

        let client = IrisClient(session: IrisStateURLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseStateRepository(client: client)
        let flags = try await repo.fetchSubmitFlags(
            session: IrisSession(cookies: "myacinfo=A"),
            appId: "app-7"
        )

        #expect(flags["iap-1"] == true)
        #expect(flags["iap-2"] == false)
    }

    @Test func `fetchSubmitFlags hits the iris IAP listing endpoint with expected fields and state filter`() async throws {
        let captured = CapturedURL()
        IrisStateURLProtocolStub.handler = { request in
            captured.set(request.url)
            let body = Data(#"{"data":[]}"#.utf8)
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                body
            )
        }

        let client = IrisClient(session: IrisStateURLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseStateRepository(client: client)
        _ = try await repo.fetchSubmitFlags(
            session: IrisSession(cookies: "myacinfo=A"),
            appId: "app-7"
        )

        let url = try #require(captured.value)
        #expect(url.absoluteString.contains("/iris/v1/apps/app-7/inAppPurchasesV2"))
        let query = url.query ?? ""
        // Only fetches the field we actually need — minimizes payload.
        #expect(query.contains("submitWithNextAppStoreVersion"))
        // Filter narrows to actionable IAPs (queueing only matters in this state).
        #expect(query.contains("READY_TO_SUBMIT"))
    }

    @Test func `fetchSubmitFlags treats missing attribute as false`() async throws {
        IrisStateURLProtocolStub.handler = { _ in
            let body = Data(#"""
            { "data": [ { "type": "inAppPurchases", "id": "iap-3", "attributes": {} } ] }
            """#.utf8)
            return (
                HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                body
            )
        }

        let client = IrisClient(session: IrisStateURLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseStateRepository(client: client)
        let flags = try await repo.fetchSubmitFlags(
            session: IrisSession(cookies: "myacinfo=A"),
            appId: "app-7"
        )
        #expect(flags["iap-3"] == false)
    }
}
