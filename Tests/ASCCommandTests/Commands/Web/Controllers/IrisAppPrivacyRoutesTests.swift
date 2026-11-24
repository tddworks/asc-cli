import Foundation
import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import Mockable
import NIOCore
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct IrisAppPrivacyRoutesTests {
    private let unanswered = AppPrivacy(appId: "1234567890", dataCollection: .notAnswered, isPublished: false, lastPublishedAt: nil)
    private let notCollected = AppPrivacy(appId: "1234567890", dataCollection: .notCollected, isPublished: false, lastPublishedAt: nil)

    private func call(_ method: HTTPRequest.Method, _ uri: String, body: String? = nil, showing privacy: AppPrivacy) async throws -> (HTTPResponse.Status, String) {
        let cookies = MockIrisCookieProvider()
        given(cookies).resolveSession().willReturn(IrisSession(cookies: "myacinfo=a"))
        let repo = MockIrisAppPrivacyRepository()
        given(repo).fetchPrivacy(session: .any, appId: .value("1234567890")).willReturn(privacy)
        given(repo).listDataUsages(session: .any, appId: .any).willReturn([])
        given(repo).createDataUsage(session: .any, appId: .any, entry: .any).willReturn()
        given(repo).publish(session: .any, appId: .any).willReturn()
        let router = Router(context: BasicWebSocketRequestContext.self)
        IrisAppPrivacyController(cookieProvider: cookies, repo: repo).addRoutes(to: router.group("/api/v1"))
        return try await Application(router: router).test(.router) { client in
            try await client.execute(uri: uri, method: method, body: body.map { ByteBuffer(string: $0) }) {
                ($0.status, String(buffer: $0.body))
            }
        }
    }

    private func label(_ body: String) throws -> [String: Any] {
        try #require(((try JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any])?["data"] as? [[String: Any]])?.first)
    }

    @Test func `should show an app's privacy label over REST with where to declare it`() async throws {
        let (status, body) = try await call(.get, "/api/v1/iris/apps/1234567890/app-privacy", showing: unanswered)

        #expect(status == .ok)
        let row = try label(body)
        #expect(row["dataCollection"] as? String == "NOT_ANSWERED")
        #expect((row["_links"] as? [String: Any])?["declare"] as? [String: String]
            == ["href": "/api/v1/iris/apps/1234567890/app-privacy/declare", "method": "POST"])
    }

    @Test func `should declare no data collected over REST and link to publishing it`() async throws {
        let (status, body) = try await call(.post, "/api/v1/iris/apps/1234567890/app-privacy/declare",
                                            body: #"{"notCollected":true}"#, showing: notCollected)

        #expect(status == .ok)
        let row = try label(body)
        #expect(row["dataCollection"] as? String == "NOT_COLLECTED")
        #expect((row["_links"] as? [String: Any])?["publish"] as? [String: String]
            == ["href": "/api/v1/iris/apps/1234567890/app-privacy/publish", "method": "POST"])
    }

    @Test func `should refuse a declaration body that says neither`() async throws {
        let (status, body) = try await call(.post, "/api/v1/iris/apps/1234567890/app-privacy/declare", body: "{}", showing: unanswered)

        #expect(status == .badRequest)
        #expect(body.contains(#"notCollected"#))
    }

    @Test func `should refuse a data type App Privacy doesn't know as unprocessable`() async throws {
        let (status, _) = try await call(.post, "/api/v1/iris/apps/1234567890/app-privacy/declare",
                                         body: #"{"collectedData":[{"category":"EMAIL","purposes":["ANALYTICS"],"isLinkedToYou":true,"isUsedToTrackYou":false}]}"#,
                                         showing: unanswered)

        #expect(status == .unprocessableContent)
    }

    @Test func `should refuse a data type App Privacy doesn't know without reaching Apple`() async throws {
        let cookies = MockIrisCookieProvider()
        given(cookies).resolveSession().willReturn(IrisSession(cookies: "myacinfo=a"))
        let repo = MockIrisAppPrivacyRepository()
        given(repo).fetchPrivacy(session: .any, appId: .any).willReturn(unanswered)
        let router = Router(context: BasicWebSocketRequestContext.self)
        IrisAppPrivacyController(cookieProvider: cookies, repo: repo).addRoutes(to: router.group("/api/v1"))

        let status = try await Application(router: router).test(.router) { client in
            try await client.execute(uri: "/api/v1/iris/apps/1234567890/app-privacy/declare", method: .post,
                                     body: ByteBuffer(string: #"{"collectedData":[{"category":"EMAIL","purposes":["ANALYTICS"],"isLinkedToYou":true,"isUsedToTrackYou":false}]}"#)) { $0.status }
        }

        #expect(status == .unprocessableContent)
        verify(repo).fetchPrivacy(session: .any, appId: .any).called(0)
    }

    @Test func `should publish over REST`() async throws {
        let (status, body) = try await call(.post, "/api/v1/iris/apps/1234567890/app-privacy/publish", showing: notCollected)

        #expect(status == .ok)
        #expect(try label(body)["appId"] as? String == "1234567890")
    }

    @Test func `should refuse to publish a label nothing is declared on as a conflict`() async throws {
        let (status, _) = try await call(.post, "/api/v1/iris/apps/1234567890/app-privacy/publish", showing: unanswered)

        #expect(status == .conflict)
    }
}
