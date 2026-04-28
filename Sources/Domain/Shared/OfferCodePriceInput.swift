/// Per-territory price input used when creating an offer code.
///
/// `pricePointId` is optional: a `nil` value declares a free offer in that territory
/// (e.g. an IAP "free promo code" or a subscription "free trial code"). For paid
/// offers, `pricePointId` references an `InAppPurchasePricePoint` (IAP) or
/// `SubscriptionPricePoint` (subscription) — the SDK adapter routes it to the right
/// relationship type.
///
/// ASC's `prices` relationship is read-only after the offer code is created, so
/// callers must supply the full per-territory price list at creation time. Mirrors
/// the iOS app's `OfferCodePriceInput` and the inline-create payload Apple expects.
public struct OfferCodePriceInput: Sendable, Equatable {
    public let territory: String
    public let pricePointId: String?

    public init(territory: String, pricePointId: String?) {
        self.territory = territory
        self.pricePointId = pricePointId
    }

    public var isFree: Bool { pricePointId == nil }
}
