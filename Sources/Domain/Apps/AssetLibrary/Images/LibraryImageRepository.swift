import Foundation
import Mockable

@Mockable
public protocol LibraryImageRepository: Sendable {
    /// Images in the library, optionally narrowed to one image, a state or a category.
    func listImages(libraryId: String, imageId: String?, state: LibraryAssetState?, category: AssetCategory?) async throws -> [LibraryImage]
    /// Reserves, uploads and commits the file; returns the image as App Store Connect sees it after the commit.
    func uploadImage(libraryId: String, fileURL: URL, category: AssetCategory, referenceName: String?) async throws -> LibraryImage
    func deleteImage(imageId: String) async throws
}
