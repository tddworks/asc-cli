@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKLibraryVideoRepository: LibraryVideoRepository, @unchecked Sendable {
    private let client: any APIClient
    private let uploader: UploadOperationsExecutor

    public init(client: any APIClient, uploader: UploadOperationsExecutor = UploadOperationsExecutor()) {
        self.client = client
        self.uploader = uploader
    }

    public func listVideos(
        libraryId: String,
        videoId: String?,
        state: LibraryAssetState?,
        category: AssetCategory?
    ) async throws -> [LibraryVideo] {
        let sdk = APIEndpoint.v1.appAssetLibraries.id(libraryId).videos.get(parameters: .init(
            filterCategory: category.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
            filterState: state.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
            filterID: videoId.map { [$0] },
            limit: 200
        ))
        let pages = try await client.requestAllPages(
            Request<LibraryAssetsDocument>(path: sdk.path, method: "GET", query: sdk.query, id: "appAssetLibraries_videos_getToManyRelated"),
            nextCursor: { $0.meta?.paging?.nextCursor }
        )
        return pages.flatMap(\.data).compactMap { mapVideo($0, libraryId: libraryId) }
    }

    public func uploadVideo(
        libraryId: String,
        fileURL: URL,
        category: AssetCategory,
        referenceName: String?,
        previewFrameTimeCode: String?
    ) async throws -> LibraryVideo {
        let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0

        // Reserve
        let reserveBody = AppAssetLibraryVideoCreateRequest(data: .init(
            type: .appAssetLibraryVideos,
            attributes: .init(
                category: AppAssetLibraryAssetCategory(rawValue: category.rawValue) ?? .appScreenshotsAndPreviews,
                fileName: fileURL.lastPathComponent,
                fileSize: fileSize,
                previewFrameTimeCode: previewFrameTimeCode,
                referenceName: referenceName
            ),
            relationships: .init(assetLibrary: .init(data: .init(type: .appAssetLibraries, id: libraryId)))
        ))
        let reserved = try await client.request(Request<LibraryAssetDocument>(
            path: APIEndpoint.v1.appAssetLibraryVideos.path, method: "POST", body: reserveBody,
            id: "appAssetLibraryVideos_createInstance"
        ))
        let videoId = reserved.data.id

        // Upload — parts are read from disk one range at a time.
        try await uploader.upload(fileURL: fileURL, operations: reserved.data.attributes?.uploadOperations ?? [])

        // Commit
        return try await patch(libraryId: libraryId, videoId: videoId, attributes: .init(isUploaded: true))
    }

    public func deleteVideo(videoId: String) async throws {
        try await client.request(APIEndpoint.v1.appAssetLibraryVideos.id(videoId).delete)
    }

    public func updateVideo(libraryId: String, videoId: String, referenceName: String?, isArchived: Bool?) async throws -> LibraryVideo {
        try await patch(libraryId: libraryId, videoId: videoId, attributes: .init(isArchived: isArchived, referenceName: referenceName))
    }

    private func patch(
        libraryId: String,
        videoId: String,
        attributes: AppAssetLibraryVideoUpdateRequest.Data.Attributes
    ) async throws -> LibraryVideo {
        let body = AppAssetLibraryVideoUpdateRequest(data: .init(type: .appAssetLibraryVideos, id: videoId, attributes: attributes))
        let document = try await client.request(Request<LibraryAssetDocument>(
            path: APIEndpoint.v1.appAssetLibraryVideos.id(videoId).path, method: "PATCH", body: body,
            id: "appAssetLibraryVideos_updateInstance"
        ))
        guard let video = mapVideo(document.data, libraryId: libraryId) else {
            throw APIError.unknown("App Store Connect returned video \(videoId) in a state asc doesn't recognise: \(document.data.attributes?.state ?? "none")")
        }
        return video
    }

    /// `nil` when the video's state or category is one asc doesn't know yet.
    private func mapVideo(_ resource: LibraryAssetResource, libraryId: String) -> LibraryVideo? {
        let attributes = resource.attributes
        guard let state = attributes?.state.flatMap(LibraryAssetState.init(rawValue:)),
              let category = attributes?.category.flatMap(AssetCategory.init(rawValue:))
        else { return nil }
        let frame = attributes?.previewFrameImage
        return LibraryVideo(
            id: resource.id,
            libraryId: libraryId,
            fileName: attributes?.fileName ?? "",
            fileSize: attributes?.fileSize ?? 0,
            category: category,
            state: state,
            referenceName: attributes?.referenceName,
            specId: attributes?.specId,
            width: frame?.image?.width,
            height: frame?.image?.height,
            stateDetails: attributes?.stateDetails?.map { AssetStateDetail(code: $0.code, description: $0.description) },
            createdDate: attributes?.createdDate,
            previewFrameTimeCode: attributes?.previewFrameTimeCode,
            previewFrameState: frame?.state,
            previewFrameUrl: frame?.image?.templateUrl,
            videoUrl: attributes?.videoAsset
        )
    }
}
