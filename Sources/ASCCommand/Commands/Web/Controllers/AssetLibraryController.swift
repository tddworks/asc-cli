import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes for the App Asset Library: the library, its images, placement groups and placements.
///
/// Query-param names match the CLI flags (`?state=&category=&image-id=`, `?placement-type=&placement-group=`).
/// JSON bodies use the flags in camelCase (`imageId`/`videoId`, `placementType`, `placementGroup`,
/// `placementIds`, `libraryId`, `referenceName`, `archived`).
struct AssetLibraryController: Sendable {
    let libraryRepo: any AssetLibraryRepository
    let imageRepo: any LibraryImageRepository
    let videoRepo: any LibraryVideoRepository
    let placementRepo: any AssetPlacementRepository

    struct BadRequest: Error, Equatable {
        let message: String
        init(_ message: String) { self.message = message }
    }

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        // MARK: Library and reference data

        group.get("/apps/:appId/asset-library") { _, context -> Response in
            guard let appId = context.parameters.get("appId") else { return jsonError("Missing appId") }
            return try restFormat(try await self.libraryRepo.getAssetLibrary(appId: appId))
        }

        group.get("/asset-placement-groups") { request, _ -> Response in
            let params = request.uri.queryParameters
            var placementType: AssetPlacementType?
            if let raw = params.get("placement-type") {
                guard let parsed = AssetPlacementType(rawValue: raw) else { return jsonError("Unknown placement-type '\(raw)'") }
                placementType = parsed
            }
            let groups = try await self.libraryRepo.listPlacementGroups(placementType: placementType, feature: params.get("feature"))
            return try restFormat(groups)
        }

        // MARK: Images

        group.get("/asset-library/:libraryId/images") { request, context -> Response in
            guard let libraryId = context.parameters.get("libraryId") else { return jsonError("Missing libraryId") }
            let params = request.uri.queryParameters
            var state: LibraryAssetState?
            if let raw = params.get("state") {
                guard let parsed = LibraryAssetState(rawValue: raw) else { return jsonError("Unknown state '\(raw)'") }
                state = parsed
            }
            var category: AssetCategory?
            if let raw = params.get("category") {
                guard let parsed = AssetCategory(rawValue: raw) else { return jsonError("Unknown category '\(raw)'") }
                category = parsed
            }
            let images = try await self.imageRepo.listImages(
                libraryId: libraryId, imageId: params.get("image-id"), state: state, category: category
            )
            return try restFormat(images)
        }

        group.post("/asset-library/:libraryId/images") { request, context -> Response in
            guard let libraryId = context.parameters.get("libraryId") else { return jsonError("Missing libraryId") }
            let params = request.uri.queryParameters
            let category = params.get("category").flatMap(AssetCategory.init(rawValue:)) ?? .appScreenshotsAndPreviews
            let referenceName = params.get("reference-name")
            return await uploadReviewBodyResponse(
                label: "asset-images",
                request: request,
                fileExtension: extensionFor(contentType: request.headers[.contentType], fallback: "png"),
                upload: {
                    try await self.imageRepo.uploadImage(libraryId: libraryId, fileURL: $0, category: category, referenceName: referenceName)
                }
            )
        }

        group.patch("/asset-images/:imageId") { request, context -> Response in
            guard let imageId = context.parameters.get("imageId") else { return jsonError("Missing imageId") }
            let json = try await Self.jsonBody(request)
            do {
                return try restFormat(try await Self.updateImage(imageId: imageId, json: json, repo: self.imageRepo))
            } catch let error as BadRequest {
                return jsonError(error.message)
            }
        }

        group.delete("/asset-images/:imageId") { _, context -> Response in
            guard let imageId = context.parameters.get("imageId") else { return jsonError("Missing imageId") }
            try await self.imageRepo.deleteImage(imageId: imageId)
            return restResponse("{\"deleted\":true}")
        }

        group.get("/asset-images/:imageId/placements") { _, context -> Response in
            guard let imageId = context.parameters.get("imageId") else { return jsonError("Missing imageId") }
            return try restFormat(try await self.placementRepo.listAssetPlacements(mediaType: .image, assetId: imageId))
        }

