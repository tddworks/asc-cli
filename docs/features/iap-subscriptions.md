# In-App Purchases & Subscriptions

End-to-end management of in-app purchases (consumable, non-consumable, non-renewing subscriptions) and auto-renewable subscriptions, with full lifecycle, pricing, offer-code, promotional/win-back offer, and review-asset coverage.

Every command also serves as a REST endpoint when running `asc web-server`. Affordances embedded in JSON output are state-aware — they only suggest the next legal action.

## Sub-documents

| Document | Covers |
|----------|--------|
| [lifecycle.md](iap-subscriptions/lifecycle.md) | IAP & Subscription `update` / `delete` / `unsubmit` plus subscription-group / introductory-offer lifecycle. |
| [pricing.md](iap-subscriptions/pricing.md) | IAP base-territory pricing and subscription per-territory pricing (incl. `proceedsYear2`). |
| [offer-codes.md](iap-subscriptions/offer-codes.md) | IAP & subscription offer codes — 3-level hierarchy plus per-territory price listing and one-time-code redemption value fetch. |
| [group-localizations.md](iap-subscriptions/group-localizations.md) | Per-locale display name and Custom App Name for subscription groups. |
| [promotional-offers.md](iap-subscriptions/promotional-offers.md) | Subscription promotional offers with per-territory inline pricing. |
| [win-back-offers.md](iap-subscriptions/win-back-offers.md) | Win-back offers with eligibility rules, priority, promotion intent, and per-territory pricing. |
| [review-assets.md](iap-subscriptions/review-assets.md) | IAP review screenshots & 1024×1024 promotional images, subscription review screenshots — reserve→upload→commit-with-MD5. |

## REST navigation (`_links`)

When `asc web-server` is running, every IAP and Subscription returned from the list endpoints embeds a populated `_links` map so an agent can fetch its details without knowing URL conventions.

| Resource | List endpoint | Embedded `_links` keys |
|----------|---------------|------------------------|
| `InAppPurchase` | `GET /api/v1/apps/:appId/iap` | `listLocalizations`, `listOfferCodes`, `listImages`, `listPricePoints`, `getAvailability`, `getReviewScreenshot`, `update`, `delete`, `submit` (only when `READY_TO_SUBMIT`), `createLocalization` |
| `Subscription` | `GET /api/v1/subscription-groups/:groupId/subscriptions` | `listLocalizations`, `listIntroductoryOffers`, `listOfferCodes`, `listPromotionalOffers`, `listWinBackOffers`, `listPricePoints`, `getAvailability`, `getReviewScreenshot`, `update`, `delete`, `submit` (only when `READY_TO_SUBMIT`), `createLocalization`, `createIntroductoryOffer`, `createPromotionalOffer` |

Each `_links` entry resolves to a wired controller. For an IAP at id `iap-7`:

| Link key | Method | URL |
|----------|--------|-----|
| `listLocalizations` | GET | `/api/v1/iap/iap-7/localizations` |
| `getAvailability` | GET | `/api/v1/iap/iap-7/availability` |
| `listOfferCodes` | GET | `/api/v1/iap/iap-7/offer-codes` |
| `listPricePoints` | GET | `/api/v1/iap/iap-7/price-points` |
| `getReviewScreenshot` | GET | `/api/v1/iap/iap-7/review-screenshot` |
| `listImages` | GET | `/api/v1/iap/iap-7/images` |

The same shape applies to subscriptions under `/api/v1/subscriptions/{id}/…` (replace `iap` with `subscriptions` and `getReviewScreenshot`/`listImages` with subscription-specific equivalents; `listIntroductoryOffers` → `/introductory-offers`).

Related top-level features:

- [promoted-purchases.md](promoted-purchases.md) — App Store product page promoted slots.
- [iap-subscription-availability.md](iap-subscription-availability.md) — territory availability for apps, IAPs, and subscriptions.

## Architecture

