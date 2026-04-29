import Domain
import Foundation
import Testing
@testable import Infrastructure

private func collectBody(from request: URLRequest) -> Data? {
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

/// Private URLProtocol subclass with its own `handler` static so this suite's stubs
/// can't race with `URLProtocolStub`'s handler from `IdmsaAPIClientTests`. Sharing
/// the same static across suites caused intermittent `signin/init` parse failures
/// when the two suites ran in parallel.
final class IrisSubmissionsURLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (HTTPURLResponse, Data))?

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [IrisSubmissionsURLProtocolStub.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = IrisSubmissionsURLProtocolStub.handler else {
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
struct IrisSDKInAppPurchaseSubmissionRepositoryTests {

    @Test func `submitInAppPurchase posts JSON-API body with submitWithNextAppStoreVersion attribute`() async throws {
        let captured = CapturedBody()
        IrisSubmissionsURLProtocolStub.handler = { request in
            captured.set(collectBody(from: request))
            let body = Data(#"{"data":{"id":"sub-9","type":"inAppPurchaseSubmissions"}}"#.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        let client = IrisClient(session: IrisSubmissionsURLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseSubmissionRepository(client: client)
        _ = try await repo.submitInAppPurchase(
            session: IrisSession(cookies: "myacinfo=ABC"),
            iapId: "iap-7",
            submitWithNextAppStoreVersion: true
        )

        let json = try JSONSerialization.jsonObject(with: captured.value!) as? [String: Any]
        let data = try #require(json?["data"] as? [String: Any])
        #expect(data["type"] as? String == "inAppPurchaseSubmissions")
        let attrs = try #require(data["attributes"] as? [String: Any])
        #expect(attrs["submitWithNextAppStoreVersion"] as? Bool == true)
        let rels = try #require(data["relationships"] as? [String: Any])
        let iap = try #require(rels["inAppPurchaseV2"] as? [String: Any])
        let iapData = try #require(iap["data"] as? [String: Any])
        #expect(iapData["id"] as? String == "iap-7")
        #expect(iapData["type"] as? String == "inAppPurchases")
    }

    @Test func `submitInAppPurchase returns submission with iapId injected from request`() async throws {
        IrisSubmissionsURLProtocolStub.handler = { request in
            let body = Data(#"{"data":{"id":"sub-9","type":"inAppPurchaseSubmissions"}}"#.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        let client = IrisClient(session: IrisSubmissionsURLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseSubmissionRepository(client: client)
        let submission = try await repo.submitInAppPurchase(
            session: IrisSession(cookies: "myacinfo=ABC"),
            iapId: "iap-7",
            submitWithNextAppStoreVersion: true
        )

        // Apple's response omits the parent IAP id — Infrastructure injects it from the request.
        #expect(submission.id == "sub-9")
        #expect(submission.iapId == "iap-7")
        #expect(submission.submitWithNextAppStoreVersion == true)
    }

    @Test func `submitInAppPurchase posts to iris inAppPurchaseSubmissions endpoint`() async throws {
        let capturedURL = CapturedBody()
        IrisSubmissionsURLProtocolStub.handler = { request in
            capturedURL.set(Data(request.url!.absoluteString.utf8))
            let body = Data(#"{"data":{"id":"sub-9","type":"inAppPurchaseSubmissions"}}"#.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        let client = IrisClient(session: IrisSubmissionsURLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseSubmissionRepository(client: client)
        _ = try await repo.submitInAppPurchase(
            session: IrisSession(cookies: "myacinfo=ABC"),
            iapId: "iap-7",
            submitWithNextAppStoreVersion: false
        )

        let url = String(decoding: capturedURL.value!, as: UTF8.self)
        #expect(url == "https://appstoreconnect.apple.com/iris/v1/inAppPurchaseSubmissions")
    }

    @Test func `deleteSubmission DELETEs iris inAppPurchaseSubmissions by id`() async throws {
        let capturedURL = CapturedBody()
        let capturedMethod = CapturedBody()
        IrisSubmissionsURLProtocolStub.handler = { request in
            capturedURL.set(Data(request.url!.absoluteString.utf8))
            capturedMethod.set(Data((request.httpMethod ?? "").utf8))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        let client = IrisClient(session: IrisSubmissionsURLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseSubmissionRepository(client: client)
        try await repo.deleteSubmission(
            session: IrisSession(cookies: "myacinfo=ABC"),
            submissionId: "iap-7"
        )

        let url = String(decoding: capturedURL.value!, as: UTF8.self)
        let method = String(decoding: capturedMethod.value!, as: UTF8.self)
        #expect(url == "https://appstoreconnect.apple.com/iris/v1/inAppPurchaseSubmissions/iap-7")
        #expect(method == "DELETE")
    }
}
