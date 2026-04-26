# Subscription Promotional Offers

CRUD plus per-territory inline price creation. Promotional offers are presented to subscribers from inside the app (StoreKit) — distinct from offer codes (which are externally redeemable) and win-back offers (which target lapsed subscribers).

## CLI commands

| Command | Required flags |
|---------|----------------|
| `asc subscription-promotional-offers list --subscription-id <id>` | `--subscription-id` |
| `asc subscription-promotional-offers create --subscription-id <id> --name <n> --offer-code <c> --duration <d> --mode <m> --periods <n> [--price USA=spp-1 ...]` | first six |
| `asc subscription-promotional-offers delete --offer-id <id>` | `--offer-id` |
| `asc subscription-promotional-offers prices list --offer-id <id>` | `--offer-id` |

`--duration` ∈ `THREE_DAYS`, `ONE_WEEK`, `TWO_WEEKS`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`. `--mode` ∈ `FREE_TRIAL`, `PAY_AS_YOU_GO`, `PAY_UP_FRONT`. `--price` is repeatable and takes `TERRITORY=PRICE_POINT_ID`.

## Inline price creation

`create` builds the SDK request with `${newPromoOfferPrice-N}` 1-based local IDs in the `included` array — matching the shape the ASC web UI sends. Bare IDs would be rejected with `409 ENTITY_ERROR.INCLUDED.INVALID_ID`.

## Domain models

```swift
public struct SubscriptionPromotionalOffer: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String
    public let name: String
    public let offerCode: String
    public let duration: SubscriptionOfferDuration
    public let offerMode: SubscriptionOfferMode
    public let numberOfPeriods: Int
}

public struct SubscriptionPromotionalOfferPrice: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let offerId: String
    public let territory: String?
    public let subscriptionPricePointId: String?
}

public struct PromotionalOfferPriceInput: Sendable, Equatable {
    public let territory: String
    public let pricePointId: String
}
```

`Subscription` advertises `createPromotionalOffer` and `listPromotionalOffers`.

## REST endpoints

| Path | Method |
|------|--------|
| `/api/v1/subscriptions/:subscriptionId/subscription-promotional-offers` | GET |
| `/api/v1/subscription-promotional-offers/:offerId/prices` | GET |

## API reference

| Command | SDK call |
|---------|----------|
| `list` | `APIEndpoint.v1.subscriptions.id(id).promotionalOffers.get()` |
| `create` | `APIEndpoint.v1.subscriptionPromotionalOffers.post(SubscriptionPromotionalOfferCreateRequest)` with inline `included` price entries |
| `delete` | `APIEndpoint.v1.subscriptionPromotionalOffers.id(id).delete` |
| `prices list` | `APIEndpoint.v1.subscriptionPromotionalOffers.id(id).prices.get()` |

## Testing

```bash
swift test --filter 'SubscriptionPromotionalOffer'
```
