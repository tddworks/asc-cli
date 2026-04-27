import Mockable

@Mockable
public protocol SubscriptionPriceRepository: Sendable {
    /// Cursor-paginated. `cursor` is the opaque value from the previous response's
    /// `nextCursor`. `limit` defaults to ASC's page size (~50) when nil.
    func listPricePoints(
        subscriptionId: String,
        territory: String?,
        limit: Int?,
        cursor: String?
    ) async throws -> PaginatedResponse<SubscriptionPricePoint>
    func setPrice(
        subscriptionId: String,
        territory: String,
        pricePointId: String,
        startDate: String?,
        preserveCurrentPrice: Bool?
    ) async throws -> SubscriptionPrice

    /// Returns the per-territory price schedule for a subscription, or `nil` when no prices
    /// have been configured. Composes manual prices + auto-equalized prices.
    func getPriceSchedule(subscriptionId: String) async throws -> SubscriptionPriceSchedule?

    /// Returns all auto-equalized price points for a subscription price point id.
    func listEqualizations(pricePointId: String, limit: Int?) async throws -> [SubscriptionPricePoint]

    /// Sets multiple per-territory prices in one batch (creates a new SubscriptionPrice for
    /// each entry). Mirrors the iOS app's `setPrices(prices:)` API.
    func setPrices(subscriptionId: String, prices: [SubscriptionPriceInput]) async throws -> SubscriptionPriceSchedule
}

/// Input pair for batch `setPrices`.
public struct SubscriptionPriceInput: Sendable, Equatable, Codable {
    public let territory: String
    public let pricePointId: String
    public let startDate: String?
    public let preserveCurrentPrice: Bool?

    public init(territory: String, pricePointId: String, startDate: String? = nil, preserveCurrentPrice: Bool? = nil) {
        self.territory = territory
        self.pricePointId = pricePointId
        self.startDate = startDate
        self.preserveCurrentPrice = preserveCurrentPrice
    }
}
