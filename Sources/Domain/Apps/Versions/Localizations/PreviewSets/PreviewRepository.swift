import Foundation
import Mockable

@Mockable
public protocol PreviewRepository: Sendable {
    func listPreviewSets(localizationId: String) async throws -> [AppPreviewSet]
    func createPreviewSet(localizationId: String, previewType: PreviewType) async throws -> AppPreviewSet
    func listPreviews(setId: String) async throws -> [AppPreview]
    func uploadPreview(setId: String, fileURL: URL, previewFrameTimeCode: String?) async throws -> AppPreview
}
