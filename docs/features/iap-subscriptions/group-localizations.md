# Subscription Group Localizations

Per-locale display name and Custom App Name for a subscription group.

## CLI commands

| Command | Required flags |
|---------|----------------|
| `asc subscription-group-localizations list --group-id <id>` | `--group-id` |
| `asc subscription-group-localizations create --group-id <id> --locale <code> --name <n> [--custom-app-name <c>]` | first three |
| `asc subscription-group-localizations update --localization-id <id> [--name <n>] [--custom-app-name <c>]` | `--localization-id` |
| `asc subscription-group-localizations delete --localization-id <id>` | `--localization-id` |

## Domain model

```swift
public struct SubscriptionGroupLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let groupId: String
    public let locale: String
    public let name: String?
    public let customAppName: String?
    public let state: SubscriptionGroupLocalizationState?  // PREPARE_FOR_SUBMISSION / WAITING_FOR_REVIEW / APPROVED / REJECTED
}
```

`SubscriptionGroup` advertises `createLocalization` + `listLocalizations` so an agent navigating from a group can discover the localization tree.

## REST endpoints

| Path | Method |
|------|--------|
| `/api/v1/subscription-groups/:groupId/subscription-group-localizations` | GET |

## API reference

| Command | SDK call |
|---------|----------|
| `*list` | `APIEndpoint.v1.subscriptionGroups.id(id).subscriptionGroupLocalizations.get()` |
| `*create` | `APIEndpoint.v1.subscriptionGroupLocalizations.post(SubscriptionGroupLocalizationCreateRequest)` |
| `*update` | `APIEndpoint.v1.subscriptionGroupLocalizations.id(id).patch(...)` |
| `*delete` | `APIEndpoint.v1.subscriptionGroupLocalizations.id(id).delete` |

## Testing

```bash
swift test --filter 'SubscriptionGroupLocalization'
```
