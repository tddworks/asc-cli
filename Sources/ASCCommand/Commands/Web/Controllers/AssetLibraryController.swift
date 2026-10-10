import Domain
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes for the App Asset Library: the library, its images, placement groups and placements.
///
/// Query-param names match the CLI flags (`?state=&category=&image-id=`, `?placement-type=&placement-group=`).
/// JSON bodies use the flags in camelCase (`imageId`, `placementType`, `placementGroup`, `placementIds`).
struct AssetLibraryController: Sendable {
    let libraryRepo: any AssetLibraryRepository
    let imageRepo: any LibraryImageRepository
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

        group.delete("/asset-images/:imageId") { _, context -> Response in
            guard let imageId = context.parameters.get("imageId") else { return jsonError("Missing imageId") }
            try await self.imageRepo.deleteImage(imageId: imageId)
            return restResponse("{\"deleted\":true}")
        }

        group.get("/asset-images/:imageId/placements") { _, context -> Response in
            guard let imageId = context.parameters.get("imageId") else { return jsonError("Missing imageId") }
            return try restFormat(try await self.placementRepo.listAssetPlacements(mediaType: .image, assetId: imageId))
        }

        // MARK: Placements

        addPlacementRoutes(to: group, parentSegment: "version-localizations", surface: .appStoreVersionLocalization)

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

    /// Body: `{"imageId", "placementType", "placementGroup"}`.
    static func createPlacement(
        surface: PlacementSurface,
        localizationId: String,
        json: [String: Any],
        repo: any AssetPlacementRepository
    ) async throws -> AssetPlacement {
        guard let assetId = json["imageId"] as? String,
              let placementType = (json["placementType"] as? String).flatMap(AssetPlacementType.init(rawValue:)),
              let placementGroup = json["placementGroup"] as? String
        else { throw BadRequest("Provide imageId, placementType and placementGroup") }
        return try await repo.createPlacement(
            surface: surface, localizationId: localizationId, mediaType: .image, assetId: assetId,
            placementType: placementType, placementGroup: placementGroup
        )
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
