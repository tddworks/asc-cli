@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKLibraryImageRepository: LibraryImageRepository, @unchecked Sendable {
    private let client: any APIClient
    private let uploader: UploadOperationsExecutor

    public init(client: any APIClient, uploader: UploadOperationsExecutor = UploadOperationsExecutor()) {
        self.client = client
        self.uploader = uploader
    }

    public func listImages(
        libraryId: String,
        imageId: String?,
        state: LibraryAssetState?,
        category: AssetCategory?
    ) async throws -> [LibraryImage] {
        let sdk = APIEndpoint.v1.appAssetLibraries.id(libraryId).images.get(parameters: .init(
            filterCategory: category.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
            filterState: state.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
            filterID: imageId.map { [$0] },
            limit: 200
        ))
        let pages = try await client.requestAllPages(
            Request<LibraryAssetsDocument>(path: sdk.path, method: "GET", query: sdk.query, id: "appAssetLibraries_images_getToManyRelated"),
            nextCursor: { $0.meta?.paging?.nextCursor }
        )
        return pages.flatMap(\.data).compactMap { mapImage($0, libraryId: libraryId) }
    }

    public func uploadImage(
        libraryId: String,
        fileURL: URL,
        category: AssetCategory,
        referenceName: String?
    ) async throws -> LibraryImage {
        let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0

        // Reserve
        let reserveBody = AppAssetLibraryImageCreateRequest(data: .init(
            type: .appAssetLibraryImages,
            attributes: .init(
                category: AppAssetLibraryAssetCategory(rawValue: category.rawValue) ?? .appScreenshotsAndPreviews,
                fileName: fileURL.lastPathComponent,
                fileSize: fileSize,
                referenceName: referenceName
            ),
            relationships: .init(assetLibrary: .init(data: .init(type: .appAssetLibraries, id: libraryId)))
        ))
        let reserve = APIEndpoint.v1.appAssetLibraryImages.post(reserveBody)
        let reserved = try await client.request(
            Request<LibraryAssetDocument>(path: reserve.path, method: "POST", body: reserveBody, id: "appAssetLibraryImages_createInstance")
        )
        let imageId = reserved.data.id

        // Upload
        try await uploader.upload(fileURL: fileURL, operations: reserved.data.attributes?.uploadOperations ?? [])

        // Commit — asset library commits take `uploaded` alone, no checksum.
        let commitBody = AppAssetLibraryImageUpdateRequest(data: .init(
            type: .appAssetLibraryImages, id: imageId, attributes: .init(isUploaded: true)
        ))
        let commit = APIEndpoint.v1.appAssetLibraryImages.id(imageId).patch(commitBody)
        let committed = try await client.request(
            Request<LibraryAssetDocument>(path: commit.path, method: "PATCH", body: commitBody, id: "appAssetLibraryImages_updateInstance")
        )
        guard let image = mapImage(committed.data, libraryId: libraryId) else {
            throw APIError.unknown("App Store Connect returned image \(imageId) in a state asc doesn't recognise: \(committed.data.attributes?.state ?? "none")")
        }
        return image
    }

    public func updateImage(libraryId: String, imageId: String, referenceName: String?, isArchived: Bool?) async throws -> LibraryImage {
        let body = AppAssetLibraryImageUpdateRequest(data: .init(
            type: .appAssetLibraryImages, id: imageId, attributes: .init(isArchived: isArchived, referenceName: referenceName)
        ))
        let sdk = APIEndpoint.v1.appAssetLibraryImages.id(imageId).patch(body)
        let document = try await client.request(
            Request<LibraryAssetDocument>(path: sdk.path, method: "PATCH", body: body, id: "appAssetLibraryImages_updateInstance")
        )
        guard let image = mapImage(document.data, libraryId: libraryId) else {
            throw APIError.unknown("App Store Connect returned image \(imageId) in a state asc doesn't recognise: \(document.data.attributes?.state ?? "none")")
        }
        return image
    }

    public func deleteImage(imageId: String) async throws {
        try await client.request(APIEndpoint.v1.appAssetLibraryImages.id(imageId).delete)
    }

    /// `nil` when the image's state or category is one asc doesn't know yet.
    private func mapImage(_ resource: LibraryAssetResource, libraryId: String) -> LibraryImage? {
        let attributes = resource.attributes
        guard let state = attributes?.state.flatMap(LibraryAssetState.init(rawValue:)),
              let category = attributes?.category.flatMap(AssetCategory.init(rawValue:))
        else { return nil }
        let asset = attributes?.imageAsset
        return LibraryImage(
            id: resource.id,
            libraryId: libraryId,
            fileName: attributes?.fileName ?? "",
            fileSize: attributes?.fileSize ?? 0,
            category: category,
            state: state,
            referenceName: attributes?.referenceName,
            specId: attributes?.specId,
            width: asset?.width,
            height: asset?.height,
            templateUrl: asset?.templateUrl,
            stateDetails: attributes?.stateDetails?.map { AssetStateDetail(code: $0.code, description: $0.description) },
            createdDate: attributes?.createdDate
        )
    }
}
