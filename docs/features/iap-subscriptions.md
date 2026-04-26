# In-App Purchases & Subscriptions

End-to-end management of in-app purchases (consumable, non-consumable, non-renewing subscriptions) and auto-renewable subscriptions, with full lifecycle, pricing, offer-code, promotional/win-back offer, and review-asset coverage.

Every command also serves as a REST endpoint when running `asc web-server`. Affordances embedded in JSON output are state-aware — they only suggest the next legal action.

---

## CLI Usage

Each section lists the flags and shows representative output. JSON output omits nil fields and includes an `affordances` map (CLI mode) or `_links` map (REST mode).

### IAP lifecycle

| Command | Required flags | Notes |
|---------|---------------|-------|
| `asc iap list --app-id <id>` | `--app-id` | Add `--limit <n>` for pagination. |
| `asc iap create --app-id <id> --reference-name <n> --product-id <p> --type <t>` | all four | `--type` ∈ `consumable`, `non-consumable`, `non-renewing-subscription`. |
| `asc iap update --iap-id <id>` | `--iap-id` | Optional: `--reference-name`, `--review-note`, `--family-sharable | --not-family-sharable`. |
| `asc iap delete --iap-id <id>` | `--iap-id` | |
| `asc iap submit --iap-id <id>` | `--iap-id` | Affordance only appears when `state == READY_TO_SUBMIT`. |
| `asc iap unsubmit --submission-id <id>` | `--submission-id` | Manual `Request<Void>` — generated SDK lacks DELETE for `inAppPurchaseSubmissions`. |

### IAP localizations

| Command | Required flags |
|---------|----------------|
| `asc iap-localizations list --iap-id <id>` | `--iap-id` |
| `asc iap-localizations create --iap-id <id> --locale <code> --name <n> [--description <d>]` | first three |
| `asc iap-localizations update --localization-id <id> [--name <n>] [--description <d>]` | `--localization-id` |
| `asc iap-localizations delete --localization-id <id>` | `--localization-id` |

### IAP pricing

| Command | Required flags | Notes |
|---------|----------------|-------|
| `asc iap price-points list --iap-id <id> [--territory <code>]` | `--iap-id` | `--territory` filters to a single territory (e.g. `USA`). |
| `asc iap prices set --iap-id <id> --base-territory <code> --price-point-id <pp>` | all three | Single base territory; Apple auto-equalizes the rest. |

### IAP availability

| Command | Required flags |
|---------|----------------|
| `asc iap-availability get --iap-id <id>` | `--iap-id` |
| `asc iap-availability create --iap-id <id> --available-in-new-territories <bool> --territory <code>...` | `--iap-id`, at least one `--territory` |

### IAP offer codes (3-level hierarchy)

| Command | Required flags |
|---------|----------------|
| `asc iap-offer-codes list --iap-id <id>` | `--iap-id` |
| `asc iap-offer-codes create --iap-id <id> --name <n> --eligibility <e>...` | first two; `--eligibility` repeatable, ∈ `NON_SPENDER`, `ACTIVE_SPENDER`, `CHURNED_SPENDER` |
| `asc iap-offer-codes update --offer-code-id <id> --active <bool>` | both |
| `asc iap-offer-codes prices list --offer-code-id <id>` | `--offer-code-id` |
| `asc iap-offer-code-custom-codes list/create/update` | `--offer-code-id` (or `--custom-code-id` for update) |
| `asc iap-offer-code-one-time-codes list/create/update` | `--offer-code-id` (or `--one-time-code-id` for update) |
| `asc iap-offer-code-one-time-codes values --one-time-code-id <id>` | `--one-time-code-id`. Returns CSV of redemption codes (raw `String`). |

### IAP review assets

| Command | Required flags | Notes |
|---------|----------------|-------|
| `asc iap-review-screenshot get --iap-id <id>` | `--iap-id` | Returns empty `data: []` when no screenshot. |
| `asc iap-review-screenshot upload --iap-id <id> --file <path>` | both | Reserve → upload chunks → commit with MD5. |
| `asc iap-review-screenshot delete --screenshot-id <id>` | `--screenshot-id` | Affordance suppressed while `assetState == AWAITING_UPLOAD`. |
| `asc iap-images list --iap-id <id>` | `--iap-id` | 1024×1024 promotional images. |
| `asc iap-images upload --iap-id <id> --file <path>` | both | |
| `asc iap-images delete --image-id <id>` | `--image-id` | Affordance suppressed while `state.isPendingReview`. |

