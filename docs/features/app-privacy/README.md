---
description: Show, declare and publish an app's App Privacy label (data collection, "nutrition label") via the iris web session. Use when App Review refuses a submission over unpublished data usages, or the app's data practices change.
---

# App Privacy

Read, declare and publish an app's **App Privacy** label: "Data Not Collected", or each data type the app collects with its purposes, whether it's linked to the user and whether it tracks them. App Review refuses a submission until the label is published ("You must have published answers to your app's data usages"). Apple has no public API for this page, so it goes through the [iris](../iris/README.md) session. Every flag: [command reference](../../commands.md#asc-iris). Design and captured wire format: [design.md](design.md).

## Quick start

```bash
asc iris app-privacy get     --app-id 1234567890 --pretty
asc iris app-privacy declare --app-id 1234567890 --not-collected
asc iris app-privacy publish --app-id 1234567890
```

## Workflows

### See whether the label blocks review

```bash
asc iris app-privacy get --app-id 1234567890 --output table
```

| `dataCollection` | Meaning |
|---|---|
| `NOT_ANSWERED` | Nothing declared yet |
| `NOT_COLLECTED` | "Data Not Collected" — the whole label |
| `COLLECTED` | `collectedData` lists each data type |

`blocksSubmission` is `true` until the label is both answered and published. `affordances` (or `_links` over REST) say what to run next: `declareNotCollected` while nothing is declared, `publish` while a declared label isn't live.

### Declare what the app collects

Write the data types in the same shape `get` shows them:

```json
{
  "collectedData": [
    { "category": "EMAIL_ADDRESS", "purposes": ["APP_FUNCTIONALITY"], "isLinkedToYou": true,  "isUsedToTrackYou": false },
    { "category": "CRASH_DATA",    "purposes": ["ANALYTICS"],         "isLinkedToYou": false, "isUsedToTrackYou": false }
  ]
}
```

```bash
asc iris app-privacy declare --app-id 1234567890 --file privacy.json
asc iris app-privacy publish --app-id 1234567890
```

`declare` replaces the whole label: data types not in the file are removed, and rows already right are left alone. The file may also be `{"notCollected": true}`.

- **Categories:** `NAME`, `EMAIL_ADDRESS`, `PHONE_NUMBER`, `PHYSICAL_ADDRESS`, `OTHER_CONTACT_INFO`, `HEALTH`, `FITNESS`, `PAYMENT_INFORMATION`, `CREDIT_AND_FRAUD`, `OTHER_FINANCIAL_INFO`, `PRECISE_LOCATION`, `COARSE_LOCATION`, `SENSITIVE_INFO`, `CONTACTS`, `EMAILS_OR_TEXT_MESSAGES`, `PHOTOS_OR_VIDEOS`, `AUDIO`, `GAMEPLAY_CONTENT`, `CUSTOMER_SUPPORT`, `OTHER_USER_CONTENT`, `BROWSING_HISTORY`, `SEARCH_HISTORY`, `USER_ID`, `DEVICE_ID`, `PURCHASE_HISTORY`, `PRODUCT_INTERACTION`, `ADVERTISING_DATA`, `OTHER_USAGE_DATA`, `CRASH_DATA`, `PERFORMANCE_DATA`, `OTHER_DIAGNOSTIC_DATA`, `OTHER_DATA_TYPES`
- **Purposes:** `APP_FUNCTIONALITY`, `ANALYTICS`, `PRODUCT_PERSONALIZATION`, `DEVELOPERS_ADVERTISING`, `THIRD_PARTY_ADVERTISING`, `OTHER_PURPOSES`

## REST

| CLI | REST |
|---|---|
| `get --app-id A` | `GET /api/v1/iris/apps/A/app-privacy` |
| `declare --app-id A --not-collected` | `POST /api/v1/iris/apps/A/app-privacy/declare` with `{"notCollected": true}` |
| `declare --app-id A --file f.json` | `POST /api/v1/iris/apps/A/app-privacy/declare` with the file's JSON |
| `publish --app-id A` | `POST /api/v1/iris/apps/A/app-privacy/publish` |

An unknown category or purpose answers `422`; publishing a label with nothing declared answers `409`.

## Gotchas

- **Declaring doesn't publish.** Run `publish` afterwards; until then `blocksSubmission` stays `true`.
- **Nothing unknown is sent.** A category or purpose asc doesn't know is refused before anything reaches Apple, so a typo can't leave half a label.
- **"Linked to you" is per data type.** A data type is linked if any of its purposes is.
- It's a private API: Apple can change it without notice.

## See also

- [Iris](../iris/README.md) — signing in
- [App Compliance](../app-compliance/README.md) — the other private-API declarations
