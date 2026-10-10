import Mockable

@Mockable
public protocol AssetPlacementRepository: Sendable {
    /// Placements on one localization, in display order within each group.
    func listPlacements(surface: PlacementSurface, localizationId: String, placementType: AssetPlacementType?, placementGroup: String?) async throws -> [AssetPlacement]
    /// Every placement that shows one asset, across all localizations.
    func listAssetPlacements(mediaType: AssetMediaType, assetId: String) async throws -> [AssetPlacement]
    func createPlacement(surface: PlacementSurface, localizationId: String, mediaType: AssetMediaType, assetId: String, placementType: AssetPlacementType, placementGroup: String) async throws -> AssetPlacement
    func deletePlacement(placementId: String) async throws
    /// Sets the display order of one group on one localization; returns the group in its new order.
    func reorderPlacements(surface: PlacementSurface, localizationId: String, placementGroup: String, placementIds: [String]) async throws -> [AssetPlacement]
}