### Subscription Groups

| Command | Required flags |
|---------|----------------|
| `asc subscription-groups list --app-id <id>` | `--app-id` |
| `asc subscription-groups create --app-id <id> --reference-name <n>` | both |
| `asc subscription-groups update --group-id <id> --reference-name <n>` | both |
| `asc subscription-groups delete --group-id <id>` | `--group-id` |

### Subscription Group localizations

| Command | Required flags |
|---------|----------------|
| `asc subscription-group-localizations list --group-id <id>` | `--group-id` |
| `asc subscription-group-localizations create --group-id <id> --locale <code> --name <n> [--custom-app-name <c>]` | first three |
| `asc subscription-group-localizations update --localization-id <id> [--name <n>] [--custom-app-name <c>]` | `--localization-id` |
| `asc subscription-group-localizations delete --localization-id <id>` | `--localization-id` |

### Subscriptions

| Command | Required flags | Notes |
|---------|----------------|-------|
| `asc subscriptions list --group-id <id>` | `--group-id` | |
| `asc subscriptions create --group-id <id> --name <n> --product-id <p> --period <P>` | first four | `--period` ∈ `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`. Optional `--family-sharable`, `--group-level <n>`. |
| `asc subscriptions update --subscription-id <id>` | `--subscription-id` | Optional: `--name`, `--family-sharable | --not-family-sharable`, `--group-level`, `--review-note`. |
| `asc subscriptions delete --subscription-id <id>` | `--subscription-id` | |
| `asc subscriptions submit --subscription-id <id>` | `--subscription-id` | Affordance only when `state == READY_TO_SUBMIT`. |
| `asc subscriptions unsubmit --submission-id <id>` | `--submission-id` | Manual `Request<Void>`. |
| `asc subscriptions price-points list --subscription-id <id> [--territory <code>]` | `--subscription-id` | `proceedsYear2` field on each row. |
| `asc subscriptions prices set --subscription-id <id> --territory <code> --price-point-id <pp>` | all three | Per-territory (no base). |

### Subscription localizations

| Command | Required flags |
|---------|----------------|
| `asc subscription-localizations list --subscription-id <id>` | `--subscription-id` |
| `asc subscription-localizations create --subscription-id <id> --locale <code> --name <n> [--description <d>]` | first three |
| `asc subscription-localizations update --localization-id <id> [--name <n>] [--description <d>]` | `--localization-id` |
| `asc subscription-localizations delete --localization-id <id>` | `--localization-id` |

### Subscription availability

| Command | Required flags |
|---------|----------------|
| `asc subscription-availability get --subscription-id <id>` | `--subscription-id` |
| `asc subscription-availability create --subscription-id <id> --available-in-new-territories <bool> --territory <code>...` | first one + at least one territory |

### Introductory Offers

| Command | Required flags |
|---------|----------------|
| `asc subscription-offers list --subscription-id <id>` | `--subscription-id` |
| `asc subscription-offers create --subscription-id <id> --duration <d> --mode <m> --periods <n>` | first four |
| `asc subscription-offers delete --offer-id <id>` | `--offer-id` |

`--mode` ∈ `FREE_TRIAL`, `PAY_AS_YOU_GO`, `PAY_UP_FRONT`. The latter two require `--price-point-id`.

### Promotional Offers (with per-territory pricing)

| Command | Required flags |
|---------|----------------|
| `asc subscription-promotional-offers list --subscription-id <id>` | `--subscription-id` |
| `asc subscription-promotional-offers create --subscription-id <id> --name <n> --offer-code <c> --duration <d> --mode <m> --periods <n> [--price USA=spp-1 ...]` | all but `--price` |
| `asc subscription-promotional-offers delete --offer-id <id>` | `--offer-id` |
| `asc subscription-promotional-offers prices list --offer-id <id>` | `--offer-id` |

The `--price` flag is repeatable: `TERRITORY=PRICE_POINT_ID`. Internally encoded as `${newPromoOfferPrice-N}` 1-based local IDs in the SDK's `included` array — matches the ASC web UI request shape.

### Win-Back Offers

