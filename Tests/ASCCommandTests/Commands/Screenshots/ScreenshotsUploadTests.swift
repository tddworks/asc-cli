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
        [
          {
            "assetState" : "COMPLETE",
            "fileName" : "hero.png",
            "fileSize" : 2048000,
            "id" : "img-new",
            "imageHeight" : 2796,
            "imageWidth" : 1290,
            "setId" : "set-1"
          }
        ]
        """)
    }
}
