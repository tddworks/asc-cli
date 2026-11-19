/// Subscription price schedule — per-territory prices for a subscription.
///
/// Unlike `InAppPurchasePriceSchedule`, subscriptions don't have an explicit base territory:
/// developers price each territory directly, and Apple's auto-equalization fills in the rest.
public struct SubscriptionPriceSchedule: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure
    public let subscriptionId: String
    /// Per-territory prices in this schedule (manual entries, optionally enriched with
    /// equalized entries fetched separately).
    public let territoryPrices: [TerritoryPrice]

    public init(
        id: String,
        subscriptionId: String,
        territoryPrices: [TerritoryPrice] = []
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.territoryPrices = territoryPrices
    }

    public func price(for territoryId: String) -> TerritoryPrice? {
        territoryPrices.first { $0.territory.id == territoryId }
    }
}

extension SubscriptionPriceSchedule: Presentable {
    public static var tableHeaders: [String] { ["ID", "Subscription ID", "Territories"] }
    public var tableRow: [String] { [id, subscriptionId, String(territoryPrices.count)] }
}

extension SubscriptionPriceSchedule: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [
            Affordance(key: "listPricePoints", command: "subscriptions price-points", action: "list", params: ["subscription-id": subscriptionId]),
            Affordance(key: "getSubscription", command: "subscriptions", action: "get", params: ["subscription-id": subscriptionId]),
        ]
    }
}