| Command | Required flags |
|---------|----------------|
| `asc win-back-offers list --subscription-id <id>` | `--subscription-id` |
| `asc win-back-offers create --subscription-id <id> --reference-name <n> --offer-id <code> --duration <d> --mode <m> --periods <n> --paid-months <n> --since-min <n> --since-max <n> --start-date <YYYY-MM-DD> --priority HIGH|NORMAL [--end-date ...] [--wait-months n] [--promotion-intent ...] [--price ...]` | all without brackets |
| `asc win-back-offers update --offer-id <id> [--start-date ...] [--end-date ...] [--priority ...] [--promotion-intent ...] [--paid-months n] [--since-min n] [--since-max n] [--wait-months n]` | `--offer-id` |
| `asc win-back-offers delete --offer-id <id>` | `--offer-id` |
| `asc win-back-offers prices list --offer-id <id>` | `--offer-id` |

The win-back create body is encoded by hand because the generated `WinBackOfferPriceInlineCreate` is missing `territory` + `subscriptionPricePoint` relationships.

`--priority` ∈ `HIGH`, `NORMAL`. `--promotion-intent` ∈ `NOT_PROMOTED`, `USE_AUTO_GENERATED_ASSETS`. `--paid-months` is `customerEligibilityPaidSubscriptionDurationInMonths`. `--since-min`/`--since-max` are `customerEligibilityTimeSinceLastSubscribedInMonths`.

### Subscription Offer Codes (3-level hierarchy)

| Command | Required flags |
|---------|----------------|
| `asc subscription-offer-codes list --subscription-id <id>` | `--subscription-id` |
| `asc subscription-offer-codes create --subscription-id <id> --name <n> --duration <d> --mode <m> --periods <n> --eligibility <e>... --offer-eligibility <oe>` | all |
| `asc subscription-offer-codes update --offer-code-id <id> --active <bool>` | both |
| `asc subscription-offer-codes prices list --offer-code-id <id>` | `--offer-code-id` |
| `asc subscription-offer-code-custom-codes list/create/update` | as IAP equivalents |
| `asc subscription-offer-code-one-time-codes list/create/update` | as IAP equivalents |
| `asc subscription-offer-code-one-time-codes values --one-time-code-id <id>` | `--one-time-code-id`. CSV of redemption codes. |

`--eligibility` ∈ `NEW`, `LAPSED`, `WIN_BACK`, `PAID_SUBSCRIBER`. `--offer-eligibility` ∈ `STACKABLE`, `INTRODUCTORY`, `SUBSCRIPTION_OFFER`.

### Subscription review screenshot

| Command | Required flags |
|---------|----------------|
| `asc subscription-review-screenshot get --subscription-id <id>` | `--subscription-id` |
| `asc subscription-review-screenshot upload --subscription-id <id> --file <path>` | both |
| `asc subscription-review-screenshot delete --screenshot-id <id>` | `--screenshot-id` |

---

## REST Endpoints

Every CLI list/read command above has a corresponding REST endpoint. Query params match CLI flag names verbatim.

### IAP

| Path | Method |
|------|--------|
| `/api/v1/apps/:appId/iap` | GET |
| `/api/v1/iap/:iapId/review-screenshot` | GET |
| `/api/v1/iap/:iapId/images` | GET |
| `/api/v1/iap-offer-codes/:offerCodeId/prices` | GET |

### Subscriptions

| Path | Method |
|------|--------|
| `/api/v1/apps/:appId/subscription-groups` | GET |
| `/api/v1/subscription-groups/:groupId/subscription-group-localizations` | GET |
| `/api/v1/subscriptions/:subscriptionId/price-points?territory=` | GET |
| `/api/v1/subscriptions/:subscriptionId/subscription-promotional-offers` | GET |
| `/api/v1/subscription-promotional-offers/:offerId/prices` | GET |
| `/api/v1/subscriptions/:subscriptionId/win-back-offers` | GET |
| `/api/v1/win-back-offers/:offerId/prices` | GET |
| `/api/v1/subscription-offer-codes/:offerCodeId/prices` | GET |
| `/api/v1/subscriptions/:subscriptionId/review-screenshot` | GET |

JSON responses include a `_links` field instead of `affordances`. Each link is `{ "href": "/api/v1/…", "method": "GET|POST|PATCH|DELETE" }`.

---

## Typical Workflows

### Ship a new in-app purchase

