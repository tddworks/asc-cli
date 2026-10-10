import Mockable

@Mockable
public protocol AssetLibraryRepository: Sendable {
    /// The app's one asset library.
    func getAssetLibrary(appId: String) async throws -> AppAssetLibrary
    /// Placement groups from App Store Connect's reference data, one row per placement type and group.
    func listPlacementGroups(placementType: AssetPlacementType?, feature: String?) async throws -> [AssetPlacementGroup]
}
