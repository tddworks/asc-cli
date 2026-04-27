# Changelog

All notable changes to asc-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **HATEOAS `_links` for IAPs and Subscriptions** — `GET /api/v1/apps/{id}/iap` and `GET /api/v1/subscription-groups/{id}/subscriptions` now embed `_links` per item so an agent can navigate to localizations, availability, offer codes, price points, review screenshots, promotional offers, win-back offers (subscriptions only), and intro offers without knowing the URL conventions.
- **REST controllers for IAP details** — `GET /api/v1/iap/:id/localizations`, `/availability`, `/offer-codes`, `/price-points`. Each returns the agent-first `data: [...]` envelope with `_links` already populated.
- **REST controllers for Subscription details** — `GET /api/v1/subscriptions/:id/localizations`, `/availability`, `/offer-codes`, `/introductory-offers`.
- **`InAppPurchasePriceSchedule` enriched with `baseTerritory` + `territoryPrices`** — `GET /api/v1/iap/:id/price-schedule` now returns the developer-set base territory plus all auto-equalized per-territory prices (currency + customerPrice + proceeds) so the iOS Pricing tab has data to render. Composes three ASC API calls under the hood: schedule (with base territory), manual prices, and equalizations.
- **IAP equalizations primitive** — `asc iap-equalizations list --price-point-id <id> [--limit N]` and `GET /api/v1/iap-price-points/:id/equalizations`. Exposes `GET /v1/inAppPurchasePricePoints/{id}/equalizations` (~175 territory prices auto-derived from a manual base price).
- **Subscription price schedule** — new `SubscriptionPriceSchedule` domain type with `territoryPrices` and `price(for:)` lookup (no base territory — subscriptions are per-territory). `asc subscription-price-schedule get --subscription-id <id>` and `GET /api/v1/subscriptions/:id/price-schedule`. Composes `GET /v1/subscriptions/{id}/prices` + equalizations.
- **Subscription equalizations primitive** — `asc subscription-equalizations list --price-point-id <id>` and `GET /api/v1/subscription-price-points/:id/equalizations`.
- **Multi-territory subscription `setPrices` (batch)** — `asc subscriptions prices set-batch --subscription-id <id> --price USA=spp-1 --price JPN=spp-2 ...`. Mirrors iOS `setPrices(prices:)`. Returns the post-write schedule.
- **Subscription promotional images** — `asc subscription-images list|upload|delete` and `GET /api/v1/subscriptions/:id/images`. New `SubscriptionPromotionalImage` domain type with `delete` suppression while `state.isPendingReview` (mirrors IAP images).
- **`asc subscriptions update --period <PERIOD>`** — change billing period (ONE_WEEK, ONE_MONTH, …, ONE_YEAR) on an existing subscription. Mirrors the iOS app's `subscription.update(subscriptionPeriod:)`.

### Fixed
- **IAP/Subscription availability returned only ~10 territories instead of all ~175** — the parent endpoint's `include=availableTerritories` truncates the relationship to a single page. `getAvailability` now issues two parallel calls (attributes + dedicated `/availableTerritories?limit=200`) so the full territory list reaches the frontend's Availability tab. Matches the iOS SDK's `fetchAvailability` composition.
- **`SubscriptionGroup._links` was empty** — `GET /api/v1/apps/{id}/subscription-groups` items now embed populated `_links` for `listSubscriptions`, `listLocalizations`, `createSubscription`, `createLocalization`, `update`, `delete`. Migrated `SubscriptionGroup` from raw `affordances` to `structuredAffordances` so `apiLinks` auto-derives, and registered `_subscriptionGroupLocalizationRoutes` in `RESTPathResolver.ensureInitialized` so the nested localizations path resolves.
- **`/api/v1/subscription-groups/{id}/subscriptions` returned 404** — the `_links.listSubscriptions` URL had no controller. Added `SubscriptionsController` and wired it in `RESTRoutes.swift`. Each subscription's `_links` already advertise the full child surface (localizations, availability, price-schedule, offers, etc.).
- **Review screenshots and promotional images returned no image URL** — the responses included `id`/`fileName`/`fileSize`/`assetState` but nothing renderable. Added `imageAsset: ImageAsset?` to `SubscriptionReviewScreenshot`, `InAppPurchaseReviewScreenshot`, `SubscriptionPromotionalImage`, `InAppPurchasePromotionalImage` — populated from the SDK's `attributes.imageAsset` (templateUrl + width + height). Frontend calls `imageAsset.url(maxSize:format:)` to substitute the `{w}/{h}/{f}` placeholders and produce a real CDN URL.
- **`SubscriptionPrice._links` was empty** — migrated `SubscriptionPrice` from raw `affordances` to `structuredAffordances` so `apiLinks` auto-derives. `listPricePoints` now resolves to `/api/v1/subscriptions/{id}/price-points` over REST.
- **`POST /api/v1/apps/{id}/iap` returned 404** — the route wasn't registered. `IAPController` now serves `POST` (create — accepts `referenceName`, `productId`, and `inAppPurchaseType` in either CLI-style `non-consumable` or raw enum `NON_CONSUMABLE`), `PATCH /iap/{id}` (update), and `DELETE /iap/{id}`. Mirrors `VersionsController`'s POST/PATCH conventions.
- **`POST /api/v1/apps/{id}/subscription-groups` returned 404** — same fix for subscription groups. `SubscriptionGroupsController` now serves `POST` (create — `referenceName`), `PATCH /subscription-groups/{id}` (rename), and `DELETE /subscription-groups/{id}`.
- **`GET /api/v1/iap/{id}/availability` returned 500 for newly-created IAPs** — ASC returns 404 until the developer creates the availability resource. `getAvailability(iapId:)` and `getAvailability(subscriptionId:)` now return `Optional` and tolerate the 404 by returning nil; controllers wrap nil into an empty `data: []` array. Mirrors the iOS SDK's `refreshTerritoryStatuses` 404 tolerance — frontends treat empty as "no availability set yet" and seed sensible defaults.

### Changed
- **`RESTPathResolver` resolves singleton-under-parent `get` to nested path** — when an action is not `list`/`create`, the singularized own-id is missing, and a registered route's parent param matches one in `params`, the resolver now returns the nested `/parent/{id}/segment` path. This corrects `_links.getReviewScreenshot` for IAP and Subscription (was `/api/v1/iap-review-screenshot/{id}` → now `/api/v1/iap/{id}/review-screenshot`) and similar singletons (availability, age-rating).
- **`AgeRatingController`** now serves the canonical nested path `/api/v1/app-infos/{appInfoId}/age-rating` matching the resolver's `_links`. The flat `/api/v1/age-rating/{id}` remains for back-compat.

---

## [0.17.3] - 2026-04-26

### Added
- **State-aware affordances on the new aggregates** — affordances no longer suggest illegal next actions:
  - `PromotedPurchase` exposes `state.isLocked` (true while `WAITING_FOR_REVIEW` / `IN_REVIEW`); `update` and `delete` are suppressed while locked, so an agent following affordances won't issue a 409 against App Review.
  - `InAppPurchasePromotionalImage` suppresses `delete` while `state.isPendingReview` is true.
  - `InAppPurchaseReviewScreenshot.AssetState` and `SubscriptionReviewScreenshot.AssetState` gain `isComplete` / `hasFailed` semantic booleans. `delete` is offered once the asset is reachable (`uploadComplete` / `complete` / `failed`); while `awaitingUpload`, only `upload` is offered as the recovery path.
- **IAP & Subscription review screenshots + IAP promotional images** — closes the upload-heavy feature parity gap. New CLI commands implement the standard ASC reserve → upload chunks → commit-with-MD5 protocol on top of `URLSession`:
  - `asc iap-review-screenshot get|upload|delete` — single review screenshot per IAP. `get` returns an empty `data: []` array when no screenshot is present, mirroring CAEOAS conventions.
  - `asc iap-images list|upload|delete` — 1024×1024 promotional images for an IAP, with state semantic booleans (`isApproved`, `isPendingReview`).
  - `asc subscription-review-screenshot get|upload|delete` — single review screenshot per subscription.
  - New domain types: `InAppPurchaseReviewScreenshot`, `InAppPurchasePromotionalImage` (with `ImageState` enum), `SubscriptionReviewScreenshot`. New repository protocols `InAppPurchaseReviewRepository` + `SubscriptionReviewRepository`, both `@Mockable`.
  - `InAppPurchase` now advertises `getReviewScreenshot` + `listImages`; `Subscription` advertises `getReviewScreenshot`.
- **Promoted purchases** — App Store product page promoted slot CRUD. New CLI commands under `asc promoted-purchases`:
  - `list --app-id <id>`, `create --app-id <id> (--iap-id <id> | --subscription-id <id>) [--visible|--hidden] [--enabled|--disabled]`, `update --promoted-id <id> ...`, `delete --promoted-id <id>`.
  - New `PromotedPurchase` domain type carrying `appId` + either `inAppPurchaseId` or `subscriptionId` (mutually exclusive at create time, validated in the command). State enum `PromotedPurchaseState` with raw values matching ASC plus `isLocked` / `isApproved` semantic booleans.
  - Backed by `GET/POST /v1/apps/{id}/promotedPurchases` and `PATCH/DELETE /v1/promotedPurchases/{id}`.
- **Win-back offers** — full CRUD with eligibility rules, priority, promotion intent, and per-territory pricing. New CLI command tree under `asc win-back-offers`:
  - `list --subscription-id <id>`, `delete --offer-id <id>`, `update --offer-id <id> [--priority HIGH|NORMAL] [--start-date ...] [--end-date ...] [--paid-months n] [--since-min n] [--since-max n] [--wait-months n] [--promotion-intent ...]`, `prices list --offer-id <id>`.
  - `create --subscription-id <id> --reference-name <name> --offer-id <id> --duration <d> --mode <m> --periods <n> --paid-months <n> --since-min <n> --since-max <n> --start-date <YYYY-MM-DD> --priority HIGH|NORMAL [--end-date ...] [--wait-months n] [--promotion-intent ...] [--price USA=spp-1 --price GBR=spp-2 ...]` — bypasses the generated SDK's incomplete `WinBackOfferPriceInlineCreate` (missing relationships) by encoding the body manually with type-erased `AnyCodable`.
  - Domain types: `WinBackOffer` (with `customerEligibilityTimeSinceLastSubscribed` min/max, `WinBackOfferPriority`, `WinBackOfferPromotionIntent`), `WinBackOfferPrice`, `WinBackOfferPriceInput`. `Subscription` advertises `listWinBackOffers`.