```bash
APP_ID="A123456789"

# 1. Create + localize
IAP_ID=$(asc iap create --app-id "$APP_ID" --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" --type consumable | jq -r '.data[0].id')
asc iap-localizations create --iap-id "$IAP_ID" --locale en-US --name "Gold Coins" --description "In-game currency"
asc iap-localizations create --iap-id "$IAP_ID" --locale zh-Hans --name "金币"

# 2. Set price (Tier 1 USA, Apple auto-equalizes)
PRICE_ID=$(asc iap price-points list --iap-id "$IAP_ID" --territory USA \
  | jq -r '.data[] | select(.customerPrice == "0.99") | .id')
asc iap prices set --iap-id "$IAP_ID" --base-territory USA --price-point-id "$PRICE_ID"

# 3. Add review screenshot + promo image
asc iap-review-screenshot upload --iap-id "$IAP_ID" --file ./review.png
asc iap-images upload --iap-id "$IAP_ID" --file ./promo-1024.png

# 4. Submit for review
asc iap submit --iap-id "$IAP_ID"
```

### Launch a subscription with a promotional offer

```bash
APP_ID="A123456789"

# 1. Group + tier
GROUP_ID=$(asc subscription-groups create --app-id "$APP_ID" --reference-name "Premium" \
  | jq -r '.data[0].id')
SUB_ID=$(asc subscriptions create --group-id "$GROUP_ID" --name "Monthly Premium" \
  --product-id "com.app.monthly" --period ONE_MONTH | jq -r '.data[0].id')

# 2. Localize the group + the tier
asc subscription-group-localizations create --group-id "$GROUP_ID" --locale en-US \
  --name "Premium Plans" --custom-app-name "Premium App"
asc subscription-localizations create --subscription-id "$SUB_ID" --locale en-US \
  --name "Monthly Premium" --description "Unlock everything"

# 3. Set per-territory pricing
USA_PP=$(asc subscriptions price-points list --subscription-id "$SUB_ID" --territory USA \
  | jq -r '.data[] | select(.customerPrice == "9.99") | .id')
asc subscriptions prices set --subscription-id "$SUB_ID" --territory USA --price-point-id "$USA_PP"

# 4. Promotional offer with per-territory pricing
asc subscription-promotional-offers create --subscription-id "$SUB_ID" \
  --name "Loyalty25" --offer-code loyalty25 \
  --duration THREE_MONTHS --mode PAY_AS_YOU_GO --periods 3 \
  --price USA=$USA_PP

# 5. Submit
asc subscriptions submit --subscription-id "$SUB_ID"
```

### Run a win-back campaign

```bash
SUB_ID="sub-42"

# Eligibility: paid 3 months, lapsed 1-6 months, wait 2 months between offers, expires Dec 31.
asc win-back-offers create --subscription-id "$SUB_ID" \
  --reference-name "Lapsed Q4" --offer-id lapsedQ4 \
  --duration ONE_MONTH --mode FREE_TRIAL --periods 1 \
  --paid-months 3 --since-min 1 --since-max 6 --wait-months 2 \
  --start-date 2026-04-01 --end-date 2026-12-31 \
  --priority HIGH --promotion-intent USE_AUTO_GENERATED_ASSETS
```

---

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
IAPAvailability*                      SDKInAppPurchaseAvailabilityRepository    InAppPurchaseAvailability

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
SubscriptionAvailability*             SDKSubscriptionAvailabilityRepository     SubscriptionAvailability

Web/Controllers/                      RESTRoutes wires repos →                  AffordanceProviding
  IAPController, IAPReviewController,   controllers; APIRoot                      .structuredAffordances
  SubscriptionGroupsController, …       advertises top-level resources            renders to both CLI + REST
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`. Domain has zero I/O.

**Two SDK gaps work around with manual `Request<Void>`:**
- `DELETE /v1/inAppPurchaseSubmissions/{id}` — used by `iap unsubmit`
- `DELETE /v1/subscriptionSubmissions/{id}` — used by `subscriptions unsubmit`

**One SDK gap works around with hand-encoded JSON body:**
- `WinBackOfferPriceInlineCreate` — missing `territory` + `subscriptionPricePoint` relationships, so `win-back-offers create` builds the body via a type-erased `AnyCodable` enum.

---

## State-aware affordances

Affordances suppress themselves when the action wouldn't succeed:

| Aggregate | Trigger | Affordance suppressed |
|-----------|---------|-----------------------|
| `InAppPurchase` / `Subscription` | `state != .readyToSubmit` | `submit` |
| `InAppPurchasePromotionalImage` | `state.isPendingReview == true` | `delete` |
| `InAppPurchaseReviewScreenshot` / `SubscriptionReviewScreenshot` | `assetState == .awaitingUpload` | `delete` (only `upload` offered as recovery) |
| `SubscriptionPricePoint` | `territory == nil` | `setPrice` |
| `IAP*OfferCode*` / `Subscription*OfferCode*` custom & one-time codes | `isActive == false` | `deactivate` |

---

## Key Domain Models

A representative subset — read the source for full surface.

```swift
public struct InAppPurchase: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let appId: String          // injected by Infrastructure
    public let referenceName: String
    public let productId: String
    public let type: InAppPurchaseType
    public let state: InAppPurchaseState
}
// State semantic booleans: isApproved, isLive, isEditable, isPendingReview

