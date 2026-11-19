import Mockable

@Mockable
public protocol SubscriptionAvailabilities: Sendable {
    /// Returns nil when the subscription has no availability resource yet (404 from ASC).
    /// Mirrors `InAppPurchaseAvailabilities.getAvailability` 404 tolerance.
    func getAvailability(subscriptionId: String) async throws -> SubscriptionAvailability?
    func createAvailability(subscriptionId: String, isAvailableInNewTerritories: Bool, territoryIds: [String]) async throws -> SubscriptionAvailability
}