- **Subscription promotional offers** — CRUD plus per-territory inline price creation. New CLI commands under `asc subscription-promotional-offers`:
  - `list --subscription-id <id>`, `delete --offer-id <id>`, `prices list --offer-id <id>`.
  - `create --subscription-id <id> --name <name> --offer-code <code> --duration <d> --mode <m> --periods <n> [--price USA=spp-1 ...]` — uses `${newPromoOfferPrice-N}` 1-based local IDs in the `included` array, matching the ASC web UI request shape.
  - Domain types: `SubscriptionPromotionalOffer`, `SubscriptionPromotionalOfferPrice`, shared `PromotionalOfferPriceInput`. `Subscription` advertises `createPromotionalOffer` + `listPromotionalOffers`.
- **Subscription group localizations** — per-locale display name and Custom App Name for a subscription group. New CLI command tree under `asc subscription-group-localizations`:
  - `list --group-id <id>`, `create --group-id <id> --locale <code> --name <name> [--custom-app-name <name>]`, `update --localization-id <id> [--name <name>] [--custom-app-name <name>]`, and `delete --localization-id <id>`.
  - New `SubscriptionGroupLocalization` domain type ({id, groupId, locale, name?, customAppName?, state?}) with `listSiblings`/`update`/`delete` affordances. New `SubscriptionGroupLocalizationRepository` `@Mockable` protocol, SDK adapter on `/v1/subscriptionGroupLocalizations`.
  - `SubscriptionGroup` now advertises `createLocalization`/`listLocalizations` so an agent navigating from a group can discover the localization tree.
- **Offer code prices + one-time code values** — completes the offer-code feature so an agent can read back per-territory pricing and download distributable redemption codes:
  - `asc iap-offer-codes prices list --offer-code-id <id>` and `asc subscription-offer-codes prices list --offer-code-id <id>` — returns each price with `territory` and `pricePointId` (IAP) or `subscriptionPricePointId` (Subscription). Backed by `GET /v1/inAppPurchaseOfferCodes/{id}/prices` and `GET /v1/subscriptionOfferCodes/{id}/prices`.
  - `asc iap-offer-code-one-time-codes values --one-time-code-id <id>` and `asc subscription-offer-code-one-time-codes values --one-time-code-id <id>` — fetches the raw CSV body of one-time-use redemption codes for distribution. Backed by `GET /v1/.../oneTimeUseCodes/{id}/values` (`Request<String>`).
  - Two new domain types: `InAppPurchaseOfferCodePrice { id, offerCodeId, territory?, pricePointId? }` and `SubscriptionOfferCodePrice { id, offerCodeId, territory?, subscriptionPricePointId? }`. Each advertises a `listPrices` affordance that points back at its parent offer code.
  - Repository protocols extended with `listPrices(offerCodeId:)` and `fetchOneTimeUseCodeValues(oneTimeCodeId:) -> String`; SDK adapters implement them on top of the appstoreconnect-swift-sdk.
- **Subscription pricing parity** — subscriptions now match IAP for browsing tiers and committing per-territory prices. Subscriptions don't have a base territory (Apple auto-equalizes), so the model has `proceedsYear2` and `prices set` is per-territory rather than per-base. New CLI commands (mirrored under `asc subscriptions`):
  - `asc subscriptions price-points list --subscription-id <id> [--territory <code>]` — list `SubscriptionPricePoint`s with optional territory filter. Each result advertises `setPrice` only when a territory is attached.
  - `asc subscriptions prices set --subscription-id <id> --territory <code> --price-point-id <id> [--start-date YYYY-MM-DD] [--preserve-current-price]` — POST `/v1/subscriptionPrices` to commit a price.
  - New domain models: `SubscriptionPricePoint` (id, subscriptionId, territory, customerPrice, proceeds, **proceedsYear2**) and `SubscriptionPrice` (id, subscriptionId).
  - New `SubscriptionPriceRepository` `@Mockable` protocol with `listPricePoints` + `setPrice`; SDK adapter wires `GET /v1/subscriptions/{id}/pricePoints` and `POST /v1/subscriptionPrices`.
- **IAP & Subscription lifecycle parity** — symmetric update/delete/unsubmit across the in-app-purchase and subscription aggregates so an agent can drive the full lifecycle, not just create-then-submit. New CLI commands:
  - `asc iap-localizations update --localization-id <id> [--name <name>] [--description <desc>]` and `asc iap-localizations delete --localization-id <id>`.
  - `asc subscription-localizations update --localization-id <id> [--name <name>] [--description <desc>]` and `asc subscription-localizations delete --localization-id <id>`.
  - `asc iap update --iap-id <id> [--reference-name <name>] [--review-note <note>] [--family-sharable | --not-family-sharable]`, `asc iap delete --iap-id <id>`, and `asc iap unsubmit --submission-id <id>` (the SDK lacks a generated DELETE, so it goes through a manual `Request<Void>`).
  - `asc subscriptions update --subscription-id <id> [--name <name>] [--family-sharable | --not-family-sharable] [--group-level <n>] [--review-note <note>]`, `asc subscriptions delete --subscription-id <id>`, and `asc subscriptions unsubmit --submission-id <id>` (manual DELETE same as IAP).
  - `asc subscription-groups update --group-id <id> --reference-name <name>` and `asc subscription-groups delete --group-id <id>`.
  - `asc subscription-offers delete --offer-id <id>` to drop an introductory offer.
- Affordance updates so the new commands surface in the JSON output of every list/create/submit response: `InAppPurchase` now advertises `update`/`delete`, `Subscription` advertises `update`/`delete`, `SubscriptionGroup` advertises `update`/`delete`, both localization models advertise `update`/`delete`, both submission models advertise `unsubmit`, and `SubscriptionIntroductoryOffer` advertises `delete`.

---

## [0.17.2] - 2026-04-25

### Added
- **Plugin update workflow (Sparkle-style)** — check for and apply plugin updates via CLI or REST:
  - `asc plugins updates` (CLI) and `GET /api/v1/plugins/updates` (REST) — list every installed plugin where the marketplace has a newer version. Each entry is a `PluginUpdate { name, installedVersion, latestVersion, repositoryURL?, downloadURL? }` with affordances pointing at `asc plugins update --name X` (CLI) and `POST /api/v1/plugins/:name/update` (REST).
  - `asc plugins update --name X` (CLI) and `POST /api/v1/plugins/:name/update` (REST) — uninstall the named plugin and reinstall the latest marketplace version. Returns the freshly installed `Plugin`.
  - `Plugin.affordances` adds `checkUpdate → asc plugins updates` for installed plugins so frontends can wire a "Check for updates" entry without hard-coding the path.
  - New `PluginRepository.listOutdated()` and `update(name:)` methods on the repository protocol; implemented in `PluginMarketRepository` by zipping `listInstalled()` with `listAvailable()` on `name`.
- **Plugins REST install/uninstall/search** — `PluginsController` now mirrors the full `asc plugins` CLI:
  - `POST /api/v1/plugins` — install a plugin from the marketplace. Body: `{ "name": "Hello.plugin" }`. Returns the installed `Plugin` with `isInstalled: true`.
  - `DELETE /api/v1/plugins/:name` — uninstall by name (or slug). Returns `204 No Content`.
  - `GET /api/v1/plugins/market?q=<query>` — search the marketplace. Without `q`, behaves like the existing list. With `q`, calls `PluginRepository.searchAvailable`. Same response shape as `GET /api/v1/plugins/market`.
  - These endpoints back the install/uninstall/search affordances already advertised on `Plugin.affordances` — frontends following affordances no longer hit a 404.
- **Auth REST endpoints** — `asc auth` is now drivable from a web client. New `AuthController` exposes:
  - `POST /api/v1/auth/accounts` (login) — body `{ keyId, issuerId, privateKeyPEM, name?, vendorNumber? }`. Saves to `~/.asc/credentials.json` and marks active. Returns the new `AuthStatus`.
  - `GET /api/v1/auth/accounts` (list) — returns all saved `ConnectAccount` records.
  - `GET /api/v1/auth/accounts/active` (check) — returns the active account's `AuthStatus`.
  - `PATCH /api/v1/auth/accounts/active` (use) — body `{ name }` switches the active account, returns updated `AuthStatus`.
  - `PATCH /api/v1/auth/accounts/:name` (update) — body `{ vendorNumber }` updates a stored account.
  - `DELETE /api/v1/auth/accounts/active` and `DELETE /api/v1/auth/accounts/:name` (logout) — return `204 No Content`.
  - **Security:** the controller writes API key PEMs to disk via `AuthStorage`. Run `asc web-server` bound to loopback only when this controller is enabled; the request body is sensitive.
  - `AuthStatus` and `ConnectAccount` now conform to `Presentable` so REST responses share the `{"data":[…]}` shape used elsewhere.

---

## [0.17.1] - 2026-04-24