public struct SubscriptionPricePoint: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String
    public let territory: String?
    public let customerPrice: String?
    public let proceeds: String?
    public let proceedsYear2: String? // distinguishes subscription pricing from IAP
}

public struct WinBackOffer: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let subscriptionId: String
    public let referenceName: String
    public let offerId: String
    public let duration: SubscriptionOfferDuration
    public let offerMode: SubscriptionOfferMode
    public let periodCount: Int
    public let customerEligibilityPaidSubscriptionDurationInMonths: Int
    public let customerEligibilityTimeSinceLastSubscribedMin: Int
    public let customerEligibilityTimeSinceLastSubscribedMax: Int
    public let customerEligibilityWaitBetweenOffersInMonths: Int?
    public let startDate: String
    public let endDate: String?
    public let priority: WinBackOfferPriority   // HIGH | NORMAL
    public let promotionIntent: WinBackOfferPromotionIntent?
}

public struct InAppPurchaseReviewScreenshot: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let iapId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetState?  // .isComplete, .hasFailed
}
```

For full domain reference see `Sources/Domain/Apps/InAppPurchases/` and `Sources/Domain/Apps/Subscriptions/`.

---

## File Map

```
Sources/Domain/Apps/
├── InAppPurchases/
│   ├── InAppPurchase.swift, InAppPurchaseRepository.swift
│   ├── InAppPurchaseSubmission.swift, InAppPurchaseSubmissionRepository.swift
│   ├── InAppPurchasePricePoint.swift, InAppPurchasePriceSchedule.swift, InAppPurchasePriceRepository.swift
│   ├── Localizations/InAppPurchaseLocalization.swift + Repository
│   ├── Availability/InAppPurchaseAvailability.swift + Repository
│   ├── OfferCodes/InAppPurchaseOfferCode.swift + Custom + OneTime + Price + Repository
│   └── Review/InAppPurchaseReviewScreenshot.swift (+ PromotionalImage) + Repository
└── Subscriptions/
    ├── SubscriptionGroup.swift + Repository
    ├── Subscription.swift + Repository
    ├── SubscriptionSubmission.swift + Repository
    ├── SubscriptionPricePoint.swift, SubscriptionPrice.swift, SubscriptionPriceRepository.swift
    ├── Localizations/Subscription[Group]Localization.swift + Repository
    ├── Availability/SubscriptionAvailability.swift + Repository
    ├── IntroductoryOffers/SubscriptionIntroductoryOffer.swift + Repository
    ├── PromotionalOffers/SubscriptionPromotionalOffer.swift + Price + Repository
    ├── WinBackOffers/WinBackOffer.swift (+ Price + Input) + Repository
    ├── OfferCodes/SubscriptionOfferCode.swift + Custom + OneTime + Price + Repository
    └── Review/SubscriptionReviewScreenshot.swift + Repository

Sources/Infrastructure/Apps/   # SDK adapters mirroring the Domain folder structure

