import Foundation
import Testing
@testable import Domain

@Suite
struct AppPreviewTests {

    // MARK: - Parent ID

    @Test func `preview carries setId`() {
        let preview = MockRepositoryFactory.makePreview(id: "p-1", setId: "set-42")
        #expect(preview.setId == "set-42")
    }

    // MARK: - isComplete

    @Test func `preview is complete when videoDeliveryState is complete`() {
        let preview = MockRepositoryFactory.makePreview(videoDeliveryState: .complete)
        #expect(preview.isComplete == true)
    }

    @Test func `preview is not complete when videoDeliveryState is processing`() {
        let preview = MockRepositoryFactory.makePreview(videoDeliveryState: .processing)
        #expect(preview.isComplete == false)
    }

    @Test func `preview is not complete when videoDeliveryState is nil`() {
        let preview = MockRepositoryFactory.makePreview(videoDeliveryState: nil)
        #expect(preview.isComplete == false)
    }

    // MARK: - hasFailed

    @Test func `preview hasFailed when assetDeliveryState is failed`() {
        let preview = MockRepositoryFactory.makePreview(assetDeliveryState: .failed)
        #expect(preview.hasFailed == true)
    }

    @Test func `preview hasFailed when videoDeliveryState is failed`() {
        let preview = MockRepositoryFactory.makePreview(videoDeliveryState: .failed)
        #expect(preview.hasFailed == true)
    }

    @Test func `preview has not failed when both states are not failed`() {
        let preview = MockRepositoryFactory.makePreview(
            assetDeliveryState: .complete,
            videoDeliveryState: .complete
        )
        #expect(preview.hasFailed == false)
    }

    // MARK: - VideoDeliveryState semantic booleans

    @Test func `processing video delivery state is processing`() {
        #expect(AppPreview.VideoDeliveryState.processing.isProcessing == true)
    }

    @Test func `complete video delivery state is complete`() {
        #expect(AppPreview.VideoDeliveryState.complete.isComplete == true)
    }

    @Test func `failed video delivery state has failed`() {
        #expect(AppPreview.VideoDeliveryState.failed.hasFailed == true)
    }

    // MARK: - fileSizeDescription

    @Test func `file size description formats bytes`() {
        let preview = MockRepositoryFactory.makePreview(fileSize: 512)
        #expect(preview.fileSizeDescription == "512 B")
    }

    @Test func `file size description formats megabytes`() {
        let preview = MockRepositoryFactory.makePreview(fileSize: 10_485_760)
        #expect(preview.fileSizeDescription == "10.0 MB")
    }

    // MARK: - Codable nil omission

    @Test func `nil optional fields are omitted from json output`() throws {
        let preview = AppPreview(id: "p-1", setId: "set-1", fileName: "preview.mp4", fileSize: 1024)
        let data = try JSONEncoder().encode(preview)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("mimeType"))
        #expect(!json.contains("assetDeliveryState"))
        #expect(!json.contains("videoDeliveryState"))
        #expect(!json.contains("videoURL"))
        #expect(!json.contains("previewFrameTimeCode"))
    }

    @Test func `codable round-trip preserves all fields`() throws {
        let original = MockRepositoryFactory.makePreview(
            id: "p-1", setId: "set-1",
            assetDeliveryState: .uploadComplete,
            videoDeliveryState: .processing,
            videoURL: "https://example.com/preview.mp4",
            previewFrameTimeCode: "00:00:05"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppPreview.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Affordances

    @Test func `preview affordances include listPreviews command`() {
        let preview = MockRepositoryFactory.makePreview(id: "p-1", setId: "set-1")
        #expect(preview.affordances["listPreviews"] == "asc app-previews list --set-id set-1")
    }
}
