# App, IAP & Subscription Availability

Manage territory availability for apps, in-app purchases, and auto-renewable subscriptions.

## CLI Usage

### App Availability (Per-Territory Status)

The richest availability view — shows every territory with `isAvailable`, blocking reasons (`contentStatuses`), `releaseDate`, and `isPreOrderEnabled`.

```bash
asc app-availability get --app-id <id> [--pretty]
```

Example output:
```json
{
  "data": [{
    "id": "avail-1",
    "appId": "app-42",
    "isAvailableInNewTerritories": true,
    "territories": [
      { "id": "ta-1", "territoryId": "USA", "isAvailable": true, "isPreOrderEnabled": false, "contentStatuses": ["AVAILABLE"] },
      { "id": "ta-2", "territoryId": "CHN", "isAvailable": false, "isPreOrderEnabled": false, "contentStatuses": ["CANNOT_SELL_RESTRICTED_RATING"] }
    ]
  }]
}
```

**ContentStatus values** include: `AVAILABLE`, `MISSING_RATING`, `CANNOT_SELL_RESTRICTED_RATING`, `CANNOT_SELL_GAMBLING`, `BRAZIL_REQUIRED_TAX_ID`, `ICP_NUMBER_MISSING`, and 30+ more reasons explaining why a territory is blocked.

### Discover Territories

```bash
# List all ~175 territories with currency codes
asc territories list
asc territories list --output table
```

| Flag | Required | Description |
|------|----------|-------------|
| `--output` | No | Output format: json (default), table, markdown |
| `--pretty` | No | Pretty-print JSON output |

Example output (table):

```
ID    Currency
USA   USD
CHN   CNY
JPN   JPY
GBR   GBP
DEU   EUR
...
```

### IAP Availability

#### Get IAP Availability

```bash
asc iap-availability get --iap-id <id>
```

Returns territory IDs **with currency codes** so you know which territories the IAP is available in.

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | Yes | IAP ID to get availability for |

#### Create IAP Availability

```bash
asc iap-availability create --iap-id <id> \
  --available-in-new-territories \
  --territory USA --territory CHN --territory JPN
```

| Flag | Required | Description |
|------|----------|-------------|
| `--iap-id` | Yes | IAP ID to set availability for |
| `--available-in-new-territories` | No | Auto-include new territories Apple adds |
| `--territory` | No | Territory ID (repeatable, e.g. USA, CHN, JPN) |

### Subscription Availability

#### Get Subscription Availability

```bash
asc subscription-availability get --subscription-id <id>
```

#### Create Subscription Availability

```bash
asc subscription-availability create --subscription-id <id> \
  --available-in-new-territories \
  --territory USA --territory GBR
```

| Flag | Required | Description |
|------|----------|-------------|
| `--subscription-id` | Yes | Subscription ID to set availability for |
| `--available-in-new-territories` | No | Auto-include new territories Apple adds |
| `--territory` | No | Territory ID (repeatable) |

### Example Output (JSON)

```json
{
  "data": [
    {
      "id": "avail-1",
      "iapId": "iap-42",
      "isAvailableInNewTerritories": true,
      "territories": [
        { "id": "USA", "currency": "USD" },
        { "id": "CHN", "currency": "CNY" }
      ],
      "affordances": {
        "getAvailability": "asc iap-availability get --iap-id iap-42",
        "createAvailability": "asc iap-availability create --iap-id iap-42 ...",
        "listTerritories": "asc territories list"
      }
    }
  ]
}
```

## Typical Workflow

```bash
# 1. Discover what territories exist
asc territories list --output table

# 2. List IAPs for an app
asc iap list --app-id $APP_ID

# 3. Check current availability for a specific IAP
asc iap-availability get --iap-id $IAP_ID
# → Shows which territories + currency codes are enabled

# 4. Set availability to specific territories
asc iap-availability create --iap-id $IAP_ID \
  --available-in-new-territories \
  --territory USA --territory GBR --territory DEU

# Same flow for subscriptions:
asc subscriptions list --group-id $GROUP_ID
asc subscription-availability get --subscription-id $SUB_ID
asc subscription-availability create --subscription-id $SUB_ID \
  --territory USA --territory JPN
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ ASCCommand                                                   │
│  TerritoriesCommand (list)                                  │
│  IAPAvailabilityCommand (get, create)                       │
│  SubscriptionAvailabilityCommand (get, create)              │
├─────────────────────────────────────────────────────────────┤
│ Infrastructure                                               │
│  SDKTerritoryRepository                                     │
│  SDKInAppPurchaseAvailabilityRepository                     │
│  SDKSubscriptionAvailabilityRepository                      │
├─────────────────────────────────────────────────────────────┤
│ Domain                                                       │
│  Territory (id, currency)                                   │
│  InAppPurchaseAvailability + territories: [Territory]        │
│  SubscriptionAvailability + territories: [Territory]         │
│  TerritoryRepository (@Mockable)                            │
│  InAppPurchaseAvailabilityRepository (@Mockable)            │
│  SubscriptionAvailabilityRepository (@Mockable)             │
└─────────────────────────────────────────────────────────────┘
```

## Domain Models

### Territory

```swift
public struct Territory: Sendable, Equatable, Identifiable, Codable {
    public let id: String        // e.g. "USA", "CHN", "JPN"
    public let currency: String? // e.g. "USD", "CNY", "JPY"
}
```

### InAppPurchaseAvailability

```swift
public struct InAppPurchaseAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let iapId: String                        // parent ID, injected by Infrastructure
    public let isAvailableInNewTerritories: Bool
    public let territories: [Territory]             // includes currency from API `included` data
}
```

