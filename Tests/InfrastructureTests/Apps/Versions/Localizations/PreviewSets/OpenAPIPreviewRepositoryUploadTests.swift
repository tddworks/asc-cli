@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct OpenAPIPreviewRepositoryUploadTests {

    @Test func `should reserve the preview with the file's name, size and video type and commit it with its checksum`() async throws {
        let file = try UploadFixtures.file(named: "demo.mov", contents: "MOVDATA")
        let stub = StubAPIClient()
        stub.willReturnPages([
            try Self.preview(#"{"data":{"type":"appPreviews","id":"prev-1","attributes":{"fileName":"demo.mov","fileSize":7,"uploadOperations":[]}},"links":{"self":""}}"#),
            try Self.preview(#"{"data":{"type":"appPreviews","id":"prev-1","attributes":{"fileName":"demo.mov","fileSize":7,"mimeType":"video/quicktime","previewFrameTimeCode":"00:00:05:00","videoDeliveryState":{"state":"UPLOAD_COMPLETE"}}},"links":{"self":""}}"#),
        ])

        let preview = try await OpenAPIPreviewRepository(client: stub).uploadPreview(setId: "pset-1", fileURL: file, previewFrameTimeCode: "00:00:05:00")

        #expect(preview == AppPreview(id: "prev-1", setId: "pset-1", fileName: "demo.mov", fileSize: 7, mimeType: "video/quicktime",
                                      videoDeliveryState: .uploadComplete, previewFrameTimeCode: "00:00:05:00"))
        #expect(stub.requests.map { "\($0.method) \($0.path) \($0.body ?? "")" } == [
            #"POST /v1/appPreviews {"data":{"attributes":{"fileName":"demo.mov","fileSize":7,"mimeType":"video\/quicktime","previewFrameTimeCode":"00:00:05:00"},"relationships":{"appPreviewSet":{"data":{"id":"pset-1","type":"appPreviewSets"}}},"type":"appPreviews"}}"#,
            #"PATCH /v1/appPreviews/prev-1 {"data":{"attributes":{"sourceFileChecksum":"13930ff759ec0d9b5a79272a3de5ab7f","uploaded":true},"id":"prev-1","type":"appPreviews"}}"#,
        ])
    }

    @Test func `should fail without committing the preview when App Store Connect's storage refuses a part`() async throws {
        let file = try UploadFixtures.file(named: "demo.mov", contents: "MOVDATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.preview(#"{"data":{"type":"appPreviews","id":"prev-1","attributes":{"fileName":"demo.mov","fileSize":7,"uploadOperations":[{"method":"PUT","url":"https://upload.example.com/1","length":7,"offset":0}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 500)

        await #expect(throws: (any Error).self) {
            try await OpenAPIPreviewRepository(client: stub, uploader: UploadOperationsExecutor(http: http)).uploadPreview(setId: "pset-1", fileURL: file, previewFrameTimeCode: nil)
        }
        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["POST /v1/appPreviews"])
    }

    @Test func `should fail without sending or committing the preview when App Store Connect leaves out a part's method`() async throws {
        let file = try UploadFixtures.file(named: "demo.mov", contents: "MOVDATA")
        let stub = StubAPIClient()
        stub.willReturn(try Self.preview(#"{"data":{"type":"appPreviews","id":"prev-1","attributes":{"fileName":"demo.mov","fileSize":7,"uploadOperations":[{"url":"https://upload.example.com/0","length":3,"offset":0},{"method":"PUT","url":"https://upload.example.com/1","length":4,"offset":3}]}},"links":{"self":""}}"#))
        let http = SequencedStubHTTPClient()
        http.enqueue(json: "", statusCode: 200)

        await #expect(throws: (any Error).self) {
            _ = try await OpenAPIPreviewRepository(client: stub, uploader: UploadOperationsExecutor(http: http)).uploadPreview(setId: "pset-1", fileURL: file, previewFrameTimeCode: nil)
        }
        #expect(http.capturedRequests.isEmpty)
        #expect(stub.requests.map { "\($0.method) \($0.path)" } == ["POST /v1/appPreviews"])
    }

    static func preview(_ json: String) throws -> AppPreviewResponse {
        try UploadFixtures.decode(AppPreviewResponse.self, json)
    }
}
