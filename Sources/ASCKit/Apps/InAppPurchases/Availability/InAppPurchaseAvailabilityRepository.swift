import Mockable

@Mockable
public protocol InAppPurchaseAvailabilityRepository: Sendable {
    /// Returns nil when the IAP has no availability resource yet (404 from ASC) — typical
    /// for newly-created IAPs. Frontends treat nil as "no availability set; default UI".
    func getAvailability(iapId: String) async throws -> InAppPurchaseAvailability?
    func createAvailability(iapId: String, isAvailableInNewTerritories: Bool, territoryIds: [String]) async throws -> InAppPurchaseAvailability
}
