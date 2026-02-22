import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotsListTests {

    @Test func `execute json output`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshots(setId: .any).willReturn([
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "hero.png", fileSize: 2_048_000, assetState: .complete, imageWidth: 1290, imageHeight: 2796),
        ])

        let cmd = try ScreenshotsList.parse(["--set-id", "set-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        [
          {
            "assetState" : "COMPLETE",
            "fileName" : "hero.png",
            "fileSize" : 2048000,
            "id" : "img-1",
            "imageHeight" : 2796,
            "imageWidth" : 1290,
            "setId" : "set-1"
          }
        ]
        """)
    }

    @Test func `execute json output with nil dimensions`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshots(setId: .any).willReturn([
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "screen.png", fileSize: 100, assetState: nil, imageWidth: nil, imageHeight: nil),
        ])

        let cmd = try ScreenshotsList.parse(["--set-id", "set-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        [
          {
            "fileName" : "screen.png",
            "fileSize" : 100,
            "id" : "img-1",
            "setId" : "set-1"
          }
        ]
        """)
    }

    @Test func `execute passes setId to repository`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshots(setId: .value("set-77")).willReturn([])

        let cmd = try ScreenshotsList.parse(["--set-id", "set-77"])
        _ = try await cmd.execute(repo: mockRepo)
    }
}
