import Domain
import Foundation
import Testing
@testable import Infrastructure

/// Private URLProtocol subclass with its own `handler` static so this suite's
/// stubs can't race with other iris suites' handlers when run in parallel
/// (same precedent as `IrisSubmissionsURLProtocolStub`).
final class IrisResolutionCenterURLProtocolStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (HTTPURLResponse, Data))?

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [IrisResolutionCenterURLProtocolStub.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = IrisResolutionCenterURLProtocolStub.handler else {
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

private let threadsJSON = Data("""
{
  "data": [
    {
      "type": "resolutionCenterThreads",
      "id": "thread-1",
      "attributes": {
        "threadType": "APP_REVIEW",
        "state": "OPEN",
        "createdDate": "2026-07-01T10:00:00Z"
      }
    }
  ]
}
""".utf8)

private let messagesJSON = Data("""
{
  "data": [
    {
      "type": "resolutionCenterMessages",
      "id": "msg-1",
      "attributes": {
        "messageBody": "<p>Guideline 2.1 - Performance</p>",
        "createdDate": "2026-07-02T09:30:00Z"
      },
      "relationships": {
        "fromActor": { "data": { "type": "actors", "id": "actor-1" } }
      }
    }
  ],
  "included": [
    {
      "type": "actors",
      "id": "actor-1",
      "attributes": { "actorType": "APPLE" }
    }
  ]
}
""".utf8)

private let rejectionsJSON = Data("""
{
  "data": [
    {
      "type": "reviewRejections",
      "id": "rej-1",
      "attributes": {
        "reasons": [
          {
            "reasonSection": "Performance",
            "reasonDescription": "App crashed on launch",
            "reasonCode": "2.1"
          }
        ]
      }
    }
  ]
}
""".utf8)

private let emptyThreadsJSON = Data(#"{"data":[]}"#.utf8)

@Suite(.serialized)
struct IrisSDKResolutionCenterRepositoryTests {

    private func makeRepo() -> IrisSDKResolutionCenterRepository {
        IrisSDKResolutionCenterRepository(
            client: IrisClient(session: IrisResolutionCenterURLProtocolStub.makeSession())
        )
    }

    @Test func `getResolution composes thread, messages, and rejections with parent submissionId injected`() async throws {
        IrisResolutionCenterURLProtocolStub.handler = { request in
            let url = request.url!.absoluteString
            let body: Data
            if url.contains("resolutionCenterMessages") {
                body = messagesJSON
            } else if url.contains("reviewRejections") {
                body = rejectionsJSON
            } else {
                body = threadsJSON
            }
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        let detail = try await makeRepo().getResolution(
            session: IrisSession(cookies: "myacinfo=ABC"),
            submissionId: "sub-42"
        )

        #expect(detail.id == "thread-1")
        #expect(detail.submissionId == "sub-42")
        #expect(detail.threadState == "OPEN")
        #expect(detail.messages.count == 1)
        #expect(detail.messages[0].id == "msg-1")
        #expect(detail.messages[0].threadId == "thread-1")
        #expect(detail.messages[0].body == "<p>Guideline 2.1 - Performance</p>")
        #expect(detail.messages[0].fromActor == "APPLE")
        #expect(detail.rejectionReasons == [
            ReviewRejectionReason(
                id: "rej-1",
                section: "Performance",
                descriptionText: "App crashed on launch",
                code: "2.1"
            ),
        ])
    }

    @Test func `getResolution requests the three iris endpoints with the documented filters`() async throws {
        let captured = CapturedURLs()
        IrisResolutionCenterURLProtocolStub.handler = { request in
            let url = request.url!.absoluteString
            captured.append(url)
            let body: Data
            if url.contains("resolutionCenterMessages") {
                body = messagesJSON
            } else if url.contains("reviewRejections") {
                body = rejectionsJSON
            } else {
                body = threadsJSON
            }
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, body)
        }

        _ = try await makeRepo().getResolution(
            session: IrisSession(cookies: "myacinfo=ABC"),
            submissionId: "sub-42"
        )

        let urls = captured.values
        #expect(urls.count == 3)
        #expect(urls[0].contains("resolutionCenterThreads"))
        #expect(urls[0].contains("sub-42"))
        #expect(urls[1].contains("resolutionCenterThreads/thread-1/resolutionCenterMessages"))
        #expect(urls[1].contains("fromActor"))
        #expect(urls[2].contains("reviewRejections"))
        #expect(urls[2].contains("thread-1"))
    }

    @Test func `getResolution without a thread throws a clear no-thread error`() async throws {
        IrisResolutionCenterURLProtocolStub.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, emptyThreadsJSON)
        }

        await #expect(throws: IrisResolutionCenterError.noThread(submissionId: "sub-42")) {
            _ = try await makeRepo().getResolution(
                session: IrisSession(cookies: "myacinfo=ABC"),
                submissionId: "sub-42"
            )
        }
    }
}

/// Thread-safe URL capture for handler closures.
private final class CapturedURLs: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    var values: [String] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }
    func append(_ url: String) {
        lock.lock(); defer { lock.unlock() }
        storage.append(url)
    }
}