### Added
- **`createVersion` affordance on `App`** — every app response now advertises `asc versions create --app-id <id>` (REST: `POST /api/v1/apps/{appId}/versions`). Frontends driven by affordances (e.g. the command center UI) can use the presence of this key to enable a "Create Version" action without hard-coding capabilities.
- **`updateVersion` affordance on editable `AppStoreVersion`** — versions in `prepareForSubmission` state expose `asc versions update --version-id <id>` (REST: `PATCH /api/v1/versions/{id}`). Live and pending versions omit it, giving the UI a state-aware signal for the edit dialog.
- **`asc versions update --version-id <id> --version <string>`** — new CLI command to update an existing App Store version's version string. Backed by new `VersionRepository.updateVersion(id:versionString:)` which maps to the ASC SDK `AppStoreVersionUpdateRequest`.
- **`POST /api/v1/apps/{appId}/versions`** and **`PATCH /api/v1/versions/{versionId}`** — REST endpoints for version create/update on `VersionsController`. Request body: `{ "versionString": "...", "platform": "IOS" }` for create, `{ "versionString": "..." }` for update.
- **`createLocalization` affordance on `AppInfo`** — every app-info response now advertises the locale-add endpoint. Unblocks the frontend's "+ Add Locale" button, which previously had no link to POST against.
- **`POST /api/v1/app-infos/{appInfoId}/localizations`** — create an `AppInfoLocalization` via REST. Body: `{ "locale": "fr-FR", "name": "..." }`. Returns the new row with its `_links` (`updateLocalization`, `delete`, `listLocalizations`).
- **`PATCH /api/v1/app-info-localizations/{localizationId}`** — update `name`, `subtitle`, `privacyPolicyUrl`, `privacyChoicesUrl`, `privacyPolicyText`. Missing keys mean "don't change"; sending an empty string clears the field. Fixes the `404` the frontend was seeing when saving per-locale name / subtitle / privacy URLs.
- **`DELETE /api/v1/app-info-localizations/{localizationId}`** — delete a locale, returns `204 No Content`. Backs the "trash" button on the localization row.
- **`App.contentRightsDeclaration` + `ContentRightsDeclaration` enum** — apps now carry the third-party-content declaration (`USES_THIRD_PARTY_CONTENT` / `DOES_NOT_USE_THIRD_PARTY_CONTENT`). Field is optional and omitted from JSON when unset. This is the ASC-accurate mapping — the declaration lives on `App`, not on `AppInfo`.
- **`asc apps update --app-id <id> --content-rights-declaration <value>`** + **`PATCH /api/v1/apps/{appId}`** — update content rights declaration via CLI or REST. Backed by new `AppRepository.updateContentRights(appId:declaration:)` which maps to the ASC SDK `AppUpdateRequest`.
- **`updateContentRights` affordance on `App`** — every app response advertises the new PATCH endpoint so frontends can wire the declaration switch without hard-coding the URL.
- **`PATCH /api/v1/age-rating/{declarationId}`** — update an age rating declaration via REST. Body accepts any subset of the `AgeRatingDeclarationUpdate` fields (boolean flags, `ContentIntensity` values, `kidsAgeBand`, `ageRatingOverride`, `koreaAgeRatingOverride`). Fixes the `404` the frontend was seeing when following the `update` `_link` on an `AgeRatingDeclaration` response. Matches the affordance key already advertised by `AgeRatingDeclaration.structuredAffordances`.

---

## [0.17.0] - 2026-04-21

### Added
- **`GET /api/v1/apps?include=icon`** — enriches each app in the response with its primary build's `iconAsset` (`templateUrl`, `width`, `height`). Icon fetch is opt-in to keep the default list-apps path fast. Without `?include=icon`, behaviour is unchanged. Template URL placeholders (`{w}`, `{h}`, `{f}`) can be substituted client-side to render at any size (e.g. `120x120bb.png`).
- **Domain types `ImageAsset`, `App.iconAsset`** — new optional `iconAsset` on `App` (omitted from JSON when nil), new `ImageAsset` value type under `Domain/Shared/` with `url(maxSize:format:)` helper. Populated from SDK `Build.iconAssetToken` via `/v1/apps/{id}/appStoreVersions?include=build`
- **`AppRepository.fetchAppIcon(appId:)`** — returns `ImageAsset?` by joining the latest app version to its build. Returns `nil` when no version has an attached build
- **`GET /api/v1/apps/{appId}/app-infos`** — new REST route backed by `AppInfoRepository`. Previously the affordance on `App` advertised this path but the controller returned 404. `AppInfo` is now `Presentable` and uses `structuredAffordances`, so responses include `_links` to app-info localizations, age rating, and the enclosing app-infos list
- **`AppInfo.appStoreState` / `AppInfo.state`** — app-infos responses now include lifecycle fields (`appStoreState` uses legacy ASC version states like `READY_FOR_SALE`; `state` uses the newer `AppInfo.State` enum like `READY_FOR_DISTRIBUTION`, `PREPARE_FOR_SUBMISSION`). Agents can use these to pick the live-version app-info vs the version-being-prepared. Computed booleans `isLive` and `isEditable` expose the common decisions
- **`AppInfo.appStoreAgeRating`** — computed App Store age rating (e.g. `FOUR_PLUS`, `NINE_PLUS`, `TWELVE_PLUS`, `SEVENTEEN_PLUS`) now surfaced on app-infos responses. This is what the App Store listing page displays; cheaper than fetching the full `ageRatingDeclaration` when only the label is needed
- **`asc app-categories get --category-id <id>`** + **`GET /api/v1/app-categories/{id}`** — fetch a single App Store category by ID. `AppInfo` responses now include `getPrimaryCategory`, `getSecondaryCategory`, and four subcategory affordances (conditional on the respective ID being set), each pointing at the new endpoint. Backed by new `AppCategoryRepository.getCategory(id:)`
- **`GET /api/v1/app-categories`** — list categories exposed at the REST layer (previously CLI-only). Optional `?platform=` query param mirrors the CLI flag
- **`GET /api/v1/app-infos/{appInfoId}/localizations`** — new REST route backed by `AppInfoRepository.listLocalizations`. `AppInfoLocalization` is now `Presentable` with `structuredAffordances` including update/delete links
- **Unified REST path resolver** — removed the global `{param → segment}` alias table from `RESTPathResolver`. New single rule: for resource actions (get/update/delete/submit/…), the command name IS the REST segment. CLI flag aliases (e.g. `--localization-id`, `--product-id`) are presentation concerns and no longer drive REST routing. Fixes ambiguity where the same CLI flag belonged to multiple resources
- **`GET /api/v1/age-rating/{appInfoId}`** — fetch the age rating declaration for an app-info. Previously only `asc age-rating get` worked; the REST route was advertised via `_links.getAgeRating` but returned 404. `AgeRatingDeclaration` is now `Presentable` with `structuredAffordances`
- **`PATCH /api/v1/app-infos/{appInfoId}`** — update app-info categories (primary, secondary, up to two subcategories each) via REST. JSON body accepts `primaryCategoryId`, `primarySubcategoryOneId`, `primarySubcategoryTwoId`, `secondaryCategoryId`, `secondarySubcategoryOneId`, `secondarySubcategoryTwoId` — any subset. Returns the updated `AppInfo` with `_links` that now include `getPrimaryCategory` / `getSecondaryCategory` pointing at the new values
- **`GET /api/v1/version-localizations/{localizationId}/screenshot-sets`** and **`GET /api/v1/screenshot-sets/{setId}/screenshots`** — screenshot-related `_links` on `AppStoreVersionLocalization` and `AppScreenshotSet` responses now resolve to working REST endpoints. `AppStoreVersionLocalization`, `AppScreenshotSet`, and `AppScreenshot` now use `structuredAffordances` (replacing raw `affordances`); the latter two also gained `Presentable` conformance

### Changed
- **REST controllers split by resource (SRP/OCP refactor)** — the former `AppsController` was a god controller accumulating 15+ routes across 8 unrelated resources (apps, versions, localizations, screenshot-sets, screenshots, builds, testflight, reviews, iap, subscription-groups, app-infos, app-info-localizations, app-categories, age-rating). Now split into 13 focused controllers, one per REST resource type — `AppsController`, `VersionsController`, `VersionLocalizationsController`, `ScreenshotSetsController`, `ScreenshotsController`, `BuildsController`, `TestFlightController`, `CustomerReviewsController`, `IAPController`, `SubscriptionGroupsController`, `AppInfosController`, `AppCategoriesController`, `AgeRatingController`. Each takes only the 1–2 repositories it actually needs. `RESTRoutes.configure` composes them with one line per resource. Adding a new resource no longer requires editing an existing controller

### Fixed
- **`RESTPathResolver.ensureInitialized` race** — the `initialized` flag was being set *before* the domain route registrations ran, so concurrent callers could observe `initialized == true` while the `routes` dictionary was still empty. Now uses a separate `initLock` and sets the flag only after all `_*Routes` registrations complete. Fixes intermittent test failures where screenshot/localization `_links` resolved to top-level paths under parallel test execution
- **`include=primaryCategory,…` on app-infos request** — added to `SDKAppInfoRepository.listAppInfos` alongside `fields[appInfos]`. The ASC API returns only relationship `links` with `fields[]` alone; `include=` is required to populate `relationships.primaryCategory.data.id` so the mapper can surface `primaryCategoryId` etc.

### Fixed
- **`AppInfo.primaryCategoryId` / secondary categories missing from `/v1/apps/{id}/appInfos`** — the ASC API returns relationship `data` sparsely unless the client requests the explicit sparse fieldset. `SDKAppInfoRepository.listAppInfos` now passes `fields[appInfos]=primaryCategory,primarySubcategoryOne,primarySubcategoryTwo,secondaryCategory,secondarySubcategoryOne,secondarySubcategoryTwo`, so the mapped `AppInfo` carries the category IDs

---

## [0.16.9] - 2026-04-20

### Added
- **`asc review-submissions list`** — list App Store review submissions for an app. Required `--app-id`; optional `--state <CSV>` (e.g. `WAITING_FOR_REVIEW,IN_REVIEW,READY_FOR_REVIEW` or `UNRESOLVED_ISSUES`) and `--limit`. Backed by `SubmissionRepository.listSubmissions(appId:states:limit:)`
- **`asc certificates list` filtering flags** — `--limit` (server-side), `--expired-only` (client-side, drops unexpired certs), `--before <ISO8601>` (client-side, keeps certs with expirationDate strictly before the cutoff)
- **REST endpoint `GET /api/v1/apps/{appId}/review-submissions`** — new `ReviewSubmissionsController` in the `asc web-server`. Supports `?state=…&limit=…` query params; mirrors the CLI. **No fleet route** — Apple's OpenAPI spec marks `filter[app]` as required, so review submissions can only be listed per-app
- **REST endpoint `GET /api/v1/certificates` query params** — now honours `?type=&limit=&expired-only=&before=` (previously ignored). `before` accepts both full ISO8601 (`2026-11-01T00:00:00Z`) and date-only (`2026-11-01`, interpreted as midnight UTC). Same filter semantics as the CLI
- **REST endpoint `GET /api/v1/builds`** — fleet listing with optional `?app-id=&platform=&version=&limit=` query params. `/api/v1/apps/{appId}/builds` still works for the nested form