        // MARK: Videos

        group.get("/asset-library/:libraryId/videos") { request, context -> Response in
            guard let libraryId = context.parameters.get("libraryId") else { return jsonError("Missing libraryId") }
            let params = request.uri.queryParameters
            var state: LibraryAssetState?
            if let raw = params.get("state") {
                guard let parsed = LibraryAssetState(rawValue: raw) else { return jsonError("Unknown state '\(raw)'") }
                state = parsed
            }
            var category: AssetCategory?
            if let raw = params.get("category") {
                guard let parsed = AssetCategory(rawValue: raw) else { return jsonError("Unknown category '\(raw)'") }
                category = parsed
            }
            let videos = try await self.videoRepo.listVideos(
                libraryId: libraryId, videoId: params.get("video-id"), state: state, category: category
            )
            return try restFormat(videos)
        }

        group.post("/asset-library/:libraryId/videos") { request, context -> Response in
            guard let libraryId = context.parameters.get("libraryId") else { return jsonError("Missing libraryId") }
            let params = request.uri.queryParameters
            let category = params.get("category").flatMap(AssetCategory.init(rawValue:)) ?? .appScreenshotsAndPreviews
            let referenceName = params.get("reference-name")
            let previewFrameTimeCode = params.get("preview-frame-time-code")
            return await uploadReviewBodyResponse(
                label: "asset-videos",
                request: request,
                fileExtension: extensionFor(contentType: request.headers[.contentType], fallback: "mp4"),
                maxBytes: Self.maxVideoBytes,
                upload: {
                    try await self.videoRepo.uploadVideo(
                        libraryId: libraryId, fileURL: $0, category: category,
                        referenceName: referenceName, previewFrameTimeCode: previewFrameTimeCode
                    )
                }
            )
        }

        group.patch("/asset-videos/:videoId") { request, context -> Response in
            guard let videoId = context.parameters.get("videoId") else { return jsonError("Missing videoId") }
            let json = try await Self.jsonBody(request)
            do {
                return try restFormat(try await Self.updateVideo(videoId: videoId, json: json, repo: self.videoRepo))
            } catch let error as BadRequest {
                return jsonError(error.message)
            }
        }

        group.delete("/asset-videos/:videoId") { _, context -> Response in
            guard let videoId = context.parameters.get("videoId") else { return jsonError("Missing videoId") }
            try await self.videoRepo.deleteVideo(videoId: videoId)
            return restResponse("{\"deleted\":true}")
        }

        group.get("/asset-videos/:videoId/placements") { _, context -> Response in
            guard let videoId = context.parameters.get("videoId") else { return jsonError("Missing videoId") }
            return try restFormat(try await self.placementRepo.listAssetPlacements(mediaType: .video, assetId: videoId))
        }

        // MARK: Placements

        addPlacementRoutes(to: group, parentSegment: "version-localizations", surface: .appStoreVersionLocalization)
        addPlacementRoutes(to: group, parentSegment: "experiment-treatment-localizations", surface: .experimentTreatmentLocalization)