```
ASCCommand                            Infrastructure                            Domain
─────────────────────────────────────────────────────────────────────────────────────────
IAP*                                  SDKInAppPurchaseRepository                InAppPurchase
IAPSubmit / Unsubmit                  SDKInAppPurchaseSubmissionRepository      InAppPurchaseSubmission
IAPLocalizations*                     SDKInAppPurchaseLocalizationRepository    InAppPurchaseLocalization
IAPPricePointsList / IAPPricesSet     SDKInAppPurchasePriceRepository           InAppPurchasePricePoint, PriceSchedule
IAPOfferCodes*                        SDKInAppPurchaseOfferCodeRepository       InAppPurchaseOfferCode + Custom + OneTime + Price
IAPReviewScreenshot* / IAPImages*     SDKInAppPurchaseReviewRepository          InAppPurchaseReviewScreenshot, PromotionalImage

SubscriptionGroups*                   SDKSubscriptionGroupRepository            SubscriptionGroup
SubscriptionGroupLocalizations*       SDKSubscriptionGroupLocalizationRepository SubscriptionGroupLocalization
Subscriptions*                        SDKSubscriptionRepository                 Subscription
SubscriptionsSubmit / Unsubmit        SDKSubscriptionSubmissionRepository       SubscriptionSubmission
SubscriptionLocalizations*            SDKSubscriptionLocalizationRepository     SubscriptionLocalization
SubscriptionPricePointsList /         SDKSubscriptionPriceRepository            SubscriptionPricePoint, SubscriptionPrice
  SubscriptionPricesSet                                                         (proceedsYear2)
SubscriptionOffers* (intro)           SDKSubscriptionIntroductoryOfferRepository SubscriptionIntroductoryOffer
SubscriptionPromotionalOffers*        SDKSubscriptionPromotionalOfferRepository SubscriptionPromotionalOffer + Price + Input
WinBackOffers*                        SDKWinBackOfferRepository                 WinBackOffer + Price + Input
SubscriptionOfferCodes*               SDKSubscriptionOfferCodeRepository        SubscriptionOfferCode + Custom + OneTime + Price
SubscriptionReviewScreenshot*         SDKSubscriptionReviewRepository           SubscriptionReviewScreenshot

Web/Controllers/                      RESTRoutes wires repos →                  AffordanceProviding
  IAPController, IAPReviewController,   controllers; APIRoot                      .structuredAffordances
  SubscriptionGroupsController, …       advertises top-level resources            renders to both CLI + REST
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`. Domain has zero I/O.

## State-aware affordances

Affordances suppress themselves when the action wouldn't succeed:

| Aggregate | Trigger | Affordance suppressed |
|-----------|---------|-----------------------|
| `InAppPurchase` / `Subscription` | `state != .readyToSubmit` | `submit` |
| `InAppPurchasePromotionalImage` | `state.isPendingReview == true` | `delete` |
| `InAppPurchaseReviewScreenshot` / `SubscriptionReviewScreenshot` | `assetState == .awaitingUpload` | `delete` (only `upload` offered as recovery) |
| `SubscriptionPricePoint` | `territory == nil` | `setPrice` |
| `*OfferCodeCustomCode` / `*OfferCodeOneTimeUseCode` | `isActive == false` | `deactivate` |

## SDK gaps worked around

The generated `appstoreconnect-swift-sdk` is incomplete in three places:

1. **`DELETE /v1/inAppPurchaseSubmissions/{id}`** — used by `iap unsubmit`. Built with manual `Request<Void>(path:method:id:)`.
2. **`DELETE /v1/subscriptionSubmissions/{id}`** — used by `subscriptions unsubmit`. Same manual pattern.
3. **`WinBackOfferPriceInlineCreate`** — generated entity is missing `territory` + `subscriptionPricePoint` relationships, so `win-back-offers create` builds the body via a private type-erased `AnyCodable` enum in `SDKWinBackOfferRepository`.

## File map

```
Sources/Domain/Apps/InAppPurchases/   # All IAP-side domain models
Sources/Domain/Apps/Subscriptions/    # All subscription-side domain models
Sources/Infrastructure/Apps/…         # SDK adapters mirroring the Domain folder structure
Sources/ASCCommand/Commands/IAP*/, Subscription*/, WinBackOffers/, …
Sources/ASCCommand/Commands/Web/Controllers/…Controller.swift
```

**Wiring files:**

| File | Role |
|------|------|
| `Sources/ASCCommand/ASC.swift` | Registers every command group as a subcommand. |
| `Sources/ASCCommand/ClientProvider.swift` | Static factory per repository. |
| `Sources/Infrastructure/Client/ClientFactory.swift` | Auth → SDK repository instantiation. |
| `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` | Wires controllers per repository. |

## Testing

```bash
# Domain + infra + commands + REST for IAP & subscriptions.
swift test --filter 'IAP|Subscription|WinBackOffer'
```
