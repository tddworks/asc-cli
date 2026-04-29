# IAP & Subscription Lifecycle

Symmetric `update` / `delete` / `unsubmit` across in-app-purchase and subscription aggregates so an agent can drive the full lifecycle, not just create-then-submit.

## CLI commands

### IAP

| Command | Required flags | Optional flags |
|---------|----------------|----------------|
| `asc iap update --iap-id <id>` | `--iap-id` | `--reference-name <n>`, `--review-note <note>`, `--family-sharable`, `--not-family-sharable` |
| `asc iap delete --iap-id <id>` | `--iap-id` | |
| `asc iap unsubmit --submission-id <id>` | `--submission-id` | |

### IAP localizations

| Command | Required flags | Optional flags |
|---------|----------------|----------------|
| `asc iap-localizations update --localization-id <id>` | `--localization-id` | `--name <n>`, `--description <d>` |
| `asc iap-localizations delete --localization-id <id>` | `--localization-id` | |

### Subscriptions

| Command | Required flags | Optional flags |
|---------|----------------|----------------|
| `asc subscriptions update --subscription-id <id>` | `--subscription-id` | `--name <n>`, `--family-sharable`, `--not-family-sharable`, `--group-level <n>`, `--review-note <note>` |
| `asc subscriptions delete --subscription-id <id>` | `--subscription-id` | |
| `asc subscriptions unsubmit --submission-id <id>` | `--submission-id` | |

### Subscription localizations

| Command | Required flags | Optional flags |
|---------|----------------|----------------|
| `asc subscription-localizations update --localization-id <id>` | `--localization-id` | `--name <n>`, `--description <d>` |
| `asc subscription-localizations delete --localization-id <id>` | `--localization-id` | |

### Subscription Groups

| Command | Required flags |
|---------|----------------|
| `asc subscription-groups update --group-id <id> --reference-name <n>` | both |
| `asc subscription-groups delete --group-id <id>` | `--group-id` |

### REST surface (subscription group localizations)

| Verb | Path | Body |
|------|------|------|
| `GET` | `/api/v1/subscription-groups/:groupId/subscription-group-localizations` | — |
| `POST` | `/api/v1/subscription-groups/:groupId/subscription-group-localizations` | `{locale, name, customAppName?}` |
| `PATCH` | `/api/v1/subscription-group-localizations/:localizationId` | `{name?, customAppName?}` |
| `DELETE` | `/api/v1/subscription-group-localizations/:localizationId` | — |

### Introductory offers

| Command | Required flags |
|---------|----------------|
| `asc subscription-offers delete --offer-id <id>` | `--offer-id` |

## Read-side `reviewNote`

Both `InAppPurchase` and `Subscription` carry a `reviewNote: String?` field on the read path. ASC returns it on every list/get; the value an agent wrote with `--review-note` is visible on the next `asc iap list` / `asc subscriptions list` (and the matching REST endpoints) without a separate fetch. Nil values are omitted from JSON via `encodeIfPresent`, so output shape is unchanged when no note is set.

```json
{
  "id": "iap-1",
  "appId": "app-1",
  "productId": "com.app.gold",
  "reviewNote": "Use code TEST",
  "state": "MISSING_METADATA"
}
```

## Affordances surfaced

After running any list/create command, JSON output advertises the matching update/delete/unsubmit commands:

```json
"affordances" : {
  "delete" : "asc iap delete --iap-id iap-1",
  "update" : "asc iap update --iap-id iap-1 --reference-name <name>",
  "submit" : "asc iap submit --iap-id iap-1"   // only when state == READY_TO_SUBMIT
}
```

`InAppPurchaseSubmission` and `SubscriptionSubmission` both advertise `unsubmit` so an agent can withdraw from review. Group localization, IAP localization, and Subscription localization all advertise `update` + `delete`.

## API reference

| Command | SDK call |
|---------|----------|
| `iap update` | `APIEndpoint.v2.inAppPurchases.id(id).patch(InAppPurchaseV2UpdateRequest)` |
| `iap delete` | `APIEndpoint.v2.inAppPurchases.id(id).delete` |
| `iap unsubmit` | manual `Request<Void>(path: "/v1/inAppPurchaseSubmissions/{id}", method: "DELETE")` |
| `iap-localizations update` | `APIEndpoint.v1.inAppPurchaseLocalizations.id(id).patch(...)` |
| `iap-localizations delete` | `APIEndpoint.v1.inAppPurchaseLocalizations.id(id).delete` |
| `subscriptions update` | `APIEndpoint.v1.subscriptions.id(id).patch(SubscriptionUpdateRequest)` |
| `subscriptions delete` | `APIEndpoint.v1.subscriptions.id(id).delete` |
| `subscriptions unsubmit` | manual `Request<Void>(path: "/v1/subscriptionSubmissions/{id}", method: "DELETE")` |
| `subscription-localizations update` | `APIEndpoint.v1.subscriptionLocalizations.id(id).patch(...)` |
| `subscription-localizations delete` | `APIEndpoint.v1.subscriptionLocalizations.id(id).delete` |
| `subscription-groups update` | `APIEndpoint.v1.subscriptionGroups.id(id).patch(SubscriptionGroupUpdateRequest)` |
| `subscription-groups delete` | `APIEndpoint.v1.subscriptionGroups.id(id).delete` |
| `subscription-offers delete` | `APIEndpoint.v1.subscriptionIntroductoryOffers.id(id).delete` |

## Testing

```bash
swift test --filter 'IAPUpdateTests|IAPDeleteTests|IAPUnsubmitTests|SubscriptionsUpdateTests|SubscriptionsDeleteTests|SubscriptionsUnsubmitTests'
```