Sources/ASCCommand/Commands/
├── IAP/, IAPLocalizations/, IAPOfferCodes/, IAPOfferCodeCustomCodes/, IAPOfferCodeOneTimeCodes/
├── IAPReviewScreenshot/, IAPImages/
├── SubscriptionGroups/, SubscriptionGroupLocalizations/
├── Subscriptions/, SubscriptionLocalizations/
├── SubscriptionOffers/ (intro), SubscriptionPromotionalOffers/, WinBackOffers/
├── SubscriptionOfferCodes/, SubscriptionOfferCodeCustomCodes/, SubscriptionOfferCodeOneTimeCodes/
├── SubscriptionReviewScreenshot/
└── Web/Controllers/IAP*Controller.swift, Subscription*Controller.swift, etc.
```

**Wiring:**
- `Sources/ASCCommand/ASC.swift` — registers every command group
- `Sources/ASCCommand/ClientProvider.swift` — static factory per repository
- `Sources/Infrastructure/Client/ClientFactory.swift` — auth → SDK repository instantiation
- `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` — wires controllers per repository

---

## Selected API Reference

| Command | SDK call |
|---------|----------|
| `iap update` | `APIEndpoint.v2.inAppPurchases.id(id).patch(InAppPurchaseV2UpdateRequest)` |
| `iap delete` | `APIEndpoint.v2.inAppPurchases.id(id).delete` |
| `iap unsubmit` | manual `Request<Void>(path: "/v1/inAppPurchaseSubmissions/{id}", method: "DELETE")` |
| `iap-localizations update` | `APIEndpoint.v1.inAppPurchaseLocalizations.id(id).patch(...)` |
| `iap-localizations delete` | `APIEndpoint.v1.inAppPurchaseLocalizations.id(id).delete` |
| `iap-offer-codes prices list` | `APIEndpoint.v1.inAppPurchaseOfferCodes.id(id).prices.get()` |
| `iap-offer-code-one-time-codes values` | `APIEndpoint.v1.inAppPurchaseOfferCodeOneTimeUseCodes.id(id).values.get` (`Request<String>`) |
| `iap-review-screenshot upload` | reserve `POST /v1/inAppPurchaseAppStoreReviewScreenshots` → upload chunks → commit `PATCH …/{id}` with MD5 |
| `iap-images list` | `APIEndpoint.v2.inAppPurchases.id(id).images.get()` |
| `subscriptions update` | `APIEndpoint.v1.subscriptions.id(id).patch(SubscriptionUpdateRequest)` |
| `subscriptions delete` | `APIEndpoint.v1.subscriptions.id(id).delete` |
| `subscriptions unsubmit` | manual `Request<Void>(path: "/v1/subscriptionSubmissions/{id}", method: "DELETE")` |
| `subscriptions price-points list` | `APIEndpoint.v1.subscriptions.id(id).pricePoints.get()` |
| `subscriptions prices set` | `APIEndpoint.v1.subscriptionPrices.post(SubscriptionPriceCreateRequest)` |
| `subscription-group-localizations *` | `APIEndpoint.v1.subscriptionGroupLocalizations.*` |
| `subscription-promotional-offers create` | `APIEndpoint.v1.subscriptionPromotionalOffers.post(...)` with `included` price create entries |
| `win-back-offers create` | manual `POST /v1/winBackOffers` with hand-encoded body (SDK lacks price relationships) |
| `win-back-offers update / delete` | `APIEndpoint.v1.winBackOffers.id(id).patch(...) / .delete` |
| `subscription-review-screenshot upload` | reserve → upload chunks → commit on `/v1/subscriptionAppStoreReviewScreenshots` |

---

## Testing

Each repository, command, and REST controller has its own test suite. Representative slices:

```swift
// Domain — state-aware affordance
@Test func `iap localization affordances include update with localization id`() {
    let loc = MockRepositoryFactory.makeInAppPurchaseLocalization(id: "loc-1", iapId: "iap-1")
    #expect(loc.affordances["update"] == "asc iap-localizations update --localization-id loc-1 --name <name>")
}

// Infrastructure — parent-id injection
@Test func `listPricePoints injects subscriptionId into each price point`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(SubscriptionPricePointsResponse(data: [...], links: .init(this: "")))
    let repo = SDKSubscriptionPriceRepository(client: stub)
    let result = try await repo.listPricePoints(subscriptionId: "sub-77", territory: nil)
    #expect(result.allSatisfy { $0.subscriptionId == "sub-77" })
}

// REST — _links shape
@Test func `subscription promotional offers REST exposes nested paths`() async throws {
    // …
    let output = try await SubscriptionPromotionalOffersList.parse([...])
        .execute(repo: mockRepo, affordanceMode: .rest)
    #expect(output.contains("/api/v1/subscriptions/sub-7/subscription-promotional-offers"))
    #expect(output.contains("/api/v1/subscription-promotional-offers/po-1/prices"))
}
```

Run targeted slices:

```bash
swift test --filter 'IAP|Subscription|WinBackOffer'
```

---

## Extending

Natural next steps not yet implemented:

- **IAP price schedule fetch with equalizations** — currently only `prices set` and `price-points list`. The full schedule fetch would parallel the AppStoreSdk-SPM `loadPriceSchedule()` flow.
- **Promotional offer / win-back offer territory-prices update** — only listing today; ASC API allows price replacement.
- **Promoted purchases** — see [`promoted-purchases.md`](promoted-purchases.md).
