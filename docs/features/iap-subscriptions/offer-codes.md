# IAP & Subscription Offer Codes

A 3-level hierarchy: **offer code → custom codes / one-time-use codes → values (CSV)**. Each level has its own CLI command and REST endpoint. Per-territory pricing is read-only after creation.

## CLI commands

### IAP offer codes

| Command | Required flags |
|---------|----------------|
| `asc iap-offer-codes list --iap-id <id>` | `--iap-id` |
| `asc iap-offer-codes create --iap-id <id> --name <n> --eligibility <e>... [--price <T>=<pp-id>...] [--free-territory <T>...]` | first two; `--eligibility` repeatable, ∈ `NON_SPENDER`, `ACTIVE_SPENDER`, `CHURNED_SPENDER`. `--price` is `<territory>=<price-point-id>` (repeatable). `--free-territory` is repeatable. **Per-territory pricing is read-only after creation — supply every territory at create time.** |
| `asc iap-offer-codes update --offer-code-id <id> --active <bool>` | both |
| `asc iap-offer-codes prices list --offer-code-id <id>` | `--offer-code-id` |
| `asc iap-offer-code-custom-codes list --offer-code-id <id>` | `--offer-code-id` |
| `asc iap-offer-code-custom-codes create --offer-code-id <id> --custom-code <c> --number-of-codes <n> [--expiration-date YYYY-MM-DD]` | first three |
| `asc iap-offer-code-custom-codes update --custom-code-id <id> --active <bool>` | both |
| `asc iap-offer-code-one-time-codes list --offer-code-id <id>` | `--offer-code-id` |
| `asc iap-offer-code-one-time-codes create --offer-code-id <id> --number-of-codes <n> --expiration-date YYYY-MM-DD [--environment production\|sandbox]` | first three; `--environment` defaults to `production` |
| `asc iap-offer-code-one-time-codes update --one-time-code-id <id> --active <bool>` | both |
| `asc iap-offer-code-one-time-codes values --one-time-code-id <id>` | `--one-time-code-id` — returns CSV string |

### Subscription offer codes

| Command | Required flags |
|---------|----------------|
| `asc subscription-offer-codes list --subscription-id <id>` | `--subscription-id` |
| `asc subscription-offer-codes create --subscription-id <id> --name <n> --duration <d> --mode <m> --periods <n> --eligibility <e>... --offer-eligibility <oe> [--auto-renew <bool>] [--price <T>=<pp-id>...] [--free-territory <T>...]` | all required as before. `--auto-renew` defaults to `true`; pass `false` for non-renewing offers (ASC accepts only `--mode FREE_TRIAL` in that case). `--price`/`--free-territory` same shape as IAP. |
| `asc subscription-offer-codes update --offer-code-id <id> --active <bool>` | both |
| `asc subscription-offer-codes prices list --offer-code-id <id>` | `--offer-code-id` |
| `asc subscription-offer-code-custom-codes list/create/update` | as IAP equivalents |
| `asc subscription-offer-code-one-time-codes list/update` | as IAP equivalents |
| `asc subscription-offer-code-one-time-codes create --offer-code-id <id> --number-of-codes <n> --expiration-date YYYY-MM-DD [--environment production\|sandbox]` | first three; `--environment` defaults to `production` |
| `asc subscription-offer-code-one-time-codes values --one-time-code-id <id>` | `--one-time-code-id` — returns CSV string |

`--eligibility` for subscription offer codes ∈ `NEW`, `LAPSED`, `WIN_BACK`, `PAID_SUBSCRIBER`. `--offer-eligibility` ∈ `STACKABLE`, `INTRODUCTORY`, `SUBSCRIPTION_OFFER`.

### Environment (production / sandbox)

Apple separates one-time-use redemption batches into two environments:

- **`production`** — codes redeem against live App Store accounts. Per-quarter ceiling ≈ 150,000 codes.
- **`sandbox`** — codes redeem against sandbox tester accounts. Per-quarter ceiling ≈ 10,000 codes.

`asc iap-offer-codes list` and `asc subscription-offer-codes list` now report `productionCodeCount` and `sandboxCodeCount` so you can track usage against each ceiling separately. List output for one-time-codes includes the `environment` per batch so you can filter sandbox vs production batches:

```bash
asc iap-offer-code-one-time-codes list --offer-code-id oc-1 \
  | jq '.data[] | select(.environment == "SANDBOX")'
```

## Domain models

```swift
public struct InAppPurchaseOfferCode: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let iapId: String              // injected by Infrastructure
    public let name: String
    public let customerEligibilities: [IAPCustomerEligibility]
    public let isActive: Bool
    public let totalNumberOfCodes: Int?
    public let productionCodeCount: Int?  // Apple-reported count of production codes used
    public let sandboxCodeCount: Int?     // Apple-reported count of sandbox codes used
}

public struct SubscriptionOfferCode: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String     // injected by Infrastructure
    public let name: String
    public let customerEligibilities: [SubscriptionCustomerEligibility]
    public let offerEligibility: SubscriptionOfferEligibility
    public let duration: SubscriptionOfferDuration
    public let offerMode: SubscriptionOfferMode
    public let numberOfPeriods: Int
    public let totalNumberOfCodes: Int?
    public let productionCodeCount: Int?
    public let sandboxCodeCount: Int?
    public let isActive: Bool
}

public struct InAppPurchaseOfferCodeOneTimeUseCode: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let offerCodeId: String        // injected by Infrastructure
    public let numberOfCodes: Int
    public let createdDate: String?
    public let expirationDate: String?
    public let isActive: Bool
    public let environment: OfferCodeEnvironment?  // PRODUCTION | SANDBOX
}

public struct SubscriptionOfferCodeOneTimeUseCode: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let offerCodeId: String
    public let numberOfCodes: Int
    public let createdDate: String?
    public let expirationDate: String?
    public let isActive: Bool
    public let environment: OfferCodeEnvironment?
}

public enum OfferCodeEnvironment: String, Sendable, Codable, Equatable {
    case production = "PRODUCTION"
    case sandbox = "SANDBOX"
}

public struct InAppPurchaseOfferCodePrice: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let offerCodeId: String
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
  "deactivate" : "asc iap-offer-code-custom-codes update --active false --custom-code-id cc-1"
}
```

