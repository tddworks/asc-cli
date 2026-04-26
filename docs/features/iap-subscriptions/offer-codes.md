# IAP & Subscription Offer Codes

A 3-level hierarchy: **offer code → custom codes / one-time-use codes → values (CSV)**. Each level has its own CLI command and REST endpoint. Per-territory pricing is read-only after creation.

## CLI commands

### IAP offer codes

| Command | Required flags |
|---------|----------------|
| `asc iap-offer-codes list --iap-id <id>` | `--iap-id` |
| `asc iap-offer-codes create --iap-id <id> --name <n> --eligibility <e>...` | first two; `--eligibility` repeatable, ∈ `NON_SPENDER`, `ACTIVE_SPENDER`, `CHURNED_SPENDER` |
| `asc iap-offer-codes update --offer-code-id <id> --active <bool>` | both |
| `asc iap-offer-codes prices list --offer-code-id <id>` | `--offer-code-id` |
| `asc iap-offer-code-custom-codes list --offer-code-id <id>` | `--offer-code-id` |
| `asc iap-offer-code-custom-codes create --offer-code-id <id> --custom-code <c> --number-of-codes <n> [--expiration-date YYYY-MM-DD]` | first three |
| `asc iap-offer-code-custom-codes update --custom-code-id <id> --active <bool>` | both |
| `asc iap-offer-code-one-time-codes list --offer-code-id <id>` | `--offer-code-id` |
| `asc iap-offer-code-one-time-codes create --offer-code-id <id> --number-of-codes <n> --expiration-date YYYY-MM-DD` | all three |
| `asc iap-offer-code-one-time-codes update --one-time-code-id <id> --active <bool>` | both |
| `asc iap-offer-code-one-time-codes values --one-time-code-id <id>` | `--one-time-code-id` — returns CSV string |

### Subscription offer codes

| Command | Required flags |
|---------|----------------|
| `asc subscription-offer-codes list --subscription-id <id>` | `--subscription-id` |
| `asc subscription-offer-codes create --subscription-id <id> --name <n> --duration <d> --mode <m> --periods <n> --eligibility <e>... --offer-eligibility <oe>` | all |
| `asc subscription-offer-codes update --offer-code-id <id> --active <bool>` | both |
| `asc subscription-offer-codes prices list --offer-code-id <id>` | `--offer-code-id` |
| `asc subscription-offer-code-custom-codes list/create/update` | as IAP equivalents |
| `asc subscription-offer-code-one-time-codes list/create/update` | as IAP equivalents |
| `asc subscription-offer-code-one-time-codes values --one-time-code-id <id>` | `--one-time-code-id` — returns CSV string |

`--eligibility` for subscription offer codes ∈ `NEW`, `LAPSED`, `WIN_BACK`, `PAID_SUBSCRIBER`. `--offer-eligibility` ∈ `STACKABLE`, `INTRODUCTORY`, `SUBSCRIPTION_OFFER`.

## Domain models

```swift
public struct InAppPurchaseOfferCodePrice: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let offerCodeId: String     // injected by Infrastructure
    public let territory: String?
    public let pricePointId: String?
}

public struct SubscriptionOfferCodePrice: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let offerCodeId: String
    public let territory: String?
    public let subscriptionPricePointId: String?
}
```

## Affordances

```json
"affordances" : {
  "listPrices" : "asc iap-offer-codes prices list --offer-code-id oc-1",
  "deactivate" : "asc iap-offer-code-custom-codes update --custom-code-id cc-1 --active false"  // only when isActive
}
```

Custom codes and one-time-use codes both surface a `deactivate` affordance only when `isActive == true`.

## REST endpoints

| Path | Method |
|------|--------|
| `/api/v1/iap-offer-codes/:offerCodeId/prices` | GET |
| `/api/v1/subscription-offer-codes/:offerCodeId/prices` | GET |

The CSV `values` endpoint is intentionally CLI-only — REST clients should use the parent `one-time-codes` resource and follow its affordances.

## API reference

| Command | SDK call |
|---------|----------|
| `*-offer-codes prices list` | `APIEndpoint.v1.inAppPurchaseOfferCodes.id(id).prices.get()` / `subscriptionOfferCodes.id(id).prices.get()` |
| `*-one-time-codes values` | `…OneTimeUseCodes.id(id).values.get` (`Request<String>`) |

## Testing

```bash
swift test --filter 'IAPOfferCodes|SubscriptionOfferCodes|OneTimeCodesValues|OfferCodePrice'
```
