import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ScreenshotsUploadTests {

    @Test func `uploaded screenshot is returned with file metadata`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).uploadScreenshot(setId: .any, fileURL: .any).willReturn(
            AppScreenshot(id: "img-new", setId: "set-1", fileName: "hero.png", fileSize: 2_048_000, assetState: .complete, imageWidth: 1290, imageHeight: 2796)
        )

        let cmd = try ScreenshotsUpload.parse(["--set-id", "set-1", "--file", "/tmp/hero.png", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc screenshots delete --screenshot-id img-new",
                "listScreenshots" : "asc screenshots list --set-id set-1"
              },
              "assetState" : "COMPLETE",
              "fileName" : "hero.png",
              "fileSize" : 2048000,
              "id" : "img-new",
              "imageHeight" : 2796,
              "imageWidth" : 1290,
              "setId" : "set-1"
            }
          ]
        }
        """)
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).uploadScreenshot(setId: .any, fileURL: .any).willReturn(
            AppScreenshot(id: "img-1", setId: "set-1", fileName: "screen.png", fileSize: 1_048_576, assetState: .complete, imageWidth: 390, imageHeight: 844)
        )

        let cmd = try ScreenshotsUpload.parse(["--set-id", "set-1", "--file", "/tmp/screen.png", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("img-1"))
        #expect(output.contains("screen.png"))
        #expect(output.contains("Complete"))
    }
}
