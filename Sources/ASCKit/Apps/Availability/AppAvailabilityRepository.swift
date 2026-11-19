import Mockable

@Mockable
public protocol AppAvailabilityRepository: Sendable {
    /// `nil` when the app's availability hasn't been set up yet.
    func getAppAvailability(appId: String) async throws -> AppAvailability?
    /// Sets up the app's availability: available in `territoryIds`.
    func createAppAvailability(
        appId: String,
        isAvailableInNewTerritories: Bool,
        territoryIds: [String]
    ) async throws -> AppAvailability
}