### Changed
- **`CertificateRepository.listCertificates`** signature now takes `(certificateType:limit:)` — forwards `limit` to the SDK
- **`ReviewSubmission` REST links** — affordance migrated from raw `affordances` dictionary to `structuredAffordances`, so REST responses now render `_links` correctly (e.g. `/api/v1/apps/{appId}/versions`)

---

## [0.1.68] - 2026-04-14

### Added
- **`asc testflight groups create`** — create external or internal TestFlight beta groups (`--internal` flag toggles internal; `--public-link-enabled` / `--feedback-enabled` for external groups)
- **`asc init` review contact flags** — `--contact-first-name`, `--contact-last-name`, `--contact-phone`, `--contact-email` save review contact info to `.asc/project.json` for reuse across versions
- **`ProjectConfig` review contact fields** — optional `contactFirstName`, `contactLastName`, `contactPhone`, `contactEmail` with `hasReviewContact` computed property
- **`setReviewContact` / `updateReviewContact` affordances** — `ProjectConfig` now suggests setting review contact when missing

---

## [0.1.67] - 2026-04-13

### Changed
- Bug fixes and improvements.

---

## [0.1.66] - 2026-04-09

### Added
- **`ThemeDesign` domain model** — composes from Gallery-native types (`GalleryPalette` + `[Decoration]`) for structured theme output. Generated by AI once, applied deterministically to all screenshots
- **`ThemeDesignApplier`** — re-renders through `GalleryHTMLRenderer.renderScreen()` pipeline with overridden palette and merged decorations (no HTML patching)
- **`GalleryPalette.textColor`** — optional explicit text color, overrides the auto-detect heuristic
- **`Decoration.label()` shape** — text/emoji decorative elements (e.g. `Decoration(shape: .label("✨"), ...)`)
- **`DecorationAnimation`** — float, drift, pulse, spin, twinkle animations for decorations
- **`ScreenLayout.withDecorations()`** — creates a copy with additional decorations
- **`GalleryHTMLRenderer.renderDecorations()`** — renders `ScreenLayout.decorations` (previously dead code) using `cqi` units
- **`buildDesignContext()` on `ScreenTheme`** — prompt method that instructs AI to return `ThemeDesign` JSON
- **`design()` on `ThemeProvider`/`ThemeRepository`** — generate a ThemeDesign from AI in one call
- **`--design-only` / `--apply-design` CLI flags** — batch theme workflow
- **REST endpoints** — `POST /app-shots/themes/design` and `POST /app-shots/themes/apply-design`

