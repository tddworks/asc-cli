import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppPreviewsCommandTests {

    // MARK: - list

    @Test func `listed previews include file metadata and affordances`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).listPreviews(setId: .any).willReturn([
            AppPreview(
                id: "prev-1",
                setId: "set-1",
                fileName: "preview.mp4",
                fileSize: 10_485_760,
                mimeType: "video/mp4",
                assetDeliveryState: AppPreview.AssetDeliveryState.complete,
                videoDeliveryState: AppPreview.VideoDeliveryState.complete
            ),
        ])

        let cmd = try AppPreviewsList.parse(["--set-id", "set-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviews" : "asc app-previews list --set-id set-1"
              },
              "assetDeliveryState" : "COMPLETE",
              "fileName" : "preview.mp4",
              "fileSize" : 10485760,
              "id" : "prev-1",
              "mimeType" : "video\\/mp4",
              "setId" : "set-1",
              "videoDeliveryState" : "COMPLETE"
            }
          ]
        }
        """)
    }

    @Test func `previews without optional fields omit them from json`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).listPreviews(setId: .any).willReturn([
            AppPreview(
                id: "prev-1",
                setId: "set-1",
                fileName: "preview.mp4",
                fileSize: 100
            ),
        ])

        let cmd = try AppPreviewsList.parse(["--set-id", "set-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviews" : "asc app-previews list --set-id set-1"
              },
              "fileName" : "preview.mp4",
              "fileSize" : 100,
              "id" : "prev-1",
              "setId" : "set-1"
            }
          ]
        }
        """)
    }

    @Test func `previews in processing state include video delivery state`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).listPreviews(setId: .any).willReturn([
            AppPreview(
                id: "prev-1",
                setId: "set-1",
                fileName: "preview.mp4",
                fileSize: 10_485_760,
                mimeType: "video/mp4",
                assetDeliveryState: AppPreview.AssetDeliveryState.uploadComplete,
                videoDeliveryState: AppPreview.VideoDeliveryState.processing
            ),
        ])

        let cmd = try AppPreviewsList.parse(["--set-id", "set-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviews" : "asc app-previews list --set-id set-1"
              },
              "assetDeliveryState" : "UPLOAD_COMPLETE",
              "fileName" : "preview.mp4",
              "fileSize" : 10485760,
              "id" : "prev-1",
              "mimeType" : "video\\/mp4",
              "setId" : "set-1",
              "videoDeliveryState" : "PROCESSING"
            }
          ]
        }
        """)
    }

    @Test func `table output for previews includes all row fields`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).listPreviews(setId: .any).willReturn([
            AppPreview(
                id: "prev-1",
                setId: "set-1",
                fileName: "preview.mp4",
                fileSize: 10_485_760,
                mimeType: "video/mp4",
                assetDeliveryState: AppPreview.AssetDeliveryState.complete,
                videoDeliveryState: AppPreview.VideoDeliveryState.complete
            ),
        ])

        let cmd = try AppPreviewsList.parse(["--set-id", "set-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("prev-1"))
        #expect(output.contains("preview.mp4"))
        #expect(output.contains("Complete"))
    }

    // MARK: - upload

    @Test func `uploaded preview is returned with file metadata and affordances`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).uploadPreview(setId: .any, fileURL: .any, previewFrameTimeCode: .any).willReturn(
            AppPreview(
                id: "prev-new",
                setId: "set-1",
                fileName: "hero.mp4",
                fileSize: 20_971_520,
                mimeType: "video/mp4",
                assetDeliveryState: AppPreview.AssetDeliveryState.complete,
                videoDeliveryState: AppPreview.VideoDeliveryState.complete
            )
        )

        let cmd = try AppPreviewsUpload.parse(["--set-id", "set-1", "--file", "/tmp/hero.mp4", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviews" : "asc app-previews list --set-id set-1"
              },
              "assetDeliveryState" : "COMPLETE",
              "fileName" : "hero.mp4",
              "fileSize" : 20971520,
              "id" : "prev-new",
              "mimeType" : "video\\/mp4",
              "setId" : "set-1",
              "videoDeliveryState" : "COMPLETE"
            }
          ]
        }
        """)
    }

    @Test func `upload with preview frame timecode passes timecode to repository`() async throws {
        let mockRepo = MockAppPreviews()
        given(mockRepo).uploadPreview(setId: .any, fileURL: .any, previewFrameTimeCode: .any).willReturn(
            AppPreview(
                id: "prev-1",
                setId: "set-1",
                fileName: "clip.mp4",
                fileSize: 5_242_880,
                mimeType: "video/mp4",
                assetDeliveryState: AppPreview.AssetDeliveryState.awaitingUpload,
                videoDeliveryState: AppPreview.VideoDeliveryState.awaitingUpload
            )
        )

        let cmd = try AppPreviewsUpload.parse([
            "--set-id", "set-1",
            "--file", "/tmp/clip.mp4",
            "--preview-frame-time-code", "00:00:05",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPreviews" : "asc app-previews list --set-id set-1"
              },
              "assetDeliveryState" : "AWAITING_UPLOAD",
              "fileName" : "clip.mp4",
              "fileSize" : 5242880,
              "id" : "prev-1",
              "mimeType" : "video\\/mp4",
              "setId" : "set-1",
              "videoDeliveryState" : "AWAITING_UPLOAD"
            }
          ]
        }
        """)
    }
}
