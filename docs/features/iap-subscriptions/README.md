---
description: Manage in-app purchases and auto-renewable subscriptions end to end, from creation and pricing to offer codes, offers, review assets and submission. Use when setting up or changing anything a user can buy inside an app.
---

# In-App Purchases & Subscriptions

In-app purchases (consumable, non-consumable, non-renewing subscriptions) and auto-renewable subscriptions: lifecycle, pricing, offer codes, promotional and win-back offers, and review assets. Every flag: [iap](../../commands.md#asc-iap), [subscription-groups](../../commands.md#asc-subscription-groups), [subscriptions](../../commands.md#asc-subscriptions).

Most list/read commands and many writes are also served by `asc web-server` (subscription create/delete and intro-offer create are CLI-only). Affordances in the JSON output are state-aware: they only suggest the next legal action.

## Quick start
```bash
asc iap create --app-id <APP_ID> --reference-name "Gold Coins" --product-id com.app.goldcoins --type consumable
asc subscription-groups create --app-id <APP_ID> --reference-name "Premium"
asc subscriptions create --group-id <GROUP_ID> --name "Monthly" --product-id com.app.monthly --period ONE_MONTH
```

## Workflows
Each job has its own page in this folder:

| Page | Covers |
|----------|--------|
| [lifecycle.md](lifecycle.md) | IAP & subscription `update` / `delete` / `unsubmit`, plus subscription-group and introductory-offer lifecycle. |
| [pricing.md](pricing.md) | IAP base-territory pricing and subscription per-territory pricing (incl. `proceedsYear2`). |
| [offer-codes.md](offer-codes.md) | IAP & subscription offer codes: 3-level hierarchy, per-territory price listing, one-time-code redemption value fetch. |
| [group-localizations.md](group-localizations.md) | Per-locale display name and Custom App Name for subscription groups. |
| [promotional-offers.md](promotional-offers.md) | Subscription promotional offers with per-territory inline pricing. |
| [win-back-offers.md](win-back-offers.md) | Win-back offers with eligibility rules, priority, promotion intent, and per-territory pricing. |
| [review-assets.md](review-assets.md) | IAP review screenshots & 1024×1024 promotional images, subscription review screenshots (reserve → upload → commit-with-MD5). |
| [submission-iris-parity.md](submission-iris-parity.md) | Why first-time IAP submission goes through iris, and the subscription status. |

## REST
When `asc web-server` is running, every IAP and subscription from the list endpoints embeds a `_links` map, so an agent can fetch its details without knowing URL conventions.

| Resource | List endpoint | Embedded `_links` keys |
|----------|---------------|------------------------|
| `InAppPurchase` | `GET /api/v1/apps/:appId/iap` | `listLocalizations`, `listOfferCodes`, `listImages`, `listPricePoints`, `getAvailability`, `getReviewScreenshot`, `update`, `delete`, `submit` / `addToNextVersion` / `removeFromNextVersion` (see Gotchas), `createLocalization`, and more |
| `Subscription` | `GET /api/v1/subscription-groups/:groupId/subscriptions` | `listLocalizations`, `listIntroductoryOffers`, `listOfferCodes`, `listPromotionalOffers`, `listWinBackOffers`, `listPricePoints`, `getAvailability`, `getReviewScreenshot`, `update`, `delete`, `submit` (only when `READY_TO_SUBMIT`), `createLocalization`, `createIntroductoryOffer`, `createPromotionalOffer`, and more |

For an IAP with id `iap-7`:

| Link key | Method | URL |
|----------|--------|-----|
| `listLocalizations` | GET | `/api/v1/iap/iap-7/localizations` |
| `getAvailability` | GET | `/api/v1/iap/iap-7/availability` |
| `listOfferCodes` | GET | `/api/v1/iap/iap-7/offer-codes` |
| `listPricePoints` | GET | `/api/v1/iap/iap-7/price-points` |
| `getReviewScreenshot` | GET | `/api/v1/iap/iap-7/review-screenshot` |
| `listImages` | GET | `/api/v1/iap/iap-7/images` |

Subscriptions follow the same shape under `/api/v1/subscriptions/{id}/…` (`listIntroductoryOffers` → `/introductory-offers`).

## Gotchas
Affordances hide themselves when the action wouldn't succeed:
- `submit` appears on a subscription in `READY_TO_SUBMIT`. On an IAP it also needs the IAP not to be queued and not to be a first-time submission; otherwise a ready IAP gets `addToNextVersion`, or `removeFromNextVersion` once queued.
- A promotional image has no `delete` while it is pending review.
- A review screenshot still awaiting upload offers only `upload`, not `delete`.
- A subscription price point without a territory has no `setPrice`.
- Inactive custom codes and one-time-use codes have no `deactivate`.

Subscriptions show `multiSeatStatus` (`ENABLED`/`DISABLED`) and `marketSettings` (`APP_STORE`, `APPLE_SCHOOL`, `APPLE_BUSINESS`) only when App Store Connect sends them. Set them with `asc subscriptions update --multi-seat-status ENABLED --market-setting APP_STORE --market-setting APPLE_SCHOOL` or `PATCH /api/v1/subscriptions/:id` with `{"multiSeatStatus":"ENABLED","marketSetting":["APP_STORE"]}`. The markets you pass replace the current list. `create` can't set them: App Store Connect only accepts them on update.

## See also
[promoted-purchases](../promoted-purchases/README.md) · [iap-subscription-availability](../iap-subscription-availability/README.md) · [submit-with-products](../submit-with-products/README.md)
