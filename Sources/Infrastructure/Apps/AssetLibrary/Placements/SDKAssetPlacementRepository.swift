@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKAssetPlacementRepository: AssetPlacementRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listPlacements(
        surface: PlacementSurface,
        localizationId: String,
        placementType: AssetPlacementType?,
        placementGroup: String?
    ) async throws -> [AssetPlacement] {
        let pages = try await client.requestAllPages(
            listRequest(surface: surface, localizationId: localizationId, placementType: placementType, placementGroup: placementGroup),
            nextCursor: { $0.meta?.paging?.nextCursor }
        )
        // Apple sorts by `placementGroupPosition` but doesn't return it; the response order
        // within each placement type's group is the display order.
        var positions: [String: Int] = [:]
        return pages.flatMap(\.data).compactMap { resource in
            guard let placement = map(resource, surface: surface, localizationId: localizationId) else { return nil }
            let slot = "\(placement.placementType.rawValue)/\(placement.placementGroup)"
            let position = (positions[slot] ?? 0) + 1
            positions[slot] = position
            return placement.at(position: position)
        }
    }

    public func listAssetPlacements(mediaType: AssetMediaType, assetId: String) async throws -> [AssetPlacement] {
        let sdk: (path: String, query: [(String, String?)]?)
        switch mediaType {
        case .image:
            let r = APIEndpoint.v1.appAssetLibraryImages.id(assetId).placements.get(parameters: .init(
                limit: 200,
                include: [.appEventLocalization, .appStoreVersionLocalization, .appCustomProductPageLocalization, .appStoreVersionExperimentTreatmentLocalization]
            ))
            sdk = (r.path, r.query)
        case .video:
            let r = APIEndpoint.v1.appAssetLibraryVideos.id(assetId).placements.get(parameters: .init(
                limit: 200,
                include: [.appEventLocalization, .appStoreVersionLocalization, .appCustomProductPageLocalization, .appStoreVersionExperimentTreatmentLocalization]
            ))
            sdk = (r.path, r.query)
        }
        let pages = try await client.requestAllPages(
            Request<AssetPlacementsDocument>(path: sdk.path, method: "GET", query: sdk.query, id: "asset_placements_getToManyRelated"),
            nextCursor: { $0.meta?.paging?.nextCursor }
        )
        return pages.flatMap(\.data).compactMap { map($0, mediaType: mediaType, assetId: assetId) }
    }

    public func createPlacement(
        surface: PlacementSurface,
        localizationId: String,
        mediaType: AssetMediaType,
        assetId: String,
        placementType: AssetPlacementType,
        placementGroup: String
    ) async throws -> AssetPlacement {
        let body = PlacementCreateBody(data: .init(
            attributes: .init(placementType: placementType.rawValue, placementGroup: placementGroup),
            relationships: [
                mediaType.relationshipKey: ToOneBody(data: .init(type: mediaType.resourceType, id: assetId)),
                surface.relationshipKey: ToOneBody(data: .init(type: surface.resourceType, id: localizationId)),
            ]
        ))
        let document = try await client.request(Request<AssetPlacementDocument>(
            path: APIEndpoint.v1.appAssetLibraryPlacements.path, method: "POST", body: body,
            id: "appAssetLibraryPlacements_createInstance"
        ))
        guard let placement = map(document.data, surface: surface, localizationId: localizationId, mediaType: mediaType, assetId: assetId) else {
            throw APIError.unknown("App Store Connect returned placement \(document.data.id) in a state asc doesn't recognise")
        }
        return placement
    }

    public func deletePlacement(placementId: String) async throws {
        try await client.request(APIEndpoint.v1.appAssetLibraryPlacements.id(placementId).delete)
    }

    public func reorderPlacements(
        surface: PlacementSurface,
        localizationId: String,
        placementGroup: String,
        placementIds: [String]
    ) async throws -> [AssetPlacement] {
        let body = PlacementOrderingBody(data: .init(
            attributes: .init(placementGroup: placementGroup),
            relationships: .init(
                surfaceKey: surface.relationshipKey,
                surface: ToOneBody(data: .init(type: surface.resourceType, id: localizationId)),
                orderedPlacements: ToManyBody(data: placementIds.map { .init(type: "appAssetLibraryPlacements", id: $0) })
            )
        ))
        _ = try await client.request(Request<PlacementOrderingDocument>(
            path: APIEndpoint.v1.appAssetLibraryPlacementOrderingRequests.path, method: "POST", body: body,
            id: "appAssetLibraryPlacementOrderingRequests_createInstance"
        ))
        return try await listPlacements(surface: surface, localizationId: localizationId, placementType: nil, placementGroup: placementGroup)
    }

    // MARK: - Requests

    private func listRequest(
        surface: PlacementSurface,
        localizationId: String,
        placementType: AssetPlacementType?,
        placementGroup: String?
    ) -> Request<AssetPlacementsDocument> {
        let groups = placementGroup.map { [$0] }
        let sdk: (path: String, query: [(String, String?)]?)
        switch surface {
        case .appStoreVersionLocalization:
            let r = APIEndpoint.v1.appStoreVersionLocalizations.id(localizationId).placements.get(parameters: .init(
                filterPlacementType: placementType.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
                filterPlacementGroup: groups, sort: [.placementGroupPosition], limit: 200, include: [.image, .video]
            ))
            sdk = (r.path, r.query)
        case .experimentTreatmentLocalization:
            let r = APIEndpoint.v1.appStoreVersionExperimentTreatmentLocalizations.id(localizationId).placements.get(parameters: .init(
                filterPlacementType: placementType.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
                filterPlacementGroup: groups, sort: [.placementGroupPosition], limit: 200, include: [.image, .video]
            ))
            sdk = (r.path, r.query)
        case .customProductPageLocalization:
            let r = APIEndpoint.v1.appCustomProductPageLocalizations.id(localizationId).placements.get(parameters: .init(
                filterPlacementType: placementType.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
                filterPlacementGroup: groups, sort: [.placementGroupPosition], limit: 200, include: [.image, .video]
            ))
            sdk = (r.path, r.query)
        case .eventLocalization:
            let r = APIEndpoint.v1.appEventLocalizations.id(localizationId).placements.get(parameters: .init(
                filterPlacementType: placementType.flatMap { .init(rawValue: $0.rawValue) }.map { [$0] },
                filterPlacementGroup: groups, sort: [.placementGroupPosition], limit: 200, include: [.image, .video]
            ))
            sdk = (r.path, r.query)
        }
        return Request(path: sdk.path, method: "GET", query: sdk.query, id: "localization_placements_getToManyRelated")
    }

    // MARK: - Mapping

    /// Fills what the request already knows (surface, localization, asset) and reads the
    /// rest from the response's relationship linkages. `nil` when a type or state is one asc
    /// doesn't know yet, or the response doesn't say where the placement sits.
    private func map(
        _ resource: AssetPlacementResource,
        surface knownSurface: PlacementSurface? = nil,
        localizationId knownLocalizationId: String? = nil,
        mediaType knownMediaType: AssetMediaType? = nil,
        assetId knownAssetId: String? = nil
    ) -> AssetPlacement? {
        let attributes = resource.attributes
        let links = resource.relationships
        guard let placementType = attributes?.placementType.flatMap(AssetPlacementType.init(rawValue:)),
              let state = attributes?.state.flatMap(PlacementState.init(rawValue:)),
              let placementGroup = attributes?.placementGroup
        else { return nil }

        let linkedSurface: (PlacementSurface, String)? = PlacementSurface.allCases.lazy.compactMap { surface in
            Self.linkage(surface, in: links).map { (surface, $0) }
        }.first
        guard let surface = knownSurface ?? linkedSurface?.0,
              let localizationId = knownLocalizationId ?? linkedSurface?.1
        else { return nil }

        let mediaType = knownMediaType
            ?? attributes?.mediaType.flatMap(AssetMediaType.init(rawValue:))
            ?? (links?.video?.data != nil ? .video : .image)
        guard let assetId = knownAssetId ?? (mediaType == .image ? links?.image : links?.video)?.data?.id else { return nil }

        return AssetPlacement(
            id: resource.id, surface: surface, localizationId: localizationId, mediaType: mediaType, assetId: assetId,
            placementType: placementType, placementGroup: placementGroup, state: state,
            stateDetails: attributes?.stateDetails?.map { AssetStateDetail(code: $0.code, description: $0.description) }
        )
    }

    private static func linkage(_ surface: PlacementSurface, in links: AssetPlacementResource.Relationships?) -> String? {
        switch surface {
        case .appStoreVersionLocalization: links?.appStoreVersionLocalization?.data?.id
        case .experimentTreatmentLocalization: links?.appStoreVersionExperimentTreatmentLocalization?.data?.id
        case .customProductPageLocalization: links?.appCustomProductPageLocalization?.data?.id
        case .eventLocalization: links?.appEventLocalization?.data?.id
        }
    }
}

private extension AssetPlacement {
    func at(position: Int) -> AssetPlacement {
        AssetPlacement(
            id: id, surface: surface, localizationId: localizationId, mediaType: mediaType, assetId: assetId,
            placementType: placementType, placementGroup: placementGroup, position: position,
            state: state, stateDetails: stateDetails
        )
    }
}
