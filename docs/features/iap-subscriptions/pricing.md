# IAP & Subscription Pricing

IAP and subscriptions both expose price-point browsing and price-setting, but the schemas differ:

| | IAP | Subscription |
|--|-----|--------------|
| Pricing model | Single base territory; Apple auto-equalizes the rest. | Per-territory; Apple still auto-equalizes but each territory carries `proceeds` + `proceedsYear2`. |
| `set` flags | `--base-territory`, `--price-point-id` | `--territory`, `--price-point-id`, optional `--start-date`, `--preserve-current-price` |
| Price-point list | `proceeds` only | `proceeds` + `proceedsYear2` |

## CLI commands

### IAP

| Command | Required flags |
|---------|----------------|
| `asc iap price-points list --iap-id <id> [--territory <code>]` | `--iap-id` |
| `asc iap prices set --iap-id <id> --base-territory <code> --price-point-id <pp>` | all three |

### Subscription

| Command | Required flags |
|---------|----------------|
| `asc subscriptions price-points list --subscription-id <id> [--territory <code>]` | `--subscription-id` |
| `asc subscriptions prices set --subscription-id <id> --territory <code> --price-point-id <pp> [--start-date YYYY-MM-DD] [--preserve-current-price]` | first three |

## Domain models

```swift
public struct SubscriptionPricePoint: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String     // injected by Infrastructure
    public let territory: String?
    public let customerPrice: String?
    public let proceeds: String?
    public let proceedsYear2: String?     // distinguishes subscription pricing
}

public struct SubscriptionPrice: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String
}
```

The matching IAP types are `InAppPurchasePricePoint` and `InAppPurchasePriceSchedule`.

## Affordances

Each price point points at the next legal action:

```json
{
  "affordances" : {
    "listPricePoints" : "asc subscriptions price-points list --subscription-id sub-1",
    "setPrice" : "asc subscriptions prices set --price-point-id pp-tier1 --subscription-id sub-1 --territory USA"
  }
}
```

`setPrice` is suppressed when `territory == nil` — an unanchored price-point can't be applied directly.

## REST endpoints

| Path | Method | Query params |
|------|--------|--------------|
| `/api/v1/subscriptions/:subscriptionId/price-points` | GET | `territory` |

IAP pricing endpoints live alongside the IAP resource (see [IAP REST routes](../iap-subscriptions.md#rest-endpoints)).

## API reference

| Command | SDK call |
|---------|----------|
| `iap price-points list` | `APIEndpoint.v2.inAppPurchases.id(id).pricePoints.get(...)` |
| `iap prices set` | `APIEndpoint.v1.inAppPurchasePriceSchedules.post(InAppPurchasePriceScheduleCreateRequest)` |
| `subscriptions price-points list` | `APIEndpoint.v1.subscriptions.id(id).pricePoints.get(...)` |
| `subscriptions prices set` | `APIEndpoint.v1.subscriptionPrices.post(SubscriptionPriceCreateRequest)` |

## Testing

```bash
swift test --filter 'SubscriptionPricePoint|SDKSubscriptionPriceRepository|SubscriptionPricesSet'
```
