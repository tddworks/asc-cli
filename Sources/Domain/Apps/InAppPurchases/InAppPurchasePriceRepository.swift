import Mockable

@Mockable
public protocol InAppPurchasePriceRepository: Sendable {
    func listPricePoints(iapId: String, territory: String?) async throws -> [InAppPurchasePricePoint]
    func setPriceSchedule(iapId: String, baseTerritory: String, pricePointId: String) async throws -> InAppPurchasePriceSchedule
    /// Returns the manual price schedule for an IAP, or `nil` if none has been configured (404).
    func getPriceSchedule(iapId: String) async throws -> InAppPurchasePriceSchedule?

    /// Returns all auto-equalized price points for the given price point id. Apple maintains
    /// a price equivalence across ~175 territories — calling this with the manual base price's
    /// id returns the full territory-by-territory list.
    func listEqualizations(pricePointId: String, limit: Int?) async throws -> [InAppPurchasePricePoint]
}
