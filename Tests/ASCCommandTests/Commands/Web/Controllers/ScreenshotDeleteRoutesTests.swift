import Hummingbird
import HummingbirdTesting
import HummingbirdWebSocket
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain
@testable import Infrastructure

@Suite
struct ScreenshotDeleteRoutesTests {

    @Test func `should confirm the screenshot was deleted over REST`() async throws {
        let repo = MockScreenshotRepository()
        given(repo).deleteScreenshot(screenshotId: .value("shot-1")).willReturn()

        let (status, body) = try await Self.delete("/api/v1/screenshots/shot-1") {
            ScreenshotsController(repo: repo).addRoutes(to: $0)
        }

        #expect(status == .ok)
        #expect(body == #"{"deleted":true}"#)
    }

    @Test func `should confirm the screenshot set was deleted over REST`() async throws {
        let repo = MockScreenshotRepository()
        given(repo).deleteScreenshotSet(setId: .value("set-1")).willReturn()

        let (status, body) = try await Self.delete("/api/v1/screenshot-sets/set-1") {
            ScreenshotSetsController(repo: repo).addRoutes(to: $0)
        }

        #expect(status == .ok)
        #expect(body == #"{"deleted":true}"#)
    }

    // MARK: - Helpers

    static func delete(
        _ uri: String,
        routes: (RouterGroup<BasicWebSocketRequestContext>) -> Void
    ) async throws -> (HTTPResponse.Status, String) {
        let router = Router(context: BasicWebSocketRequestContext.self)
        routes(router.group("/api/v1"))
        return try await Application(router: router).test(.router) { client in
            try await client.execute(uri: uri, method: .delete) { response in
                (response.status, String(buffer: response.body))
            }
        }
    }
}
