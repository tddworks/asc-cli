import Foundation
import Mockable

@Mockable
public protocol LibraryVideoRepository: Sendable {
    /// Videos in the library, optionally narrowed to one video, a state or a category.
    func listVideos(libraryId: String, videoId: String?, state: LibraryAssetState?, category: AssetCategory?) async throws -> [LibraryVideo]
    /// Reserves, uploads (streamed from disk) and commits the file.
    func uploadVideo(libraryId: String, fileURL: URL, category: AssetCategory, referenceName: String?, previewFrameTimeCode: String?) async throws -> LibraryVideo
    func deleteVideo(videoId: String) async throws
    /// Renames and/or archives the video; `nil` leaves a field as it is.
    func updateVideo(libraryId: String, videoId: String, referenceName: String?, isArchived: Bool?) async throws -> LibraryVideo
}