**Affordances:** `getAvailability`, `createAvailability`, `listTerritories`

### SubscriptionAvailability

```swift
public struct SubscriptionAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String               // parent ID, injected by Infrastructure
    public let isAvailableInNewTerritories: Bool
    public let territories: [Territory]
}
```

**Affordances:** Same pattern as IAP availability.

## File Map

```
Sources/
├── Domain/Territories/
│   ├── Territory.swift
│   └── TerritoryRepository.swift
├── Domain/Apps/InAppPurchases/Availability/
│   ├── InAppPurchaseAvailability.swift
│   └── InAppPurchaseAvailabilityRepository.swift
├── Domain/Apps/Subscriptions/Availability/
│   ├── SubscriptionAvailability.swift
│   └── SubscriptionAvailabilityRepository.swift
├── Infrastructure/Territories/
│   └── SDKTerritoryRepository.swift
├── Infrastructure/Apps/InAppPurchases/Availability/
│   └── SDKInAppPurchaseAvailabilityRepository.swift
├── Infrastructure/Apps/Subscriptions/Availability/
│   └── SDKSubscriptionAvailabilityRepository.swift
└── ASCCommand/Commands/
    ├── Territories/
    │   ├── TerritoriesCommand.swift
    │   └── TerritoriesList.swift
    ├── IAP/Availability/
    │   ├── IAPAvailabilityCommand.swift
    │   ├── IAPAvailabilityGet.swift
    │   └── IAPAvailabilityCreate.swift
    └── Subscriptions/Availability/
        ├── SubscriptionAvailabilityCommand.swift
        ├── SubscriptionAvailabilityGet.swift
        └── SubscriptionAvailabilityCreate.swift

Tests/
├── DomainTests/Territories/
│   └── TerritoryTests.swift
├── DomainTests/Apps/InAppPurchases/Availability/
│   └── InAppPurchaseAvailabilityTests.swift
├── DomainTests/Apps/Subscriptions/Availability/
│   └── SubscriptionAvailabilityTests.swift
├── InfrastructureTests/Territories/
│   └── SDKTerritoryRepositoryTests.swift
├── InfrastructureTests/Apps/InAppPurchases/Availability/
│   └── SDKInAppPurchaseAvailabilityRepositoryTests.swift
├── InfrastructureTests/Apps/Subscriptions/Availability/
│   └── SDKSubscriptionAvailabilityRepositoryTests.swift
└── ASCCommandTests/Commands/
    ├── Territories/
    │   └── TerritoriesListTests.swift
    ├── IAP/Availability/
    │   ├── IAPAvailabilityGetTests.swift
    │   └── IAPAvailabilityCreateTests.swift
    └── Subscriptions/Availability/
        ├── SubscriptionAvailabilityGetTests.swift
        └── SubscriptionAvailabilityCreateTests.swift
```

| Wiring File | Change |
|-------------|--------|
| `ClientFactory.swift` | `makeTerritoryRepository`, `makeInAppPurchaseAvailabilityRepository`, `makeSubscriptionAvailabilityRepository` |
| `ClientProvider.swift` | Static factory methods for all three repositories |
| `ASC.swift` | Register `TerritoriesCommand`, `IAPAvailabilityCommand`, `SubscriptionAvailabilityCommand` |
| `InAppPurchase.swift` | Added `getAvailability` affordance |
| `Subscription.swift` | Added `getAvailability` affordance |

## API Reference

| Endpoint | SDK Call | Repository Method |
|----------|---------|-------------------|
| GET /v1/territories | `APIEndpoint.v1.territories.get()` | `listTerritories()` |
| GET /v2/inAppPurchases/{id}/inAppPurchaseAvailability | `APIEndpoint.v2.inAppPurchases.id().inAppPurchaseAvailability.get()` | `getAvailability(iapId:)` |
| POST /v1/inAppPurchaseAvailabilities | `APIEndpoint.v1.inAppPurchaseAvailabilities.post()` | `createAvailability(iapId:...)` |
| GET /v1/subscriptions/{id}/subscriptionAvailability | `APIEndpoint.v1.subscriptions.id().subscriptionAvailability.get()` | `getAvailability(subscriptionId:)` |
| POST /v1/subscriptionAvailabilities | `APIEndpoint.v1.subscriptionAvailabilities.post()` | `createAvailability(subscriptionId:...)` |

### REST Endpoints

| Method | Path | Body | Notes |
|--------|------|------|-------|
| GET | `/api/v1/iap/{iapId}/availability` | — | Returns synthetic full-territory record when no availability is configured yet |
| PATCH | `/api/v1/iap/{iapId}/availability` | `{ "territoryIds": [...], "availableInNewTerritories": Bool }` | Upsert via ASC `POST /v1/inAppPurchaseAvailabilities` (replaces if already set) |
| GET | `/api/v1/subscriptions/{subscriptionId}/availability` | — | Same synthetic-default behavior |

## Testing

```bash
swift test --filter 'TerritoryTests|InAppPurchaseAvailabilityTests|SubscriptionAvailabilityTests|SDKTerritoryRepositoryTests|SDKInAppPurchaseAvailabilityRepositoryTests|SDKSubscriptionAvailabilityRepositoryTests|IAPAvailabilityGetTests|IAPAvailabilityCreateTests|SubscriptionAvailabilityGetTests|SubscriptionAvailabilityCreateTests|TerritoriesListTests'
```

## Extending

- **App-level availability** — Use `/v2/appAvailabilities` for app-level territory control
- **Territory filtering** — Add `--currency USD` filter to `asc territories list`
