# IAP / Subscription Submission — public SDK vs iris parity gap

## Status: design note (not implemented)

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

## Proposed approach (when we ship this)

1. Extend the protocol — one method, explicit knob, default = current behaviour:

   ```swift
   public protocol InAppPurchaseSubmissionRepository: Sendable {
       func submitInAppPurchase(
           iapId: String,
           submitWithNextAppStoreVersion: Bool
       ) async throws -> InAppPurchaseSubmission
       func deleteSubmission(submissionId: String) async throws
   }
   ```

   `false` → existing public SDK path (key-auth, no browser session needed).
   `true` → new iris path via `IrisClient`, requires browser cookies.

2. CLI: `asc iap submit --iap-id X [--with-next-version]`. Default `false` keeps CI scripts working unchanged.

3. REST: `POST /api/v1/iap/:iapId/submit` body `{"submitWithNextAppStoreVersion": true}` (omit / `false` keeps legacy shape).

4. Mirror on the subscription side.

5. Surface a clear error when `--with-next-version` is requested but iris cookies are missing — point the user at `asc iris status`.

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
