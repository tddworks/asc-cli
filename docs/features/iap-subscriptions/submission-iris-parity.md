# IAP / Subscription Submission — public SDK vs iris parity gap

## Status: IAP shipped via `asc iris iap-submissions` (subscriptions still pending)

## The gap

| | Public ASC SDK | Iris (private) |
|---|---|---|
| Endpoint | `POST /v1/inAppPurchaseSubmissions` | `POST /iris/v1/inAppPurchaseSubmissions` |
| `attributes.submitWithNextAppStoreVersion` | ❌ not supported | ✅ accepted |
| Auth | Team API key (`AuthKey_*.p8`) | Browser cookie session (iris) |
| First-time IAP submission | Tends to fail (no flag to express "attach to next version") | Works with `submitWithNextAppStoreVersion: true` |

`InAppPurchaseSubmissionCreateRequest` in `appstoreconnect-swift-sdk` exposes only `data.type` + `data.relationships.inAppPurchaseV2` — there's no `attributes` field on the create request at all. Our existing `SDKInAppPurchaseSubmissionRepository.submitInAppPurchase` is built on this shape.

The iris request shape Apple's web UI sends (verified via DevTools curl):

```json
POST /iris/v1/inAppPurchaseSubmissions
{
  "data": {
    "type": "inAppPurchaseSubmissions",
    "attributes": { "submitWithNextAppStoreVersion": true },
    "relationships": {
      "inAppPurchaseV2": { "data": { "type": "inAppPurchases", "id": "..." } }
    }
  }
}
```

Same gap applies to subscriptions (`/iris/v1/subscriptionSubmissions`).

## Why this matters

Apple's published rule (developer docs):

> The first IAP for an app must be submitted alongside a new app version. Subsequent submissions can be standalone.

The web UI expresses "alongside next version" via `submitWithNextAppStoreVersion: true`. Without this flag, first-time IAPs can't be submitted through the public API — the call returns a relationship/state error that asc-cli currently surfaces as a generic ASC failure.

## Plumbing already in place

- `Sources/Infrastructure/Iris/IrisClient.swift` — handles cookie injection, `[asc-ui]` CSRF header, JSON:API content-type
- `Sources/Infrastructure/Iris/BrowserIrisCookieProvider.swift` — pulls cookies from the user's logged-in browser
- Working precedent: `IrisSDKAppBundleRepository` already calls iris through `IrisClient`

## Shipped approach (IAP)

Two paths, namespaced by auth surface — the existing `asc iap submit` stays untouched (key-auth, CI-friendly), and a new iris-namespaced path opts into the `submitWithNextAppStoreVersion` flag.

### CLI

```bash
asc iris iap-submissions create --iap-id <id> [--no-with-next-version]
```

`--with-next-version` defaults to **true** (the only reason to use this path). `--no-with-next-version` opts out and posts `false`. Lives under `asc iris …` because it requires iris cookies — either browser cookies or a session persisted by `asc iris auth login`.

### REST

```
POST /api/v1/iris/iap/:iapId/submissions
Content-Type: application/json
{
  "submitWithNextAppStoreVersion": true   // optional; default true
}
```

Returns the submission resource with a `_links.viewIAP → /api/v1/iap/:iapId` so the caller can navigate back to the IAP after submission.

### Domain protocol

```swift
public protocol IrisInAppPurchaseSubmissionRepository: Sendable {
    func submitInAppPurchase(
        session: IrisSession,
        iapId: String,
        submitWithNextAppStoreVersion: Bool
    ) async throws -> IrisInAppPurchaseSubmission
}
```

Distinct from `InAppPurchaseSubmissionRepository` (public SDK) so the two auth surfaces don't tangle.

### Discoverability

`IrisStatus.affordances` advertises `submitIAP` when iris is authenticated, so `asc iris status` lists the iris-only IAP submission path alongside `listApps` / `createApp`.

### Submission affordances on `InAppPurchase`

Two clean inverse pairs, gated on `state == .readyToSubmit`:

