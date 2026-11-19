import Mockable

@Mockable
public protocol PricingRepository: Sendable {
    func hasPricing(appId: String) async throws -> Bool
    /// The prices the app can be sold at in `territory`.
    func listPricePoints(appId: String, territory: String) async throws -> [AppPricePoint]
    /// Sets the app's price: `pricePointId` in `baseTerritory`, equalized worldwide by Apple.
    func setPriceSchedule(appId: String, baseTerritory: String, pricePointId: String) async throws -> AppPriceSchedule
}