Custom codes and one-time-use codes both surface a `deactivate` affordance only when `isActive == true`. (Param order is alphabetical because both models render via `structuredAffordances`.)

## REST endpoints

| Path | Method | Description |
|------|--------|-------------|
| `/api/v1/iap/:iapId/offer-codes` | GET | List IAP offer codes (returns `productionCodeCount`/`sandboxCodeCount` per item) |
| `/api/v1/iap/:iapId/offer-codes` | POST | Create an IAP offer code — body: `{name, customerEligibilities[], prices: [{territory, pricePointId?}]}`. Omit `pricePointId` (or set to `null`) for a free territory. **Required at create time — read-only after.** |
| `/api/v1/subscriptions/:subscriptionId/offer-codes` | GET | List subscription offer codes (same per-environment counts) |
| `/api/v1/subscriptions/:subscriptionId/offer-codes` | POST | Create a subscription offer code — body: `{name, duration, mode, periods, customerEligibilities[], offerEligibility, isAutoRenewEnabled?, prices: [{territory, pricePointId?}]}`. `isAutoRenewEnabled` defaults to `true` (also accepts `autoRenew`). Same `prices` shape and read-only-after rule as IAP. |
| `/api/v1/iap-offer-codes/:offerCodeId/prices` | GET | Per-territory prices for an IAP offer code |
| `/api/v1/subscription-offer-codes/:offerCodeId/prices` | GET | Per-territory prices for a subscription offer code |
| `/api/v1/iap-offer-codes/:offerCodeId/one-time-codes` | GET | List one-time-use code batches |
| `/api/v1/iap-offer-codes/:offerCodeId/one-time-codes` | POST | Create a batch — body: `{numberOfCodes, expirationDate, environment?}` |
| `/api/v1/iap-offer-code-one-time-codes/:oneTimeCodeId` | PATCH | Update batch — body: `{isActive: false}` to deactivate |
| `/api/v1/subscription-offer-codes/:offerCodeId/one-time-codes` | GET | Same shape as IAP |
| `/api/v1/subscription-offer-codes/:offerCodeId/one-time-codes` | POST | Same body shape as IAP |
| `/api/v1/subscription-offer-code-one-time-codes/:oneTimeCodeId` | PATCH | Same body as IAP |

`environment` in the POST body is optional — defaults to `production`. Accepts `"production"`, `"sandbox"`, `"PRODUCTION"`, or `"SANDBOX"`.

```bash
# Generate sandbox redemption codes for an existing offer code
curl -X POST http://localhost:8080/api/v1/iap-offer-codes/oc-1/one-time-codes \
  -H "Content-Type: application/json" \
  -d '{"numberOfCodes": 100, "expirationDate": "2026-12-31", "environment": "sandbox"}'

# Create a paid IAP offer code with mixed paid + free territories
curl -X POST http://localhost:8080/api/v1/iap/iap-1/offer-codes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "LAUNCH_PROMO",
    "customerEligibilities": ["NON_SPENDER", "CHURNED_SPENDER"],
    "prices": [
      {"territory": "USA", "pricePointId": "pp-usa"},
      {"territory": "JPN", "pricePointId": "pp-jpn"},
      {"territory": "BRA"}
    ]
  }'

# Create a non-renewing subscription offer code (autoRenew false ⇒ free trial only)
curl -X POST http://localhost:8080/api/v1/subscriptions/sub-1/offer-codes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "WELCOME_TRIAL",
    "duration": "ONE_MONTH", "mode": "FREE_TRIAL", "periods": 1,
    "customerEligibilities": ["NEW"], "offerEligibility": "STACKABLE",
    "isAutoRenewEnabled": false,
    "prices": [{"territory": "USA"}]
  }'
```

The CSV `values` endpoint is intentionally CLI-only — REST clients should list the parent `one-time-codes` resource and follow its affordances to deactivate or create new batches.

## API reference

| Command | SDK call |
|---------|----------|
| `*-offer-codes prices list` | `APIEndpoint.v1.inAppPurchaseOfferCodes.id(id).prices.get()` / `subscriptionOfferCodes.id(id).prices.get()` |
| `*-one-time-codes create` | `APIEndpoint.v1.{inAppPurchaseOfferCodeOneTimeUseCodes,subscriptionOfferCodeOneTimeUseCodes}.post(body)` with `Attributes(numberOfCodes:expirationDate:environment:)` |
| `*-one-time-codes values` | `…OneTimeUseCodes.id(id).values.get` (`Request<String>`) |

## Testing

```bash
swift test --filter 'IAPOfferCodes|SubscriptionOfferCodes|OneTimeCodesValues|OfferCodePrice|OfferCodeEnvironment'
```
