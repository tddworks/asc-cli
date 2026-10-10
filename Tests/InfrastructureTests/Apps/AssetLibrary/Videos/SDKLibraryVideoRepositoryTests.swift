@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation
import Testing
@testable import Infrastructure

@Suite
struct SDKLibraryVideoRepositoryTests {

    @Test func `should tie each video to the library it was listed under with its preview frame and processed video`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.videos("""
        {"data":[{"type":"appAssetLibraryVideos","id":"vid-1","attributes":{
          "category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"preview.mp4","fileSize":31457280,"referenceName":"Fall",
          "specId":"spec-v","state":"PREPARE_FOR_SUBMISSION","previewFrameTimeCode":"00:00:03:00",
          "previewFrameImage":{"state":"COMPLETE","image":{"templateUrl":"https://example.com/{w}x{h}bb.{f}","width":886,"height":1920}},
          "videoAsset":"https://example.com/preview.m3u8"
        }}],"links":{"self":""}}
        """))

        let videos = try await Self.repo(stub).listVideos(libraryId: "lib-9", videoId: "vid-1", state: nil, category: nil)

        #expect(videos == [
            LibraryVideo(id: "vid-1", libraryId: "lib-9", fileName: "preview.mp4", fileSize: 31457280,
                         category: .appScreenshotsAndPreviews, state: .prepareForSubmission, referenceName: "Fall",
                         specId: "spec-v", width: 886, height: 1920, previewFrameTimeCode: "00:00:03:00",
                         previewFrameState: "COMPLETE", previewFrameUrl: "https://example.com/{w}x{h}bb.{f}",
                         videoUrl: "https://example.com/preview.m3u8"),
        ])
        #expect(stub.lastPath == "/v1/appAssetLibraries/lib-9/videos")
        #expect(stub.lastQuery?.map { "\($0.0)=\($0.1 ?? "")" } == ["filter[id]=vid-1", "limit=200"])
    }

    @Test func `should reserve the video with its preview frame, send it and commit it`() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("preview-\(UUID().uuidString).mp4")
        try Data("MOVIEDATA".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.video("""
            {"data":{"type":"appAssetLibraryVideos","id":"vid-1","attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS",
              "fileName":"p.mp4","fileSize":9,"state":"AWAITING_UPLOAD",
              "uploadOperations":[{"method":"PUT","url":"https://upload.example.com/1","length":5,"offset":0},
                                  {"method":"PUT","url":"https://upload.example.com/2","length":4,"offset":5}]}},"links":{"self":""}}
            """),
            try Self.video("""
            {"data":{"type":"appAssetLibraryVideos","id":"vid-1","attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS",
              "fileName":"p.mp4","fileSize":9,"state":"UPLOAD_COMPLETE","previewFrameTimeCode":"00:00:03:00"}},"links":{"self":""}}
            """),
        ])
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "")
        http.enqueue(json: "")

        let video = try await Self.repo(stub, http: http).uploadVideo(
            libraryId: "lib-9", fileURL: file, category: .appScreenshotsAndPreviews, referenceName: nil, previewFrameTimeCode: "00:00:03:00"
        )

        #expect(video == LibraryVideo(id: "vid-1", libraryId: "lib-9", fileName: "p.mp4", fileSize: 9,
                                      category: .appScreenshotsAndPreviews, state: .uploadComplete, previewFrameTimeCode: "00:00:03:00"))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/appAssetLibraryVideos {"data":{"attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"\#(file.lastPathComponent)","fileSize":9,"previewFrameTimeCode":"00:00:03:00"},"relationships":{"assetLibrary":{"data":{"id":"lib-9","type":"appAssetLibraries"}}},"type":"appAssetLibraryVideos"}}"#,
            #"PATCH /v1/appAssetLibraryVideos/vid-1 {"data":{"attributes":{"uploaded":true},"id":"vid-1","type":"appAssetLibraryVideos"}}"#,
        ])
        #expect(http.capturedRequests.map { String(data: $0.httpBody ?? Data(), encoding: .utf8) } == ["MOVIE", "DATA"])
    }

    @Test func `should rename and archive the video by sending only what changed`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.video("""
        {"data":{"type":"appAssetLibraryVideos","id":"vid-1","attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS",
          "fileName":"p.mp4","fileSize":9,"state":"ARCHIVED"}},"links":{"self":""}}
        """))

        let video = try await Self.repo(stub).updateVideo(libraryId: "lib-9", videoId: "vid-1", referenceName: nil, isArchived: true)

        #expect(video.state == .archived)
        #expect(video.libraryId == "lib-9")
        #expect(stub.requests.first?.body == #"{"data":{"attributes":{"archived":true},"id":"vid-1","type":"appAssetLibraryVideos"}}"#)
    }

    @Test func `should delete the video from the library`() async throws {
        let stub = StubAPIClient()

        try await Self.repo(stub).deleteVideo(videoId: "vid-1")

        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["DELETE /v1/appAssetLibraryVideos/vid-1"])
    }

    // MARK: - Fixtures

    static func repo(_ stub: StubAPIClient, http: any HTTPPerforming = SequencedStubHTTPClient()) -> SDKLibraryVideoRepository {
        SDKLibraryVideoRepository(client: stub, uploader: UploadOperationsExecutor(http: http))
    }

    static func videos(_ json: String) throws -> LibraryAssetsDocument {
        try JSONDecoder().decode(LibraryAssetsDocument.self, from: Data(json.utf8))
    }

    static func video(_ json: String) throws -> LibraryAssetDocument {
        try JSONDecoder().decode(LibraryAssetDocument.self, from: Data(json.utf8))
    }
}
