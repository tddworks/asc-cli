import Foundation
import Testing
@testable import Domain

@Suite
struct LibraryVideoTests {

    // MARK: - Schema

    @Test func `should belong to the library it was listed under and leave out what App Store Connect has not filled in`() throws {
        let video = MockRepositoryFactory.makeLibraryVideo(
            id: "vid-1", libraryId: "lib-9", fileName: "preview.mp4", fileSize: 31457280,
            category: .appScreenshotsAndPreviews, state: .awaitingUpload
        )

        #expect(try Self.json(video) == #"{"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"preview.mp4","fileSize":31457280,"id":"vid-1","libraryId":"lib-9","state":"AWAITING_UPLOAD"}"#)
    }

    @Test func `should show the preview frame and processed video once App Store Connect has them`() throws {
        let video = MockRepositoryFactory.makeLibraryVideo(
            id: "vid-1", libraryId: "lib-9", fileName: "preview.mp4", fileSize: 10, state: .prepareForSubmission,
            referenceName: "Fall", specId: "spec-v", width: 886, height: 1920,
            previewFrameTimeCode: "00:00:03:00", previewFrameState: "COMPLETE",
            previewFrameUrl: "https://example.com/{w}x{h}bb.{f}", videoUrl: "https://example.com/preview.m3u8"
        )

        #expect(try Self.json(video) == #"{"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"preview.mp4","fileSize":10,"height":1920,"id":"vid-1","libraryId":"lib-9","previewFrameState":"COMPLETE","previewFrameTimeCode":"00:00:03:00","previewFrameUrl":"https://example.com/{w}x{h}bb.{f}","referenceName":"Fall","specId":"spec-v","state":"PREPARE_FOR_SUBMISSION","videoUrl":"https://example.com/preview.m3u8","width":886}"#)
    }

    // MARK: - Affordances

    @Test func `should offer placing a processed preview as an app preview`() {
        let video = MockRepositoryFactory.makeLibraryVideo(id: "vid-1", libraryId: "lib-1", state: .prepareForSubmission)

        #expect(video.affordances == [
            "delete": "asc asset-videos delete --video-id vid-1",
            "listPlacements": "asc asset-placements list --video-id vid-1",
            "listVideos": "asc asset-videos list --library-id lib-1",
            "place": "asc asset-placements create --localization-id <localization-id> --placement-group <placement-group> --placement-type APP_PREVIEW --video-id vid-1",
        ])
    }

    @Test func `should offer a refresh instead of placing while the video is still being processed`() {
        let video = MockRepositoryFactory.makeLibraryVideo(id: "vid-1", libraryId: "lib-1", state: .uploadComplete)

        #expect(video.affordances["place"] == nil)
        #expect(video.affordances["refresh"] == "asc asset-videos list --library-id lib-1 --video-id vid-1")
    }

    @Test func `should offer archiving and hide delete once App Review approved the video`() {
        let approved = MockRepositoryFactory.makeLibraryVideo(id: "vid-1", libraryId: "lib-1", state: .approved)
        let inReview = MockRepositoryFactory.makeLibraryVideo(id: "vid-2", state: .inReview)

        #expect(approved.affordances["archive"] == "asc asset-videos update --archived true --library-id lib-1 --video-id vid-1")
        #expect(inReview.affordances["archive"] == nil)
        #expect(inReview.affordances["delete"] == nil)
    }

    @Test func `should point to its placements, update and deletion over REST`() {
        let video = MockRepositoryFactory.makeLibraryVideo(id: "vid-1", libraryId: "lib-1", state: .approved)

        #expect(video.apiLinks["listVideos"] == APILink(href: "/api/v1/asset-library/lib-1/videos", method: "GET"))
        #expect(video.apiLinks["listPlacements"] == APILink(href: "/api/v1/asset-videos/vid-1/placements", method: "GET"))
        #expect(video.apiLinks["archive"] == APILink(href: "/api/v1/asset-videos/vid-1", method: "PATCH"))
        #expect(video.apiLinks["delete"] == APILink(href: "/api/v1/asset-videos/vid-1", method: "DELETE"))
    }

    @Test func `should show file, category, state and reference name in a table`() {
        let video = MockRepositoryFactory.makeLibraryVideo(id: "vid-1", fileName: "p.mp4", state: .approved, referenceName: "Fall")

        #expect(LibraryVideo.tableHeaders == ["ID", "File Name", "Category", "State", "Reference Name"])
        #expect(video.tableRow == ["vid-1", "p.mp4", "APP_SCREENSHOTS_AND_PREVIEWS", "APPROVED", "Fall"])
    }

    static func json(_ value: some Encodable) throws -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(data: try encoder.encode(value), encoding: .utf8)
    }
}
