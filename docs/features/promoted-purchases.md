# Promoted Purchases

App Store product page promoted slots — the "Featured In-App Purchases" surfaced under an app's product page on the App Store. Each slot promotes either an in-app purchase or an auto-renewable subscription, and goes through App Review separately.

## CLI commands

| Command | Required flags | Notes |
|---------|----------------|-------|
| `asc promoted-purchases list --app-id <id> [--limit <n>]` | `--app-id` | |
| `asc promoted-purchases create --app-id <id> (--iap-id <id> | --subscription-id <id>) [--visible | --hidden] [--enabled | --disabled]` | `--app-id` plus exactly one of `--iap-id` / `--subscription-id` | Mutual-exclusion validated in the command. |
| `asc promoted-purchases update --promoted-id <id> [--visible | --hidden] [--enabled | --disabled]` | `--promoted-id` | |
| `asc promoted-purchases delete --promoted-id <id>` | `--promoted-id` | |

`--visible` / `--hidden` flip `isVisibleForAllUsers`. `--enabled` / `--disabled` flip `isEnabled`. Omitting the pair leaves the field unchanged.

## State semantics

```swift
public enum PromotedPurchaseState: String, Sendable, Codable, Equatable {
    case approved, rejected, prepareForSubmission, waitingForReview, inReview, developerActionNeeded

    public var isLocked: Bool   // true while WAITING_FOR_REVIEW or IN_REVIEW
    public var isApproved: Bool // true only for .approved
}
```

## State-aware affordances

| State | `update` link | `delete` link |
|-------|---------------|---------------|
| `approved` / `rejected` / `prepareForSubmission` / `developerActionNeeded` | shown | shown |
| `waitingForReview` / `inReview` | **suppressed** | **suppressed** |

Submitting a mutation against a slot in review is a 409 conflict in ASC, so an agent following affordances can't make that mistake.

## Domain model

```swift
public struct PromotedPurchase: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String
    public let isVisibleForAllUsers: Bool
    public let isEnabled: Bool
    public let state: PromotedPurchaseState?
    public let inAppPurchaseId: String?    // mutually exclusive with subscriptionId
    public let subscriptionId: String?
}
```

`tableRow` formats the promotes target as `iap:<id>` or `sub:<id>`.

## REST endpoints

| Path | Method |
|------|--------|
| `/api/v1/apps/:appId/promoted-purchases` | GET |

## API reference

| Command | SDK call |
|---------|----------|
| `list` | `APIEndpoint.v1.apps.id(id).promotedPurchases.get()` |
| `create` | `APIEndpoint.v1.promotedPurchases.post(PromotedPurchaseCreateRequest)` |
| `update` | `APIEndpoint.v1.promotedPurchases.id(id).patch(PromotedPurchaseUpdateRequest)` |
| `delete` | `APIEndpoint.v1.promotedPurchases.id(id).delete` |

## File map

```
Sources/Domain/Apps/PromotedPurchases/
├── PromotedPurchase.swift
└── PromotedPurchaseRepository.swift

Sources/Infrastructure/Apps/PromotedPurchases/
└── SDKPromotedPurchaseRepository.swift

Sources/ASCCommand/Commands/PromotedPurchases/
├── PromotedPurchasesCommand.swift
├── PromotedPurchasesList.swift
├── PromotedPurchasesCreate.swift
├── PromotedPurchasesUpdate.swift
└── PromotedPurchasesDelete.swift

Sources/ASCCommand/Commands/Web/Controllers/
└── PromotedPurchasesController.swift
```

## Testing

```bash
swift test --filter 'PromotedPurchase'
```
