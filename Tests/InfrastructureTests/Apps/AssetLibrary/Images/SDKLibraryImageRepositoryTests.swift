@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation
import Testing
@testable import Infrastructure

@Suite
struct SDKLibraryImageRepositoryTests {

    // MARK: - listImages

    @Test func `should tie each image to the library it was listed under with its processed size`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.images("""
        {"data":[{"type":"appAssetLibraryImages","id":"img-1","attributes":{
          "category":"APP_SCREENSHOTS_AND_PREVIEWS","createdDate":"2026-08-11T22:44:12.019637Z",
          "fileName":"home.png","fileSize":14619,"referenceName":"Home","specId":"spec-1","state":"PREPARE_FOR_SUBMISSION",
          "stateDetails":null,"imageAsset":{"templateUrl":"https://example.com/{w}x{h}bb.{f}","width":1290,"height":2796}
        }}],"links":{"self":""}}
        """))

        let images = try await Self.repo(stub).listImages(libraryId: "lib-9", imageId: nil, state: nil, category: nil)

        #expect(images == [
            LibraryImage(id: "img-1", libraryId: "lib-9", fileName: "home.png", fileSize: 14619,
                         category: .appScreenshotsAndPreviews, state: .prepareForSubmission, referenceName: "Home",
                         specId: "spec-1", width: 1290, height: 2796, templateUrl: "https://example.com/{w}x{h}bb.{f}",
                         createdDate: "2026-08-11T22:44:12.019637Z"),
        ])
    }

    @Test func `should skip an image in a state asc does not know yet instead of failing the whole list`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.images("""
        {"data":[
          {"type":"appAssetLibraryImages","id":"img-1","attributes":{"category":"CREATIVE_ASSETS","fileName":"a.png","fileSize":1,"state":"QUARANTINED"}},
          {"type":"appAssetLibraryImages","id":"img-2","attributes":{"category":"CREATIVE_ASSETS","fileName":"b.png","fileSize":2,"state":"FAILED",
            "stateDetails":[{"code":"IMAGE_INCORRECT_DIMENSIONS","description":"Wrong size"}]}}
        ],"links":{"self":""}}
        """))

        let images = try await Self.repo(stub).listImages(libraryId: "lib-9", imageId: nil, state: nil, category: nil)

        #expect(images == [
            LibraryImage(id: "img-2", libraryId: "lib-9", fileName: "b.png", fileSize: 2, category: .creativeAssets, state: .failed,
                         stateDetails: [AssetStateDetail(code: "IMAGE_INCORRECT_DIMENSIONS", description: "Wrong size")]),
        ])
    }

    @Test func `should ask App Store Connect for just the image, state and category requested`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.images(#"{"data":[],"links":{"self":""}}"#))

        _ = try await Self.repo(stub).listImages(libraryId: "lib-9", imageId: "img-1", state: .approved, category: .creativeAssets)

        #expect(stub.lastPath == "/v1/appAssetLibraries/lib-9/images")
        #expect(stub.lastQuery?.map { "\($0.0)=\($0.1 ?? "")" } == [
            "filter[category]=CREATIVE_ASSETS", "filter[state]=APPROVED", "filter[id]=img-1", "limit=200",
        ])
    }

    @Test func `should read every page of a large library`() async throws {
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.images("""
            {"data":[{"type":"appAssetLibraryImages","id":"img-1","attributes":{"category":"CREATIVE_ASSETS","fileName":"a.png","fileSize":1,"state":"APPROVED"}}],
             "links":{"self":""},"meta":{"paging":{"limit":1,"nextCursor":"next"}}}
            """),
            try Self.images("""
            {"data":[{"type":"appAssetLibraryImages","id":"img-2","attributes":{"category":"CREATIVE_ASSETS","fileName":"b.png","fileSize":2,"state":"APPROVED"}}],
             "links":{"self":""},"meta":{"paging":{"limit":1}}}
            """),
        ])

        let images = try await Self.repo(stub).listImages(libraryId: "lib-9", imageId: nil, state: nil, category: nil)

        #expect(images.map(\.id) == ["img-1", "img-2"])
    }

    // MARK: - uploadImage

    @Test func `should reserve, send and commit the file and show the image App Store Connect is processing`() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID().uuidString).png")
        try Data("PNGDATA".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.image("""
            {"data":{"type":"appAssetLibraryImages","id":"img-1","attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS",
              "fileName":"\(file.lastPathComponent)","fileSize":7,"state":"AWAITING_UPLOAD",
              "uploadOperations":[{"method":"PUT","url":"https://upload.example.com/1","length":7,"offset":0,"requestHeaders":[]}]}},
             "links":{"self":""}}
            """),
            try Self.image("""
            {"data":{"type":"appAssetLibraryImages","id":"img-1","attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS",
              "fileName":"\(file.lastPathComponent)","fileSize":7,"referenceName":"Home","state":"UPLOAD_COMPLETE"}},
             "links":{"self":""}}
            """),
        ])
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 200)

        let image = try await Self.repo(stub, http: http).uploadImage(
            libraryId: "lib-9", fileURL: file, category: .appScreenshotsAndPreviews, referenceName: "Home"
        )

        #expect(image == LibraryImage(id: "img-1", libraryId: "lib-9", fileName: file.lastPathComponent, fileSize: 7,
                                      category: .appScreenshotsAndPreviews, state: .uploadComplete, referenceName: "Home"))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/appAssetLibraryImages {"data":{"attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS","fileName":"\#(file.lastPathComponent)","fileSize":7,"referenceName":"Home"},"relationships":{"assetLibrary":{"data":{"id":"lib-9","type":"appAssetLibraries"}}},"type":"appAssetLibraryImages"}}"#,
            #"PATCH /v1/appAssetLibraryImages/img-1 {"data":{"attributes":{"uploaded":true},"id":"img-1","type":"appAssetLibraryImages"}}"#,
        ])
        #expect(String(data: http.capturedRequests.first?.httpBody ?? Data(), encoding: .utf8) == "PNGDATA")
    }

    // MARK: - updateImage

    @Test func `should rename and archive the image by sending only what changed`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(try Self.image("""
        {"data":{"type":"appAssetLibraryImages","id":"img-1","attributes":{"category":"APP_SCREENSHOTS_AND_PREVIEWS",
          "fileName":"home.png","fileSize":7,"referenceName":"Home (Fall)","state":"ARCHIVED"}},"links":{"self":""}}
        """))

        let image = try await Self.repo(stub).updateImage(libraryId: "lib-9", imageId: "img-1", referenceName: "Home (Fall)", isArchived: true)

        #expect(image == LibraryImage(id: "img-1", libraryId: "lib-9", fileName: "home.png", fileSize: 7,
                                      category: .appScreenshotsAndPreviews, state: .archived, referenceName: "Home (Fall)"))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"PATCH /v1/appAssetLibraryImages/img-1 {"data":{"attributes":{"archived":true,"referenceName":"Home (Fall)"},"id":"img-1","type":"appAssetLibraryImages"}}"#,
        ])
    }

    // MARK: - deleteImage

    @Test func `should delete the image from the library`() async throws {
        let stub = StubAPIClient()

        try await Self.repo(stub).deleteImage(imageId: "img-1")

        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["DELETE /v1/appAssetLibraryImages/img-1"])
    }

    // MARK: - Fixtures

    static func repo(_ stub: StubAPIClient, http: any HTTPPerforming = SequencedStubHTTPClient()) -> SDKLibraryImageRepository {
        SDKLibraryImageRepository(client: stub, uploader: UploadOperationsExecutor(http: http))
    }

    static func images(_ json: String) throws -> LibraryAssetsDocument {
        try JSONDecoder().decode(LibraryAssetsDocument.self, from: Data(json.utf8))
    }

    static func image(_ json: String) throws -> LibraryAssetDocument {
        try JSONDecoder().decode(LibraryAssetDocument.self, from: Data(json.utf8))
    }
}