        group.delete("/asset-placements/:placementId") { _, context -> Response in
            guard let placementId = context.parameters.get("placementId") else { return jsonError("Missing placementId") }
            try await self.placementRepo.deletePlacement(placementId: placementId)
            return restResponse("{\"deleted\":true}")
        }
    }

    /// List / create / reorder placements under one localization surface.
    private func addPlacementRoutes(
        to group: RouterGroup<BasicWebSocketRequestContext>,
        parentSegment: String,
        surface: PlacementSurface
    ) {
        group.get("/\(parentSegment)/:localizationId/placements") { request, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            let params = request.uri.queryParameters
            var placementType: AssetPlacementType?
            if let raw = params.get("placement-type") {
                guard let parsed = AssetPlacementType(rawValue: raw) else { return jsonError("Unknown placement-type '\(raw)'") }
                placementType = parsed
            }
            let placements = try await self.placementRepo.listPlacements(
                surface: surface, localizationId: localizationId,
                placementType: placementType, placementGroup: params.get("placement-group")
            )
            return try restFormat(placements)
        }

        group.post("/\(parentSegment)/:localizationId/placements") { request, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            let json = try await Self.jsonBody(request)
            do {
                let placement = try await Self.createPlacement(surface: surface, localizationId: localizationId, json: json, repo: self.placementRepo)
                return try restFormat(placement)
            } catch let error as BadRequest {
                return jsonError(error.message)
            }
        }

        group.post("/\(parentSegment)/:localizationId/placements/reorder") { request, context -> Response in
            guard let localizationId = context.parameters.get("localizationId") else { return jsonError("Missing localizationId") }
            let json = try await Self.jsonBody(request)
            do {
                let placements = try await Self.reorderPlacements(surface: surface, localizationId: localizationId, json: json, repo: self.placementRepo)
                return try restFormat(placements)
            } catch let error as BadRequest {
                return jsonError(error.message)
            }
        }
    }

    /// Apple accepts preview files up to 500 MB.
    static let maxVideoBytes = 500 * 1024 * 1024

    /// Body: `{"imageId" | "videoId", "placementType", "placementGroup"}`.
    static func createPlacement(
        surface: PlacementSurface,
        localizationId: String,
        json: [String: Any],
        repo: any AssetPlacementRepository
    ) async throws -> AssetPlacement {
        let asset: (AssetMediaType, String)? = (json["videoId"] as? String).map { (.video, $0) }
            ?? (json["imageId"] as? String).map { (.image, $0) }
        guard let (mediaType, assetId) = asset,
              let placementType = (json["placementType"] as? String).flatMap(AssetPlacementType.init(rawValue:)),
              let placementGroup = json["placementGroup"] as? String
        else { throw BadRequest("Provide imageId or videoId, placementType and placementGroup") }
        return try await repo.createPlacement(
            surface: surface, localizationId: localizationId, mediaType: mediaType, assetId: assetId,
            placementType: placementType, placementGroup: placementGroup
        )
    }

    /// Body: `{"libraryId", "referenceName"?, "archived"?}` — the `asset-images update` flags.
    static func updateImage(imageId: String, json: [String: Any], repo: any LibraryImageRepository) async throws -> LibraryImage {
        let (referenceName, archived) = try updateFields(json)
        return try await repo.updateImage(
            libraryId: json["libraryId"] as? String ?? "", imageId: imageId, referenceName: referenceName, isArchived: archived
        )
    }

    /// Body: `{"libraryId", "referenceName"?, "archived"?}` — the `asset-videos update` flags.
    static func updateVideo(videoId: String, json: [String: Any], repo: any LibraryVideoRepository) async throws -> LibraryVideo {
        let (referenceName, archived) = try updateFields(json)
        return try await repo.updateVideo(
            libraryId: json["libraryId"] as? String ?? "", videoId: videoId, referenceName: referenceName, isArchived: archived
        )
    }

    private static func updateFields(_ json: [String: Any]) throws -> (referenceName: String?, archived: Bool?) {
        let referenceName = json["referenceName"] as? String
        let archived = json["archived"] as? Bool
        guard referenceName != nil || archived != nil else { throw BadRequest("Provide referenceName or archived") }
        return (referenceName, archived)
    }

    /// Body: `{"placementGroup", "placementIds": [...]}` in display order.
    static func reorderPlacements(
        surface: PlacementSurface,
        localizationId: String,
        json: [String: Any],
        repo: any AssetPlacementRepository
    ) async throws -> [AssetPlacement] {
        guard let placementGroup = json["placementGroup"] as? String,
              let placementIds = json["placementIds"] as? [String], !placementIds.isEmpty
        else { throw BadRequest("Provide placementGroup and placementIds") }
        return try await repo.reorderPlacements(
            surface: surface, localizationId: localizationId, placementGroup: placementGroup, placementIds: placementIds
        )
    }

    private static func jsonBody(_ request: Request) async throws -> [String: Any] {
        let body = try await request.body.collect(upTo: 64 * 1024)
        return (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
    }
}
