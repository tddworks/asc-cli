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

@Suite(.serialized)
struct IrisSDKInAppPurchaseSubmissionRepositoryTests {

    @Test func `submitInAppPurchase posts JSON-API body with submitWithNextAppStoreVersion attribute`() async throws {
        let captured = CapturedBody()
        URLProtocolStub.handler = { request in
            captured.set(collectBody(from: request))
            let body = Data(#"{"data":{"id":"sub-9","type":"inAppPurchaseSubmissions"}}"#.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        let client = IrisClient(session: URLProtocolStub.makeSession())
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
        URLProtocolStub.handler = { request in
            let body = Data(#"{"data":{"id":"sub-9","type":"inAppPurchaseSubmissions"}}"#.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        let client = IrisClient(session: URLProtocolStub.makeSession())
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
        URLProtocolStub.handler = { request in
            capturedURL.set(Data(request.url!.absoluteString.utf8))
            let body = Data(#"{"data":{"id":"sub-9","type":"inAppPurchaseSubmissions"}}"#.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        let client = IrisClient(session: URLProtocolStub.makeSession())
        let repo = IrisSDKInAppPurchaseSubmissionRepository(client: client)
        _ = try await repo.submitInAppPurchase(
            session: IrisSession(cookies: "myacinfo=ABC"),
            iapId: "iap-7",
            submitWithNextAppStoreVersion: false
        )

        let url = String(decoding: capturedURL.value!, as: UTF8.self)
        #expect(url == "https://appstoreconnect.apple.com/iris/v1/inAppPurchaseSubmissions")
    }
}
