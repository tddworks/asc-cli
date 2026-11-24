# App Privacy — "Data Not Collected", or what the app collects and why

**Status: BUILT** (get, declare, publish; CLI and REST). User guide: [README.md](README.md). Apple has no public API for App Privacy: appstoreconnect-swift-sdk has no `appDataUsages` endpoints, yet App Review refuses a submission until the answers are published ("You must have published answers to your app's data usages"). The web page reads and writes them through iris (`/iris/v1`) with the Apple ID session cookies.

This document owns **the privacy label an app declares and publishes**. Its neighbours own the rest:

| For | Read |
|---|---|
| Getting an Apple ID session | [Iris](../iris/README.md) |
| Regional declarations (China AIGC, Security Assessment) | [App Compliance](../app-compliance/design.md) |
| The privacy policy URL | [App info localizations](../app-info-localizations/README.md), a public-API resource |

---

## The one sentence

**An app's privacy label is either "Data Not Collected" or the data types it collects — each with the purposes it is used for, whether it is linked to the user and whether it tracks them — and nothing counts until it is published.**

```
 App 1234567890                                  published
  ├─ OTHER_USAGE_DATA  ANALYTICS, APP_FUNCTIONALITY  not linked · no tracking
  └─ EMAIL_ADDRESS     APP_FUNCTIONALITY             linked     · no tracking
```

## Ubiquitous language

| Word | Means | On the wire |
|---|---|---|
| **App privacy** | the label: one per app, the aggregate | `apps/{id}/dataUsages` + `apps/{id}/dataUsagePublishState` |
| **Data collection** | not answered / not collected / collected | no rows / the one `DATA_NOT_COLLECTED` row / rows with a category |
| **Collected data** | one data type and how it's used | every row for one `category` |
| **Data usage** | one row Apple stores; asc's internal unit of change | `appDataUsages` (category × purpose × protection) |
| **Published** | the label is live and no longer blocks review | `published: true` |

## Laws

1. **Collected data is the developer's unit; a row is Apple's.** asc shows and takes collected data, and turns it into rows only in `DataUsageEntry` (one row per purpose, plus a purpose-less `DATA_USED_TO_TRACK_YOU` row when it tracks). Owner: `PrivacyDeclaration.entries`.
2. **"Data Not Collected" is the whole label.** It can't be combined with a data type — the declaration type can't express both. Owner: `PrivacyDeclaration`.
3. **Declaring replaces the label.** asc deletes the rows that aren't wanted, then creates the missing ones (deletions first: a not-collected row can't sit beside a category). Rows already right are left alone. Owner: `DataUsagePlan`.
4. **Declaring does not publish.** The answer stays a draft until `publish`; the label then offers `publish`. Owner: `AppPrivacy.structuredAffordances`.
5. **Nothing is published until something is declared.** Owner: `AppPrivacy.publish(session:repo:)`.
6. **Only values asc knows are sent.** A category or purpose it doesn't know is refused before anything reaches Apple; one Apple returns is kept as Apple sent it. Owner: `PrivacyDeclaration.validate()`, `DataCategory`/`DataPurpose`.
7. **A label blocks review until it is answered and published.** Owner: `AppPrivacy.blocksSubmission`.

## The captured wire format

Captured live on 2026-11-24, read-only (ids replaced). Every call is on `https://appstoreconnect.apple.com/iris/v1/`, JSON:API, gzip-compressed (`URLSession` unpacks it).

### The rows

```
GET apps/{appId}/dataUsages?include=category,grouping,purpose,dataProtection&limit=500
```

Nothing declared — Apple answers an empty list (not `{}`):

```json
{ "data": [], "included": [], "meta": { "paging": { "total": 0, "limit": 500 } } }
```

Data Not Collected — one row, every other relationship `null`:

```json
{ "data": [ { "type": "appDataUsages", "id": "usage-1", "relationships": {
    "category": { "data": null }, "grouping": { "data": null }, "purpose": { "data": null },
    "dataProtection": { "data": { "type": "appDataUsageDataProtections", "id": "DATA_NOT_COLLECTED" } } } } ] }
```

Collected — one row per purpose (captured: one category, three purposes, not linked):

```json
{ "data": [
  { "type": "appDataUsages", "id": "usage-1", "relationships": {
      "category": { "data": { "type": "appDataUsageCategories", "id": "OTHER_USAGE_DATA" } },
      "grouping": { "data": { "type": "appDataUsageGroupings", "id": "USAGE_DATA" } },
      "purpose": { "data": { "type": "appDataUsagePurposes", "id": "OTHER_PURPOSES" } },
      "dataProtection": { "data": { "type": "appDataUsageDataProtections", "id": "DATA_NOT_LINKED_TO_YOU" } } } },
  … ANALYTICS, APP_FUNCTIONALITY …
] }
```

- The ids are in the relationships; `included` adds only `deleted: false`, so asc doesn't read it.
- A tracking row (`DATA_USED_TO_TRACK_YOU`, no purpose) has not been captured: none of the account's apps track.

### Published or not

```
GET apps/{appId}/dataUsagePublishState
```

```json
{ "data": { "type": "appDataUsagesPublishState", "id": "1234567890",
    "attributes": { "published": true, "lastPublished": "2026-11-24T00:14:02-08:00", "lastPublishedBy": "…" } } }
```

Never published: `"published": false, "lastPublished": null`.

### Changing it

| Call | Body | Captured |
|---|---|---|
| `POST appDataUsages` | `{"data":{"type":"appDataUsages","relationships":{"app":…,"dataProtection":{"data":{"type":"appDataUsageDataProtections","id":"DATA_NOT_COLLECTED"}}}}}` | yes, 201 (body not read) |
| `POST appDataUsages`, collected | the same, plus `category` and `purpose` relationships | **no** — modelled on the above |
| `DELETE appDataUsages/{id}` | — | **no** — the row's own `links.self` |
| `PATCH appDataUsagesPublishState/{appId}` | `{"data":{"type":"appDataUsagesPublishState","id":"{appId}","attributes":{"published":true}}}` | yes, 200 |

asc reads nothing back from a change: after declaring or publishing it reads the label again.

## Open questions

1. Is "linked to you" asked once per data type, or per purpose? asc assumes per data type (a row set mixing both shows as linked).
2. Does changing a published label unpublish it? asc doesn't assume: it reads `published` back after each declare.
3. The collected `POST` and the `DELETE` are uncaptured; confirm on a live app.