- **`addToNextVersion` ↔ `removeFromNextVersion`** — iris queue family. Add stages the IAP to ride along with the next App Store version submission; remove dequeues it.
- **`submit`** — public-SDK direct submit; only emitted once the app has shipped at least one IAP (Apple rejects the direct path for the first IAP).

| Condition | Affordances emitted |
|---|---|
| `state == .readyToSubmit && submitWithNextAppStoreVersion == true` | `removeFromNextVersion` (only) |
| `state == .readyToSubmit && !submitWithNextAppStoreVersion && isFirstTimeSubmission` | `addToNextVersion` (only) |
| `state == .readyToSubmit && !submitWithNextAppStoreVersion && !isFirstTimeSubmission` | `addToNextVersion` **and** `submit` |
| any other state | none of the above |

| Affordance | Command | What it does |
|---|---|---|
| `addToNextVersion` | `asc iris iap-submissions create --iap-id <id>` | `POST /iris/v1/inAppPurchaseSubmissions` (iris cookie auth) |
| `removeFromNextVersion` | `asc iap unsubmit --submission-id <iapId>` | `DELETE /v1/inAppPurchaseSubmissions/{id}` (public SDK; Apple keys the submission resource by parent IAP id in iris) |
| `submit` | `asc iap submit --iap-id <id>` | `POST /v1/inAppPurchaseSubmissions` (public SDK; standalone review) |

For an established-app IAP that's ready, the agent sees both `submit` and `addToNextVersion` and picks based on release strategy — standalone review (`submit`) vs ride along with the next app version (`addToNextVersion`).

#### Where the two signals come from

- **`isFirstTimeSubmission`** — derived per-batch in `SDKInAppPurchaseRepository.listInAppPurchases`. Every IAP returned for the app is checked via `InAppPurchaseState.hasBeenApproved` (`approved | developerRemovedFromSale | removedFromSale`); if zero are shipped, every unapproved IAP gets `true`. **Zero extra API calls** — derived from data already in the listing response.
- **`submitWithNextAppStoreVersion`** — best-effort enrichment via `IrisSDKInAppPurchaseStateRepository.fetchSubmitFlags`. One iris call per `iap list`, server-side filtered to `state=READY_TO_SUBMIT` with only the one field. Failures (no iris cookies, network error, malformed response) silently leave the flag `false` so CI scripts using API-key auth keep their existing JSON output unchanged.

**Caveat — `iap get` ≠ `iap list`.** A single `asc iap get --iap-id <id>` has no batch context, so `isFirstTimeSubmission` defaults to `false`. Iris enrichment also fires only on the list path. Agents that need the right affordance should `list` first.

### Subscriptions — still pending

Same gap exists at `POST /iris/v1/subscriptionSubmissions`. The implementation will mirror this PR — separate `IrisSubscriptionSubmissionRepository`, `asc iris subscription-submissions create`, `POST /api/v1/iris/subscriptions/:id/submissions`. Out of scope for this iteration to keep the change reviewable.

## Tradeoffs

- **Headless CI cannot do first-time IAP submission** — iris requires a browser session, which CI doesn't have. This is an inherent Apple limitation, not something asc-cli can fix.
- **Two auth surfaces** to maintain (key-auth + cookie-auth) — already true for the AppBundle iris repo, so the precedent is set.
- **Iris contracts can change without notice** — Apple may revise the iris payload shape. We accept that risk for any iris-backed code.

## Out of scope of this note

- Auto-detecting first-time vs. subsequent submission to choose the path automatically. Better surfaced via the readiness checklist (separate design note) so the user/UI explicitly opts in.
- Submitting *with* a specific app version (different endpoint). Today's `submitWithNextAppStoreVersion: true` just attaches to whichever version is in flight; binding to a specific version is a separate Apple flow.

## See also

- `docs/features/iap-subscriptions/lifecycle.md` — current submission CLI/REST commands
- `Sources/Infrastructure/Iris/IrisClient.swift` — iris HTTP layer
