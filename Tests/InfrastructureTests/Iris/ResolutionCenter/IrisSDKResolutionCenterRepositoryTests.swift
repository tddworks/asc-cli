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
        "fromActor": { "data": { "type": "actors", "id": "actor-1" } },
        "resolutionCenterMessageAttachments": {
          "data": [ { "type": "resolutionCenterMessageAttachments", "id": "att-1" } ]
        }
      }
    }
  ],
  "included": [
    {
      "type": "actors",
      "id": "actor-1",
      "attributes": { "actorType": "APPLE" }
    },
    {
      "type": "resolutionCenterMessageAttachments",
      "id": "att-1",
      "attributes": {
        "fileName": "crash-screenshot.png",
        "fileSize": 2048,
        "downloadUrl": "https://iosapps-ssl.itunes.apple.com/att-1.png"
      }
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
        // The thread lookup always goes first; the messages and rejections
        // calls run concurrently, so their order is nondeterministic.
        #expect(urls[0].contains("resolutionCenterThreads"))
        #expect(urls[0].contains("sub-42"))
        let messagesURL = try #require(urls.first {
            $0.contains("resolutionCenterThreads/thread-1/resolutionCenterMessages")
        })
        #expect(messagesURL.contains("fromActor"))
        #expect(messagesURL.contains("resolutionCenterMessageAttachments"))
        let rejectionsURL = try #require(urls.first { $0.contains("reviewRejections") })
        #expect(rejectionsURL.contains("thread-1"))
    }

    @Test func `getResolution maps included attachments with parent messageId`() async throws {
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

        #expect(detail.attachments == [
            ResolutionCenterAttachment(
                id: "att-1",
                messageId: "msg-1",
                fileName: "crash-screenshot.png",
                fileSize: 2048,
                downloadUrl: "https://iosapps-ssl.itunes.apple.com/att-1.png"
            ),
        ])
    }

    @Test func `downloadAttachment fetches bytes from an allowed https url`() async throws {
        IrisResolutionCenterURLProtocolStub.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, Data("PNGBYTES".utf8))
        }

        let data = try await makeRepo().downloadAttachment(
            session: IrisSession(cookies: "myacinfo=ABC"),
            url: "https://iosapps-ssl.itunes.apple.com/att-1.png"
        )
        #expect(data == Data("PNGBYTES".utf8))
    }

    @Test func `downloadAttachment refuses urls outside the allowed hosts`() async throws {
        IrisResolutionCenterURLProtocolStub.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, Data("SHOULD-NEVER-BE-FETCHED".utf8))
        }

        await #expect(throws: IrisResolutionCenterError.invalidAttachmentURL("https://evil.example.com/att.png")) {
            _ = try await makeRepo().downloadAttachment(
                session: IrisSession(cookies: "myacinfo=ABC"),
                url: "https://evil.example.com/att.png"
            )
        }
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
