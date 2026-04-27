import Mockable

@Mockable
public protocol SubscriptionPriceRepository: Sendable {
    func listPricePoints(subscriptionId: String, territory: String?) async throws -> [SubscriptionPricePoint]
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
