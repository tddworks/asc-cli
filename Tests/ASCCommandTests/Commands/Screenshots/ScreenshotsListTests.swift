import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotsListTests {

    @Test func `listed screenshots include file metadata`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshots(setId: .any).willReturn([
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "hero.png", fileSize: 2_048_000, assetState: .complete, imageWidth: 1290, imageHeight: 2796),
        ])

        let cmd = try ScreenshotsList.parse(["--set-id", "set-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc screenshots delete --screenshot-id img-1",
                "listScreenshots" : "asc screenshots list --set-id set-1"
              },
              "assetState" : "COMPLETE",
              "fileName" : "hero.png",
              "fileSize" : 2048000,
              "id" : "img-1",
              "imageHeight" : 2796,
              "imageWidth" : 1290,
              "setId" : "set-1"
            }
          ]
        }
        """)
    }

    @Test func `screenshots without dimensions omit size fields`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshots(setId: .any).willReturn([
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "screen.png", fileSize: 100, assetState: nil, imageWidth: nil, imageHeight: nil),
        ])

        let cmd = try ScreenshotsList.parse(["--set-id", "set-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc screenshots delete --screenshot-id img-1",
                "listScreenshots" : "asc screenshots list --set-id set-1"
              },
              "fileName" : "screen.png",
              "fileSize" : 100,
              "id" : "img-1",
              "setId" : "set-1"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listScreenshots(setId: .any).willReturn([
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "hero.png", fileSize: 2_048_000, assetState: .complete, imageWidth: 1290, imageHeight: 2796),
        ])

        let cmd = try ScreenshotsList.parse(["--set-id", "set-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("img-1"))
        #expect(output.contains("hero.png"))
        #expect(output.contains("Complete"))
    }
}