### Changed
- **`GalleryHTMLRenderer` refactored to Mustache templates** — all HTML extracted from Swift into 7 `.mustache` template files using [swift-mustache](https://github.com/hummingbird-project/swift-mustache). The renderer only builds context dictionaries; all HTML, CSS colors (via CSS custom properties in `theme-vars.mustache`), and keyframe animations live in templates. Templates are pre-compiled at startup via `MustacheLibrary` for performance. Preview rendering is cached per template ID.
- **`DecorationShape.displayCharacter`** — computed property on the model instead of renderer logic
- **`GalleryPalette.isLight` + `headlineColor`** — theme detection and text color derivation moved from renderer to palette
- **`Decoration` extended** — new optional fields: `color`, `background`, `borderRadius`, `animation`
- **Theme selection no longer requires auto-compose** — clicking a theme applies immediately to slides with existing preview HTML via `ThemeDesign` (1 AI call for design, then deterministic apply to all slides)
- **Blitz plugin: `design()` implemented** — generates `ThemeDesign` via compose bridge `mode: "design"`, enabling the fast design→apply-design flow

---

## [0.1.65] - 2026-04-06

### Changed
- **`Presentable` protocol** — domain models own their table headers and row values; eliminates `headers:`/`rowMapper:` boilerplate from 37 list commands
- **REST controllers with DI** — routes rewritten as controller structs (`AppsController`, `CodeSigningController`, etc.) with injected repo dependencies; repos created once at server startup, not per request
- **No more `Command.parse([])` in REST layer** — controllers call domain repos and operations directly; CLI and REST are equal thin adapters
- **`AffordanceRegistry` uses structured `Affordance`** — plugin affordances now render to both CLI commands and REST `_links` (previously CLI-only)
- **`ScreenshotTemplate` domain operations** — `apply(content:)`, `renderFragment(content:)` as rich domain methods; `ThemedPage` value type for page wrapping
- **`ScreenshotTemplate` Codable includes `previewHTML` and `deviceCount`** — REST consumers get preview data without special handling

---

## [0.1.64] - 2026-04-05

### Added
- **REST API with HATEOAS** — `GET /api/v1` entry point plus 12 resource endpoints (apps, versions, builds, testflight, certificates, bundle-ids, devices, profiles, simulators, plugins, territories) calling domain repositories directly (in-process, no subprocess), returning JSON with `_links` for agent navigation
- **`APIRoot` model** — HATEOAS entry point at `GET /api/v1` listing all available top-level resources with navigable `_links`
- **Structured `Affordance` type** — single source of truth for both CLI commands and REST links; models define affordances once, rendered to either format by `OutputFormatter`
- **`APILink` and `AffordanceMode`** — domain types supporting dual-mode affordance rendering (`.cli` → `"affordances"`, `.rest` → `"_links"`)
- **`RESTPathResolver`** — resolves CLI command + params into REST API paths using a route table covering 35+ resource types across the full domain hierarchy
- **HTML-to-PNG export** — `--preview image` option on `asc app-shots templates apply` and `asc app-shots themes apply` renders composed HTML to PNG via WebKit, with `--image-output` for custom output path
- **`HTMLRenderer` protocol** — `@Mockable` domain protocol for HTML-to-image rendering, implemented by `WebKitHTMLRenderer` using WKWebView snapshot

---

## [0.1.63] - 2026-04-02

### Added
- **Plugin Marketplace** — `asc plugins market list` and `asc plugins market search --query X` to browse and search plugins from [tddworks/asc-registry](https://github.com/tddworks/asc-registry)
- **Multi-source plugin registry** — `PluginSource` protocol with `GitHubPluginSource` implementation; composable sources in `PluginMarketRepository`
- **`asc plugins install --name X`** — download and install `.plugin` bundles from the marketplace
- **`asc plugins uninstall --name X`** — remove installed plugin bundles (matches by slug or registry ID)
- **Plugins page in Command Center** — web UI with Installed and Marketplace tabs, stats bar, install/uninstall with loading spinners
- **Enriched plugin manifest** — `manifest.json` now supports `description`, `author`, `repositoryURL`, `categories`; installed plugins display the same rich info as marketplace listings
- **Centralized plugin affordance merging** — `AffordanceRegistry` affordances merged automatically in `OutputFormatter` via `WithPluginAffordances`; domain models no longer need manual registry calls
- **Example plugin** — `examples/hello-plugin/` demonstrates `AffordanceRegistry`, server routes, and UI affordance handlers
- **Plugin registry repo** — [tddworks/asc-registry](https://github.com/tddworks/asc-registry) with `registry.json` and release assets for ASC Pro + Hello Plugin

### Changed
- **Unified `Plugin` model** — merged `Plugin` and `MarketPlugin` into a single model with `isInstalled`, `downloadURL?`, `slug?` fields
- **Refactored plugin system** — replaced event-based script plugins with dylib `.plugin` bundle management
- **Removed event plugin system** — deleted `PluginEvent`, `PluginEventPayload`, `PluginResult`, `PluginRunner`, `PluginEventBus` and all infrastructure
- **Removed event bus from commands** — `BuildsUpload` and `VersionsSubmit` no longer emit plugin events
- **Apps page affordance buttons** — plugin affordances (e.g. `greet` from Hello Plugin) render as clickable buttons via `appAffordanceHandlers` registry

---

## [0.1.62] - 2026-04-02

### Added
- **`asc web-server`** — Swift/Hummingbird HTTP+WebSocket server replacing Node.js. Single binary, zero external dependencies, HTTPS with self-signed cert
- **Plugin architecture** — `.plugin` bundles in `~/.asc/plugins/` extend the CLI with routes, commands, affordances, and UI. Dylibs built with `dynamic_lookup` (~300KB)
- **`AffordanceRegistry`** — plugins extend domain model affordances at runtime (e.g. pro plugin adds `stream` to booted simulators)
- **Affordance-driven UI** — web app renders buttons from CAEOAS affordances, not hardcoded features. Plugins register handlers via `window.simAffordanceHandlers`
- **Command Center Simulators page** — device list with search/filter, stats cards, affordance-driven actions

---

## [0.1.61] - 2026-03-31

### Added
- **Screenshot image URLs** — `asc screenshots list` now returns `imageUrl` for each screenshot, so you can view and render real App Store images directly from CLI output
- **Screenshot platform filtering** — filter and browse screenshots by platform (iPhone, iPad, etc.) in the web UI
- **Simulator screenshot capture** — capture and browse simulator screenshots in the web gallery

---

## [0.1.60] - 2026-03-31

### Added
- **`asc simulators list [--booted]`** — list available iOS simulators with state-aware affordances
- **`asc simulators boot --udid <udid>`** — boot a simulator
- **`asc simulators shutdown --udid <udid>`** — shut down a simulator
- **`asc simulators list/boot/shutdown`** — manage local iOS simulators with state-aware affordances

---

## [0.1.59] - 2026-03-30

### Added
- **`asc builds list --platform`** — filter builds by platform (ios, macos, tvos, visionos)
- **`asc builds list --version`** — filter builds by marketing version (e.g. 1.0.0)
- **`asc builds next-number`** — get the next build number for a version/platform, ideal for CI/CD automation (resolves #13)
- **Build platform field** — builds now include platform from preReleaseVersion
- **Build number populated** — `buildNumber` field now maps from `Build.attributes.version` (was always nil)

### Fixed
- **Global options (`--pretty`, `--output`, `--timeout`) now accepted by all commands** — previously 10 leaf commands (`builds add-beta-group`, `builds remove-beta-group`, `builds uploads delete`, `versions set-build`, `reviews responses delete`, `app-clip-experiences delete`, `app-clip-experience-localizations delete`, `analytics-reports delete`, `auth logout`, `auth use`) rejected these flags with "Unknown option"

### Changed
- **`asc builds list`** — table output now includes Build Number and Platform columns
- **Build version semantics** — `version` field now holds the marketing version (from PreReleaseVersion) when available; `buildNumber` holds the build string
- **Builds sorted by newest first** — list results default to `-uploadedDate` sort order

---

## [0.1.58] - 2026-03-23

### Changed
- Bug fixes and improvements.

---

## [0.1.57] - 2026-03-23

### Changed
- **`asc web-server`** — `/command-center/`, `/console/`, and `/` now redirect (302) to the hosted apps at `asccli.app/command-center` and `asccli.app/console` instead of serving local files that no longer exist; startup banner updated to show hosted URLs

---

## [0.1.56] - 2026-03-21

### Changed
- Bug fixes and improvements.

---

## [0.1.55] - 2026-03-21

### Added
- **Iris private API support** — new `asc iris` command namespace for cookie-based App Store Connect private API access
- **`asc iris status`** — check iris cookie session availability (browser or environment source)
- **`asc iris apps list`** — list apps via iris `/v1/appBundles` endpoint
- **`asc iris apps create`** — create a new app with initial version, supports multi-platform (`--platforms IOS MAC_OS`)
- **Cookie-based authentication** — auto-extracts `myacinfo` and session cookies from Chrome/Safari/Firefox via SweetCookieKit, with `ASC_IRIS_COOKIES` env var fallback for CI/CD
- **SweetCookieKit dependency** — browser cookie extraction for iris authentication

---

## [0.1.53] - 2026-03-18

### Changed
- **`asc web` → `asc web-server`** — renamed command to reflect its role as a local API proxy, no longer serves static files
- **Removed Hummingbird dependency** — web server replaced with embedded Node.js proxy (`apps/server.js`), reducing binary size and build dependencies
- **Unified web apps under `apps/`** — moved dashboard from `Sources/ASCCommand/Resources/web/` to `apps/asc-web-command-center/`, console from `homepage/asc-web-console/` to `apps/asc-web-console/`
- **Dual-mode API detection** — both web apps auto-detect local proxy (tries relative `/api/run`, then `localhost:8420`, then falls back to mock mode)

### Added
- **SPM build plugin (`Plugins/EmbedServerJS/`)** — auto-generates Swift source from `apps/server.js` at build time, embedding the API proxy in the binary with `apps/server.js` as single source of truth
- **Command Center nav link on homepage** — added "Command Center" navigation to homepage template with translations in all 12 languages
- **GitHub Pages deployment for web apps** — deploy workflow now copies `apps/asc-web-*` to homepage for static hosting

### Removed
- `WebServer.swift` (Hummingbird-based static file server)
- `homepage/asc-web-console/server.py` (Python dev server)
- Hummingbird package dependency

---

## [0.1.52] - 2026-03-18

### Changed
- Bug fixes and improvements.

---

## [0.1.51] - 2026-03-17

### Added
- `asc web` management dashboard — complete redesign with professional light/dark theme, Plus Jakarta Sans typography, and self-contained CSS (no Tailwind CDN dependency)
- App context selector in sidebar — select an app from the Apps page and all other sections (Versions, Builds, TestFlight, Reviews, IAP, Subscriptions) use that app context automatically
- Rich domain models in web UI — every entity carries parent IDs, semantic booleans (`isLive`, `isEditable`, `isPending`, `isUsable`), and state-aware CAEOAS affordances matching the Swift Domain layer exactly
- Mock/CLI dual data mode — web UI auto-detects the `asc web` backend; falls back to built-in mock data for offline development and demos; toggle via header button
- Dark mode with system preference detection and localStorage persistence
- 15 management pages: Command Center, Apps, Versions, Builds, TestFlight, Submissions, App Info, Screenshots, Reviews, In-App Purchases, Subscriptions, Reports, Code Signing, Xcode Cloud, Users & Roles
- Command Center with release pipeline timeline, quick actions, and stats overview
- Command log modal showing every CLI command executed by the UI
- Standalone development server (`apps/asc-web-command-center/server.js`) for working on the web UI outside of `asc web`

---

## [0.1.50] - 2026-03-15

### Added
- `asc territories list` — list all available App Store territories with currency codes
- `asc iap-availability get --iap-id <id>` — get territory availability for an in-app purchase (includes currency per territory)
- `asc iap-availability create --iap-id <id> --available-in-new-territories --territory USA --territory CHN` — create territory availability for an IAP
- `asc subscription-availability get --subscription-id <id>` — get territory availability for a subscription (includes currency per territory)
- `asc subscription-availability create --subscription-id <id> --available-in-new-territories --territory USA` — create territory availability for a subscription
- `Territory` domain model with id and currency, shared across availability responses
- `getAvailability` affordance on `InAppPurchase` and `Subscription` models for CAEOAS navigation
- `listTerritories` affordance on availability models for territory discovery
- `asc app-availability get --app-id <id>` — get per-territory availability with `isAvailable`, `contentStatuses` (blocking reasons), `releaseDate`, and `isPreOrderEnabled` for every territory

---

## [0.1.49] - 2026-03-14

### Added
- `asc skills list` — list available skills from the asc-cli repository via `npx skills add tddworks/asc-cli --list`
- `asc skills install --name <name>` — install a specific skill; `--all` to install all available skills
- `asc skills installed` — show skills installed in `~/.claude/skills/` with CAEOAS affordances
- `asc skills uninstall --name <name>` — remove an installed skill from `~/.claude/skills/`
- `asc skills check` — check for available skill updates via `npx skills check`
- `asc skills update` — update installed skills via `npx skills update`
- Auto-update checker — non-blocking skill update check on every `asc` command (24h cooldown, CI-aware, disable with `ASC_SKIP_SKILL_CHECK=true`)
- `--app-id` flag on `asc app-wall submit` — accepts App Store Connect app IDs directly, auto-constructs App Store URLs (repeatable, combinable with `--app` and `--developer-id`)

---

## [0.1.48] - 2026-03-13

### Changed
- `--developer` on `asc app-wall submit` is now optional — when omitted, the homepage card uses the iTunes artist name instead
- `asc beta-review submissions list --build-id <id>` — list beta app review submissions for a build
- `asc beta-review submissions create --build-id <id>` — submit a build for beta (TestFlight external) review
- `asc beta-review submissions get --submission-id <id>` — get a specific beta review submission
- `asc beta-review detail get --app-id <id>` — get beta review contact info and demo account details
- `asc beta-review detail update --detail-id <id>` — update beta review contact info, demo account, and notes

---

## [0.1.47] - 2026-03-13

### Changed
- Bug fixes and improvements.

---

## [0.1.46] - 2026-03-13

### Added
- `asc builds archive --scheme <name>` — archive and export Xcode projects locally via `xcodebuild`, auto-detecting workspace/project from the current directory; supports `--platform`, `--configuration`, `--export-method` (app-store/ad-hoc/development/enterprise), and `--output-dir`
- `--upload` flag on `asc builds archive` chains the exported IPA/PKG directly into App Store Connect upload, combining archive + export + upload in a single command

---

## [0.1.45] - 2026-03-12

### Changed
- Subscription offer codes: `asc subscription-offer-codes list/create/update`, `asc subscription-offer-code-custom-codes list/create/update`, `asc subscription-offer-code-one-time-codes list/create/update` — manage offer codes, custom redeemable codes, and one-time use code batches for auto-renewable subscriptions
- IAP offer codes: `asc iap-offer-codes list/create/update`, `asc iap-offer-code-custom-codes list/create/update`, `asc iap-offer-code-one-time-codes list/create/update` — manage offer codes, custom redeemable codes, and one-time use code batches for in-app purchases
- `InAppPurchase` and `Subscription` affordances now include `listOfferCodes` for direct navigation to offer codes

---

## [0.1.44] - 2026-03-12

### Added
- Power & performance metrics: `asc perf-metrics list --app-id <id>` and `asc perf-metrics list --build-id <id>` — download launch time, hang rate, memory, disk, battery, termination, and animation metrics with `--metric-type` filter
- Diagnostic signatures: `asc diagnostics list --build-id <id>` — list hang, disk write, and launch diagnostic hotspots with `--diagnostic-type` filter
- Diagnostic logs: `asc diagnostic-logs list --signature-id <id>` — view call stack metadata for a specific diagnostic signature

---

## [0.1.43] - 2026-03-11

### Added
- HTML screenshot generation: `asc app-shots html --plan composition-plan.json` — deterministic App Store screenshot generation with real device mockup frames, no AI or API keys needed
- CompositionPlan format: normalized 0-1 coordinates, multiple devices per slide, text overlays with alignment, gradient backgrounds, per-screen color themes
- Device mockup system: bundled iPhone 17 Pro Max frame with `mockups.json` config; users can add custom mockups to `~/.asc/mockups/`
- TextOverlay `textAlign` property: supports `left`, `center`, `right` alignment for text positioning in composition plans
- Client-side PNG export via html-to-image CDN in generated HTML pages

---

## [0.1.42] - 2026-03-11

### Added
- Customer reviews: `asc reviews list --app-id <id>` and `asc reviews get --review-id <id>` — list and view customer reviews with rating, title, body, reviewer nickname, and territory
- Review responses: `asc review-responses create --review-id <id> --response-body "text"`, `asc review-responses get --review-id <id>`, `asc review-responses delete --response-id <id>` — manage developer responses to customer reviews

### Changed
- Bug fixes and improvements.

---

## [0.1.41] - 2026-03-10

### Added
- Sales reports: `asc sales-reports download` with support for 10 report types, 5 sub-types, and 4 frequencies
- Finance reports: `asc finance-reports download` with financial and finance detail report types
- Gzip decompression and TSV parsing infrastructure for App Store Connect report downloads
- Analytics reports: `asc analytics-reports request/list/delete/reports/instances/segments` — multi-step analytics workflow with 5 report categories and 3 granularity levels
- `asc auth login --vendor-number <number>` — save vendor number with account credentials
- `asc auth update --vendor-number <number>` — add or update vendor number on an existing account
- Vendor number auto-resolution for `sales-reports download` and `finance-reports download` — `--vendor-number` is now optional when saved on the active account

---

## [0.1.40] - 2026-03-09

### Changed
- Bug fixes and improvements.

---

## [0.1.39] - 2026-03-08

### Added
- `asc app-clips list --app-id <id>` — list App Clips for an app; `AppClip` carries `appId` (injected), `bundleId?`; affordances: `listAppClips`, `listExperiences`
- `asc app-clip-experiences list --app-clip-id <id>` — list default experiences for an App Clip; `AppClipDefaultExperience` carries `appClipId` (injected), `action?` (OPEN/VIEW/PLAY); affordances: `delete`, `listExperiences`, `listLocalizations`
- `asc app-clip-experiences create --app-clip-id <id> [--action OPEN|VIEW|PLAY]` — create a default experience
- `asc app-clip-experiences delete --experience-id <id>` — delete a default experience
- `asc app-clip-experience-localizations list --experience-id <id>` — list localizations; `AppClipDefaultExperienceLocalization` carries `experienceId` (injected), `locale`, `subtitle?`; affordances: `delete`, `listLocalizations`
- `asc app-clip-experience-localizations create --experience-id <id> --locale <code> [--subtitle "..."]` — create a localization
- `asc app-clip-experience-localizations delete --localization-id <id>` — delete a localization
- `AppClipRepository` `@Mockable` protocol with 7 methods covering all CRUD operations
- `asc game-center detail get --app-id <id>` — get Game Center configuration for an app; `GameCenterDetail` carries `appId` (injected), `isArcadeEnabled`; affordances: `getDetail`, `listAchievements`, `listLeaderboards`
- `asc game-center achievements list --detail-id <id>` — list Game Center achievements; `GameCenterAchievement` carries `gameCenterDetailId` (injected), `referenceName`, `vendorIdentifier`, `points`, `isShowBeforeEarned`, `isRepeatable`, `isArchived`; affordances: `listAchievements`, `delete`
- `asc game-center achievements create --detail-id <id> --reference-name <n> --vendor-identifier <v> --points <n> [--show-before-earned] [--repeatable]` — create a new achievement
- `asc game-center achievements delete --achievement-id <id>` — delete an achievement
- `asc game-center leaderboards list --detail-id <id>` — list Game Center leaderboards; `GameCenterLeaderboard` carries `gameCenterDetailId` (injected), `referenceName`, `vendorIdentifier`, `scoreSortType` (ASC/DESC), `submissionType` (BEST_SCORE/MOST_RECENT_SCORE), `isArchived`; affordances: `listLeaderboards`, `delete`
- `asc game-center leaderboards create --detail-id <id> --reference-name <n> --vendor-identifier <v> --score-sort-type ASC|DESC [--submission-type BEST_SCORE|MOST_RECENT_SCORE]` — create a new leaderboard
- `asc game-center leaderboards delete --leaderboard-id <id>` — delete a leaderboard
- `ScoreSortType` and `LeaderboardSubmissionType` domain enums
- `GameCenterRepository` `@Mockable` protocol with 7 methods covering all CRUD operations

---

## [0.1.38] - 2026-03-07

### Added
- `asc xcode-cloud products list [--app-id <id>]` — list Xcode Cloud products; `XcodeCloudProduct` carries `appId` (injected from relationship), `name`, `productType`; affordances: `listWorkflows`, `listProducts`
- `asc xcode-cloud workflows list --product-id <id>` — list CI workflows for a product; `XcodeCloudWorkflow` carries `productId` (injected), `name`, `description`, `isEnabled`, `isLockedForEditing`; affordances: `listBuildRuns`, `listWorkflows` always, `startBuild` only when `isEnabled`
- `asc xcode-cloud builds list --workflow-id <id>` — list build runs for a workflow; `XcodeCloudBuildRun` carries `workflowId` (injected), `number`, `executionProgress` (PENDING/RUNNING/COMPLETE), `completionStatus` (SUCCEEDED/FAILED/ERRORED/CANCELED/SKIPPED), `startReason`; semantic booleans: `isPending`, `isRunning`, `isComplete`, `isSucceeded`, `hasFailed`
- `asc xcode-cloud builds get --build-run-id <id>` — get a specific build run by ID
- `asc xcode-cloud builds start --workflow-id <id> [--clean]` — start a new build run; `--clean` flag performs a clean build removing derived data

---

## [0.1.37] - 2026-03-06

### Changed
- Bug fixes and improvements.

---

## [0.1.36] - 2026-03-05

### Added
- `asc users list/update/remove` — manage App Store Connect team members; list users filtered by role, update a member's roles (replaces all current roles), or revoke access immediately; `TeamMember` carries `username`, `firstName`, `lastName`, `roles`, `isAllAppsVisible`, `isProvisioningAllowed`; affordances: `remove`, `updateRoles` (pre-filled with current roles)
- `asc user-invitations list/invite/cancel` — manage pending team invitations; invite a new member with one or more roles (`--role DEVELOPER --role APP_MANAGER`); `UserInvitationRecord` carries `email`, `roles`, `expirationDate`; affordance: `cancel`; supports 13 roles; `--all-apps-visible` flag on invite grants access to all apps
- `asc auth list` — list all saved App Store Connect accounts with active status and per-account affordances (`use`, `logout`)
- `asc auth use <name>` — switch the active App Store Connect account; all subsequent commands use the newly active account
- `asc auth login --name <alias>` — optional `--name` flag to save credentials under a human-readable alias (defaults to `"default"`); first saved account becomes active automatically; subsequent logins with new names are saved alongside existing accounts; account names must not contain spaces (use hyphens or underscores)

### Changed
- `asc auth logout` — now accepts optional `--name <alias>` flag; removes the named account or the active account if `--name` is omitted
- `asc auth check` — now shows the account `name` field when credentials come from a saved account (omitted for environment-variable credentials)
- `~/.asc/credentials.json` — upgraded to multi-account format `{ "active": "name", "accounts": { ... } }`; old single-credential files are auto-migrated to a `"default"` named account on first use

---

## [0.1.35] - 2026-03-04

### Added
- `asc app-wall submit` — submit your app to the community app wall at asccli.app by opening a GitHub pull request against `tddworks/asc-cli`; forks the repo, adds your entry to `homepage/apps.json`, and creates a PR automatically; supports `--developer-id` (auto-fetches all your App Store apps), `--app` (specific App Store URLs, repeatable), `--github`, `--x`; GitHub token resolved from `--github-token` flag, `$GITHUB_TOKEN`, or `gh auth token`

---

## [0.1.34] - 2026-03-02

### Fixed
- `asc app-shots translate` — no longer regenerates the visual design (background, colors, device mockup, layout) from the original plan specs; now sends a simple "edit this image, translate only the text overlays" prompt so the existing generated screenshot is preserved exactly

---

## [0.1.33] - 2026-03-02

### Added
- `asc init` — initialise project context by saving the app ID, name, and bundle ID to `.asc/project.json` in the current directory; supports `--app-id` (direct), `--name` (search by name), or auto-detect from `.xcodeproj` bundle identifier; output includes CAEOAS affordances for common next steps

---

## [0.1.32] - 2026-03-01

### Changed
- Bug fixes and improvements.

---

## [0.1.31] - 2026-03-01

### Added
- **Plugin system** — users can install executable plugins in `~/.asc/plugins/<name>/` to extend the CLI with custom event handlers (e.g., Slack/Telegram notifications)
- `asc plugins list` — list all installed plugins with name, version, enabled status, and subscribed events
- `asc plugins install <path>` — install a plugin from a local directory containing `manifest.json` and a `run` executable
- `asc plugins uninstall --name <name>` — remove an installed plugin
- `asc plugins enable --name <name>` — re-enable a disabled plugin
- `asc plugins disable --name <name>` — disable a plugin without removing it
- `asc plugins run --name <name> --event <event>` — manually invoke a plugin for testing; supports `--app-id`, `--version-id`, `--build-id` payload flags
- Auto-event emission: `asc builds upload` fires `build.uploaded` after a successful upload; `asc versions submit` fires `version.submitted` after a successful submission
- Plugin protocol: plugins receive a JSON event payload on stdin and write a `{"success": bool, "message": "..."}` result to stdout
- `version-review-detail get --version-id <id>` — fetch the App Store review contact info and demo account settings for a version
- `asc version-review-detail update --version-id <id> [flags]` — upsert review info (creates if none exists, patches if already set); supports `--contact-first-name`, `--contact-last-name`, `--contact-phone`, `--contact-email`, `--demo-account-required`, `--demo-account-name`, `--demo-account-password`, `--notes`
- `notes` field added to `AppStoreReviewDetail` domain model
- `getReviewDetail` affordance added to `AppStoreVersion` for agent navigation

---

## [0.1.30] - 2026-03-01

### Added
- `asc age-rating get --app-info-id <id>` — fetch the full age rating declaration for an app info, including all content intensity ratings, boolean flags, kids age band, and region overrides
- `asc age-rating update --declaration-id <id> [flags]` — update individual age rating fields via PATCH; supports all 9 boolean flags (`--advertising`, `--gambling`, `--loot-box`, etc.) and 13 intensity ratings (`--violence-realistic`, `--profanity`, `--sexual-content`, etc.) plus `--kids-age-band`, `--age-rating-override`, and `--korea-age-rating-override`
- `getAgeRating` affordance added to `AppInfo` for agent navigation
- `--privacy-choices-url` and `--privacy-policy-text` flags on `asc app-info-localizations update` — expose the two remaining updatable privacy fields from the App Store Connect API
- `asc app-info-localizations delete --localization-id <id>` — remove a per-locale metadata entry; `delete` affordance added to `AppInfoLocalization`
- `asc app-infos update --app-info-id <id> [--primary-category] [--primary-subcategory-one] [--primary-subcategory-two] [--secondary-category] [--secondary-subcategory-one] [--secondary-subcategory-two]` — set or update all 6 category relationship fields on an AppInfo; `updateCategories` affordance added to `AppInfo`
- `asc app-categories list [--platform IOS|MAC_OS|TV_OS]` — list all available App Store categories and subcategories; returns a flat list combining top-level (`data[]`) and subcategories (`included[]`) from the API; `AppCategory` domain model with `parentId` for subcategory identification

---

## [0.1.29] - 2026-03-01

### Added
- `--style-reference <path>` flag on `asc app-shots generate` and `asc app-shots translate` — pass any PNG/JPEG as a visual style guide; Gemini replicates the reference's colors, typography, gradients, and layout patterns without copying its content; the reference image is sent as the first part in the Gemini request followed by an explicit style-guide instruction

---

## [0.1.28] - 2026-02-28

### Added
- `--device-type` flag on `asc app-shots generate` and `asc app-shots translate` — accepts named App Store display type constants (`APP_IPHONE_69`, `APP_IPHONE_67`, `APP_IPAD_PRO_129`, etc.) and automatically sets the correct `--output-width`/`--output-height`; overrides explicit dimension flags when both are provided; all 16 device types supported across iPhone, iPad, Apple TV, Mac, and Apple Vision Pro

### Fixed
- `asc app-shots generate` and `asc app-shots translate` now upscale Gemini output to the correct App Store dimensions using CoreGraphics. Gemini returns ~704×1520; the required iPhone 6.9" size is 1320×2868. New `--output-width` (default `1320`) and `--output-height` (default `2868`) flags control the target size for all other device types.

---

## [0.1.27] - 2026-02-28

### Added
- `asc app-shots translate` — one-shot localization of generated screenshots; reads the English plan + existing `screen-{n}.png` files, sends them to Gemini with per-locale translation instructions, writes `{output-dir}/{locale}/screen-{n}.png`; supports multiple locales in one invocation (`--to zh --to ja --to ko`); locales processed in parallel via `TaskGroup`
- `asc app-shots generate` — AI-powered App Store screenshot generation using Gemini; reads a `ScreenPlan` JSON + screenshot images, calls Gemini image generation API, writes `screen-{index}.png` files; `--plan` defaults to `.asc/app-shots/app-shots-plan.json`, `--output-dir` defaults to `.asc/app-shots/output`, screenshots auto-discovered from plan directory when not provided — zero-argument happy path: `asc app-shots generate`
- `asc app-shots config` — persistent Gemini API key management; `--gemini-api-key` saves to `~/.asc/app-shots-config.json`, bare invocation shows current key + source (file/env), `--remove` deletes it; `generate` resolves key from flag → env var → stored config
- `ScreenPlan`, `ScreenConfig`, `ScreenTone`, `LayoutMode`, `ScreenColors`, `AppShotsConfig` domain models
- `ScreenshotGenerationRepository` + `AppShotsConfigStorage` `@Mockable` protocols
- `GeminiScreenshotGenerationRepository` — native Gemini `generateContent` API with `responseModalities: ["TEXT","IMAGE"]`, parallel TaskGroup generation
- `FileAppShotsConfigStorage` — saves Gemini API key to `~/.asc/app-shots-config.json`

---

## [0.1.25] - 2026-02-27

### Added
- `asc subscriptions submit` — submit a subscription for App Store review; `submit` affordance on `Subscription` appears only when `state == READY_TO_SUBMIT`
- `asc subscription-offers list` — list introductory offers for a subscription
- `asc subscription-offers create` — create a `FREE_TRIAL`, `PAY_AS_YOU_GO`, or `PAY_UP_FRONT` introductory offer; validates that `--price-point-id` is provided for paid modes
- `SubscriptionIntroductoryOffer` domain model with `SubscriptionOfferDuration` and `SubscriptionOfferMode` enums; `requiresPricePoint` semantic boolean on `SubscriptionOfferMode`
- `createIntroductoryOffer` and `listIntroductoryOffers` CAEOAS affordances on `Subscription`
- `asc iap list` — list in-app purchases (consumable, non-consumable, non-renewing subscription) for an app
- `asc iap create` — create a new in-app purchase with reference name, product ID, and type
- `asc iap-localizations list` — list localizations for an in-app purchase
- `asc iap-localizations create` — create a per-locale name and description for an in-app purchase
- `asc subscription-groups list` — list subscription groups for an app
- `asc subscription-groups create` — create a new subscription group
- `asc subscriptions list` — list subscriptions within a group
- `asc subscriptions create` — create a subscription with period (ONE_WEEK–ONE_YEAR), family sharing, and group level
- `asc subscription-localizations list` — list per-locale metadata for a subscription
- `asc subscription-localizations create` — create a per-locale name and description for a subscription
- `asc iap submit` — submit an in-app purchase for App Store review
- `asc iap price-points list` — list available price tiers for an IAP, optionally filtered by territory
- `asc iap prices set` — set the price schedule for an IAP (base territory + auto-pricing for all others)
- `InAppPurchaseSubmission`, `InAppPurchasePricePoint`, `InAppPurchasePriceSchedule` domain models with CAEOAS affordances
- `InAppPurchaseState` and `SubscriptionState` enums with semantic booleans (`isApproved`, `isLive`, `isEditable`, `isPendingReview`)
- CAEOAS affordances on all new models linking to sibling and child commands
- `asc app-preview-sets list` — list App Store video preview sets for a version localization
- `asc app-preview-sets create` — create a new preview set for a specific device type
- `asc app-previews list` — list video previews in a preview set
- `asc app-previews upload` — upload a video file (`.mp4`, `.mov`, `.m4v`) to a preview set using a 3-step upload flow (reserve → PUT chunks → PATCH with MD5)
- `PreviewType` enum with 16 device cases (iPhone, iPad, Mac, Apple TV, Apple Vision Pro)
- `AppPreview.VideoDeliveryState` with 5 states including `PROCESSING` (unique to video)
- Renamed `--group-id` to `--beta-group-id` in all `asc testflight testers` commands for consistency with `asc builds add-beta-group`

---

## [0.1.24] - 2026-02-27

---

## [0.1.23] - 2026-02-26

---

## [0.1.22] - 2026-02-26

---

## [0.1.21] - 2026-02-26

---

## [0.1.20] - 2026-02-26

---

## [0.1.9] - 2026-02-25

---

## [0.1.8] - 2026-02-25

---

## [0.1.7] - 2026-02-25

---

## [0.1.6] - 2026-02-24

---

## [0.1.5] - 2026-02-24

---

## [0.1.4] - 2026-02-24

### Added
- **Persistent Auth Login**: Save API key credentials to `~/.asc/credentials.json` so environment variables are not required on every session.
  - `asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>` — save credentials to disk
  - `asc auth logout` — remove saved credentials
  - `asc auth check` — verify credentials and show their source (`file` or `environment`)
  - Credential resolution order: `~/.asc/credentials.json` → environment variables (fully backwards-compatible)
  - `asc auth check` now outputs JSON with an `affordances` field (same agent-first format as all other commands)

### Technical
- Added `AuthStorage` `@Mockable` protocol (`save`, `load`, `delete`) in Domain
- Added `AuthStatus` domain model (`keyID`, `issuerID`, `source: CredentialSource`) with `AffordanceProviding`
- Added `CredentialSource` enum (`.file` / `.environment`) as `Codable` String raw value
- `AuthCredentials` gains `Codable` conformance for JSON file serialization
- `FileAuthStorage` (Infrastructure) reads/writes `~/.asc/credentials.json` using `JSONEncoder`/`JSONDecoder`
- `FileAuthProvider` (Infrastructure) implements `AuthProvider` backed by `FileAuthStorage`
- `CompositeAuthProvider` (Infrastructure) tries file credentials first, falls back to `EnvironmentAuthProvider`
- `ClientProvider` updated to use `CompositeAuthProvider` — all existing commands gain file-based auth transparently

---

## [0.1.3] - 2026-02-24

### Added
- **Version Localization Update**: Set What's New text, description, keywords, marketing URL, support URL, and promotional text for any locale directly from the CLI.
  - `asc version-localizations update --localization-id <id> --whats-new "text"` — update What's New
  - `asc version-localizations update --localization-id <id> --description "text" --keywords "a,b,c"` — update other fields
  - All content fields are optional — only provided fields are sent to the API
- **App Info Localizations**: Manage per-locale app metadata (name, subtitle, privacy policy) directly from the CLI. Each locale's App Store listing information is now fully writable.
  - `asc app-infos list --app-id <id>` — list AppInfo records for an app
  - `asc app-info-localizations list --app-info-id <id>` — list all locale entries
  - `asc app-info-localizations create --app-info-id <id> --locale <locale> --name <name>` — add a new locale
  - `asc app-info-localizations update --localization-id <id> [--name] [--subtitle] [--privacy-policy-url]` — patch one or more fields

### Technical
- Introduced `VersionLocalizationRepository` (`@Mockable` protocol) with `listLocalizations`, `createLocalization`, `updateLocalization` — separate from `ScreenshotRepository` which now handles only screenshot sets and images
- Added `SDKLocalizationRepository` implementing `VersionLocalizationRepository`; converts `URL?` ↔ `String?` for `marketingURL`/`supportURL` SDK fields
- `AppStoreVersionLocalization` gains 6 optional text fields with nil-safe Codable (`encodeIfPresent`) — nil fields are omitted from JSON output
- `AppStoreVersionLocalization.affordances` now includes `updateLocalization` command
- `ScreenshotsImport` updated to accept `localizationRepo` + `screenshotRepo` as separate parameters
- Added `AppInfo` and `AppInfoLocalization` domain models carrying parent IDs for agent navigation
- Added `AppInfoRepository` `@Mockable` protocol with `listAppInfos`, `listLocalizations`, `createLocalization`, `updateLocalization`
- Added `SDKAppInfoRepository` mapping `privacyPolicyURL`/`privacyChoicesURL` SDK fields; extracts `appInfoId` from PATCH response relationships
- Updated `App.affordances` to include `listAppInfos` command
- Added `docs/features/version-localizations.md`, `docs/features/app-info-localizations.md`

---

## [0.1.1] - 2026-02-22

### Added
- **App Store Version Management**: Browse and create versions for any app across all platforms (iOS, macOS, tvOS, watchOS, visionOS).
  - `asc versions list --app-id <id>`
  - `asc versions create --app-id <id> --version <string> --platform <ios|macos|...>`
- **Localization Management**: List and create App Store version localizations.
  - `asc version-localizations list --version-id <id>`
  - `asc version-localizations create --version-id <id> --locale <locale>`
- **Screenshot Sets**: List and create screenshot sets for a localization (one set per display type: iPhone 6.7", iPad Pro 12.9", Mac, etc.).
  - `asc screenshot-sets list --localization-id <id>`
  - `asc screenshot-sets create --localization-id <id> --display-type <TYPE>`
- **Screenshots**: List and upload screenshots within a set.
  - `asc screenshots list --set-id <id>` — with file size, dimensions, and delivery state
  - `asc screenshots upload --set-id <id> --file <path>` — three-step ASC flow (reserve → S3 upload → commit) handled automatically
- **Submit for Review**: Submit an App Store version for review in one command. Reuses an existing open review submission if one is already pending.
  - `asc versions submit --version-id <id>`
- **TestFlight**: List beta groups and testers.
  - `asc testflight groups [--app-id <id>]`
  - `asc testflight testers --group-id <id>`
- **TUI Screenshot Browser**: Interactive terminal UI now supports the full screenshot hierarchy — app → version → platform → locale → screenshot set.
- **Agent-First Output (CAEOAS)**: JSON responses include an `affordances` field with ready-to-run follow-up commands so AI agents can navigate the full resource tree without knowing the command structure.
  ```json
  { "data": [{ "id": "...", "affordances": { "listVersions": "asc versions list --app-id ..." } }] }
  ```
- **Homebrew Tap**: Install via Homebrew with native architecture binaries (arm64 and x86_64).
  ```bash
  brew install asc-tools/tap/asc
  ```
- **Homepage**: Static landing page at [asccli.app](https://asccli.app) with English, Chinese, and Japanese localizations.

### Fixed
- Submission flow now correctly includes the app relationship in the version request, preventing API 422 errors.
- Submission flow reuses an unresolved (open) review submission instead of always creating a new one.

### Technical
- `AppStoreVersion`, `AppStoreVersionState`, `AppStorePlatform` models with semantic booleans (`isLive`, `isEditable`, `isPending`)
- `AppStoreVersionLocalization`, `AppScreenshotSet`, `AppScreenshot` models; all carry parent IDs
- `ScreenshotDisplayType` enum with 39 display types, device categories, and human-readable names
- `AffordanceProviding` protocol; `OutputFormatter.formatAgentItems()` merges affordances into JSON
- `SubmissionRepository` orchestrating 4-step review submission API flow
- `ReviewSubmission` domain model with `ReviewSubmissionState` and `isWaitingForReview`
- `SequencedStubAPIClient` for multi-step API flow tests
- `APIClient` protocol abstraction enabling `StubAPIClient` for infrastructure tests
- Automated GitHub Actions release workflow with binary artifacts and Homebrew formula update
- CI/CD Codecov coverage reporting

---

## [0.1.0] - 2026-02-10

### Added
- **Apps**: List and get apps on your App Store Connect account.
  - `asc apps list`
- **Builds**: List builds for an app with processing state, version, and expiry.
  - `asc builds list [--app-id <id>]`
- **TUI**: Interactive terminal UI (`asc tui`) for browsing apps and builds without remembering IDs.
- **Auth Check**: Verify environment credentials are valid.
  - `asc auth check`
- **Output Formats**: All commands support `--output json` (default), `--output table`, and `--output markdown`. Use `--pretty` for formatted JSON.
- **Environment Auth**: Configure via `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_PRIVATE_KEY_PATH` (or `ASC_PRIVATE_KEY` for inline PEM).

### Technical
- Three-layer architecture: `ASCCommand → Infrastructure → Domain`
- `appstoreconnect-swift-sdk` adapter with clean domain model separation
- `App`, `Build`, `BetaGroup`, `BetaTester` domain models (`Sendable`, `Equatable`, `Identifiable`, `Codable`)
- `AppRepository`, `BuildRepository`, `TestFlightRepository` `@Mockable` protocols
- `ClientFactory` + `ClientProvider` dependency injection wiring
- Apple `@Testing` macro test suite following Chicago School TDD

---

[Unreleased]: https://github.com/tddworks/asc-cli/compare/v0.17.3...HEAD
[0.17.3]: https://github.com/tddworks/asc-cli/compare/v0.17.2...v0.17.3
[0.17.2]: https://github.com/tddworks/asc-cli/compare/v0.17.1...v0.17.2
[0.17.1]: https://github.com/tddworks/asc-cli/compare/v0.17.0...v0.17.1
[0.17.0]: https://github.com/tddworks/asc-cli/compare/v0.16.9...v0.17.0
[0.16.9]: https://github.com/tddworks/asc-cli/compare/v0.1.68...v0.16.9
[0.1.68]: https://github.com/tddworks/asc-cli/compare/v0.1.67...v0.1.68
[0.1.67]: https://github.com/tddworks/asc-cli/compare/v0.1.66...v0.1.67
[0.1.66]: https://github.com/tddworks/asc-cli/compare/v0.1.65...v0.1.66
[0.1.65]: https://github.com/tddworks/asc-cli/compare/v0.1.64...v0.1.65
[0.1.64]: https://github.com/tddworks/asc-cli/compare/v0.1.63...v0.1.64
[0.1.63]: https://github.com/tddworks/asc-cli/compare/v0.1.62...v0.1.63
[0.1.62]: https://github.com/tddworks/asc-cli/compare/v0.1.61...v0.1.62
[0.1.61]: https://github.com/tddworks/asc-cli/compare/v0.1.60...v0.1.61
[0.1.60]: https://github.com/tddworks/asc-cli/compare/v0.1.59...v0.1.60
[0.1.59]: https://github.com/tddworks/asc-cli/compare/v0.1.58...v0.1.59
[0.1.58]: https://github.com/tddworks/asc-cli/compare/v0.1.57...v0.1.58
[0.1.57]: https://github.com/tddworks/asc-cli/compare/v0.1.56...v0.1.57
[0.1.56]: https://github.com/tddworks/asc-cli/compare/v0.1.55...v0.1.56
[0.1.55]: https://github.com/tddworks/asc-cli/compare/v0.1.53...v0.1.55
[0.1.53]: https://github.com/tddworks/asc-cli/compare/v0.1.52...v0.1.53
[0.1.52]: https://github.com/tddworks/asc-cli/compare/v0.1.51...v0.1.52
[0.1.51]: https://github.com/tddworks/asc-cli/compare/v0.1.50...v0.1.51
[0.1.50]: https://github.com/tddworks/asc-cli/compare/v0.1.49...v0.1.50
[0.1.49]: https://github.com/tddworks/asc-cli/compare/v0.1.48...v0.1.49
[0.1.48]: https://github.com/tddworks/asc-cli/compare/v0.1.47...v0.1.48
[0.1.47]: https://github.com/tddworks/asc-cli/compare/v0.1.46...v0.1.47
[0.1.46]: https://github.com/tddworks/asc-cli/compare/v0.1.45...v0.1.46
[0.1.45]: https://github.com/tddworks/asc-cli/compare/v0.1.43...v0.1.45
[0.1.43]: https://github.com/tddworks/asc-cli/compare/v0.1.42...v0.1.43
[0.1.42]: https://github.com/tddworks/asc-cli/compare/v0.1.41...v0.1.42
[0.1.41]: https://github.com/tddworks/asc-cli/compare/v0.1.40...v0.1.41
[0.1.40]: https://github.com/tddworks/asc-cli/compare/v0.1.39...v0.1.40
[0.1.39]: https://github.com/tddworks/asc-cli/compare/v0.1.38...v0.1.39
[0.1.38]: https://github.com/tddworks/asc-cli/compare/v0.1.37...v0.1.38
[0.1.37]: https://github.com/tddworks/asc-cli/compare/v0.1.36...v0.1.37
[0.1.36]: https://github.com/tddworks/asc-cli/compare/v0.1.35...v0.1.36
[0.1.35]: https://github.com/tddworks/asc-cli/compare/v0.1.34...v0.1.35
[0.1.34]: https://github.com/tddworks/asc-cli/compare/v0.1.33...v0.1.34
[0.1.33]: https://github.com/tddworks/asc-cli/compare/v0.1.32...v0.1.33
[0.1.32]: https://github.com/tddworks/asc-cli/compare/v0.1.31...v0.1.32
[0.1.31]: https://github.com/tddworks/asc-cli/compare/v0.1.30...v0.1.31
[0.1.30]: https://github.com/tddworks/asc-cli/compare/v0.1.29...v0.1.30
[0.1.29]: https://github.com/tddworks/asc-cli/compare/v0.1.28...v0.1.29
[0.1.28]: https://github.com/tddworks/asc-cli/compare/v0.1.27...v0.1.28
[0.1.27]: https://github.com/tddworks/asc-cli/compare/v0.1.25...v0.1.27
[0.1.25]: https://github.com/tddworks/asc-cli/compare/v0.1.24...v0.1.25
[0.1.24]: https://github.com/tddworks/asc-cli/compare/v0.1.23...v0.1.24
[0.1.23]: https://github.com/tddworks/asc-cli/compare/v0.1.22...v0.1.23
[0.1.22]: https://github.com/tddworks/asc-cli/compare/v0.1.21...v0.1.22
[0.1.21]: https://github.com/tddworks/asc-cli/compare/v0.1.20...v0.1.21
[0.1.20]: https://github.com/tddworks/asc-cli/compare/v0.1.9...v0.1.20
[0.1.9]: https://github.com/tddworks/asc-cli/compare/v0.1.8...v0.1.9
[0.1.8]: https://github.com/tddworks/asc-cli/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/tddworks/asc-cli/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/tddworks/asc-cli/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/tddworks/asc-cli/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/tddworks/asc-cli/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/tddworks/asc-cli/compare/v0.1.1...v0.1.3
[0.1.1]: https://github.com/tddworks/asc-cli/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/tddworks/asc-cli/releases/tag/v0.1.0
