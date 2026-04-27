import Mockable

@Mockable
public protocol InAppPurchasePriceRepository: Sendable {
    /// Cursor-paginated. `cursor` is the opaque value from the previous response's
    /// `nextCursor`. `limit` defaults to ASC's page size (~50) when nil.
    func listPricePoints(
        iapId: String,
        territory: String?,
        limit: Int?,
        cursor: String?
    ) async throws -> PaginatedResponse<InAppPurchasePricePoint>
    func setPriceSchedule(iapId: String, baseTerritory: String, pricePointId: String) async throws -> InAppPurchasePriceSchedule
    /// Returns the manual price schedule for an IAP, or `nil` if none has been configured (404).
    func getPriceSchedule(iapId: String) async throws -> InAppPurchasePriceSchedule?

    /// Returns all auto-equalized price points for the given price point id. Apple maintains
    /// a price equivalence across ~175 territories — calling this with the manual base price's
    /// id returns the full territory-by-territory list.
    func listEqualizations(pricePointId: String, limit: Int?) async throws -> [InAppPurchasePricePoint]
}
