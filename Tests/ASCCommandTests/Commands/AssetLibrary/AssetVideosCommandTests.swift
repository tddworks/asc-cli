import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AssetVideosCommandTests {

    @Test func `should list the library's videos with their preview frame and what can be done with each`() async throws {
        let mockRepo = MockLibraryVideoRepository()
        given(mockRepo).listVideos(libraryId: .value("lib-1"), videoId: .value(nil), state: .value(nil), category: .value(nil)).willReturn([
            LibraryVideo(id: "vid-1", libraryId: "lib-1", fileName: "preview.mp4", fileSize: 10,
                         category: .appScreenshotsAndPreviews, state: .prepareForSubmission,
                         previewFrameTimeCode: "00:00:03:00", previewFrameState: "COMPLETE"),
        ])

        let cmd = try AssetVideosList.parse(["--library-id", "lib-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc asset-videos delete --video-id vid-1",
                "listPlacements" : "asc asset-placements list --video-id vid-1",
                "listVideos" : "asc asset-videos list --library-id lib-1",
                "place" : "asc asset-placements create --localization-id <localization-id> --placement-group <placement-group> --placement-type APP_PREVIEW --video-id vid-1"
              },
              "category" : "APP_SCREENSHOTS_AND_PREVIEWS",
              "fileName" : "preview.mp4",
              "fileSize" : 10,
              "id" : "vid-1",
              "libraryId" : "lib-1",
              "previewFrameState" : "COMPLETE",
              "previewFrameTimeCode" : "00:00:03:00",
              "state" : "PREPARE_FOR_SUBMISSION"
            }
          ]
        }
        """)
    }

    @Test func `should upload the video with its preview frame and wait until App Store Connect has processed it`() async throws {
        let mockRepo = MockLibraryVideoRepository()
        given(mockRepo).uploadVideo(libraryId: .value("lib-1"), fileURL: .any, category: .value(.appScreenshotsAndPreviews),
                                    referenceName: .value("Fall"), previewFrameTimeCode: .value("00:00:05:00"))
            .willReturn(LibraryVideo(id: "vid-1", libraryId: "lib-1", fileName: "p.mp4", fileSize: 9, category: .appScreenshotsAndPreviews, state: .uploadComplete))
        given(mockRepo).listVideos(libraryId: .value("lib-1"), videoId: .value("vid-1"), state: .value(nil), category: .value(nil))
            .willReturn([LibraryVideo(id: "vid-1", libraryId: "lib-1", fileName: "p.mp4", fileSize: 9, category: .appScreenshotsAndPreviews,
                                      state: .prepareForSubmission, referenceName: "Fall", previewFrameTimeCode: "00:00:05:00")])

        let cmd = try AssetVideosUpload.parse([
            "--library-id", "lib-1", "--file", "p.mp4", "--reference-name", "Fall", "--preview-frame-time-code", "00:00:05:00", "--wait",
        ])
        let output = try await cmd.execute(repo: mockRepo, sleep: { _ in })

        #expect(output == #"{"data":[{"affordances":{"delete":"asc asset-videos delete --video-id vid-1","listPlacements":"asc asset-placements list --video-id vid-1","listVideos":"asc asset-videos list --library-id lib-1","place":"asc asset-placements create --localization-id <localization-id> --placement-group <placement-group> --placement-type APP_PREVIEW --video-id vid-1"},"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"p.mp4","fileSize":9,"id":"vid-1","libraryId":"lib-1","previewFrameTimeCode":"00:00:05:00","referenceName":"Fall","state":"PREPARE_FOR_SUBMISSION"}]}"#)
    }

    @Test func `should archive an approved video`() async throws {
        let mockRepo = MockLibraryVideoRepository()
        given(mockRepo).updateVideo(libraryId: .value("lib-1"), videoId: .value("vid-1"), referenceName: .value(nil), isArchived: .value(true))
            .willReturn(LibraryVideo(id: "vid-1", libraryId: "lib-1", fileName: "p.mp4", fileSize: 9, category: .appScreenshotsAndPreviews, state: .archived))

        let cmd = try AssetVideosUpdate.parse(["--library-id", "lib-1", "--video-id", "vid-1", "--archived", "true"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == #"{"data":[{"affordances":{"delete":"asc asset-videos delete --video-id vid-1","listPlacements":"asc asset-placements list --video-id vid-1","listVideos":"asc asset-videos list --library-id lib-1"},"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"p.mp4","fileSize":9,"id":"vid-1","libraryId":"lib-1","state":"ARCHIVED"}]}"#)
    }

    @Test func `should ask for a new name or archiving when updating a video`() {
        #expect(throws: (any Error).self) {
            try AssetVideosUpdate.parse(["--library-id", "lib-1", "--video-id", "vid-1"])
        }
    }

    @Test func `should report App Store Connect's refusal to delete a video that is still placed`() async throws {
        let mockRepo = MockLibraryVideoRepository()
        given(mockRepo).deleteVideo(videoId: .value("vid-1")).willThrow(APIError.unknown("STATE_ERROR.ASSET_HAS_PLACEMENTS"))

        let cmd = try AssetVideosDelete.parse(["--video-id", "vid-1"])

        await #expect(throws: APIError.unknown("STATE_ERROR.ASSET_HAS_PLACEMENTS")) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}
