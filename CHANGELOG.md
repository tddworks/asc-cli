# Changelog

All notable changes to asc-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Docs reorganised: a short README, one folder per feature under `docs/features/`, and a full command reference generated from the binary (`docs/commands.md`). Releases before 0.18 moved to `docs/changelog/`. → [docs](docs/README.md) ([#29](https://github.com/tddworks/asc-cli/pull/29))
- Refused review submissions now list Apple's specific reasons (missing screenshots, content rights, App Privacy, pricing) instead of only "please check associated errors". ([#27](https://github.com/tddworks/asc-cli/pull/27))
- Dependencies updated to their latest releases, including appstoreconnect-swift-sdk 4.4.3 (was 4.2.0) and Hummingbird 2.27.0; `Package.swift` minimums raised to match. ([#27](https://github.com/tddworks/asc-cli/pull/27))

### Added
- `asc versions submit --with-products` submits every `READY_TO_SUBMIT` in-app purchase and subscription together with the app version, as first-time products require, with just your API key. `--dry-run` previews. → [docs](docs/features/submit-with-products/README.md) ([#27](https://github.com/tddworks/asc-cli/pull/27))
- `asc review-submissions create`, `items add`, `items remove` and `submit` build a review submission step by step. → [docs](docs/features/review-submissions/README.md) ([#27](https://github.com/tddworks/asc-cli/pull/27))
- `asc iap versions list`, `asc subscriptions versions list` and `asc subscription-groups versions list` show each product's review versions and state. REST: `GET /api/v1/{iap,subscriptions,subscription-groups}/:id/versions`. ([#27](https://github.com/tddworks/asc-cli/pull/27))
- `asc apps price-points list` and `asc apps prices set` set the app's price or make it free, fixing the "not eligible for submission until pricing has been set" refusal. → [docs](docs/features/app-pricing/README.md) ([#28](https://github.com/tddworks/asc-cli/pull/28))
- `asc app-availability create` sets the territories an app is sold in. REST: `POST /api/v1/apps/:appId/availability`. → [docs](docs/features/iap-subscription-availability/README.md) ([#28](https://github.com/tddworks/asc-cli/pull/28))
- `asc perf-metrics list --metric-type STORAGE` reads Apple's new storage metrics. ([#27](https://github.com/tddworks/asc-cli/pull/27))

### Fixed
- `asc app-availability get` on an app that was never set up returns `{"data":[]}` with a hint to run `create`, instead of a raw 404. ([#28](https://github.com/tddworks/asc-cli/pull/28))
- `asc review-submissions items list` shows what each item points at (app version, product versions and the rest) instead of an empty link. ([#27](https://github.com/tddworks/asc-cli/pull/27))

---

## [0.18.4] - 2026-09-23

### Fixed
- **`asc subscriptions prices set-batch` sends one request instead of one per territory** — it now sends a single `PATCH /v1/subscriptions/{id}` with every price inlined (`SubscriptionPriceInlineCreate`) instead of one `POST /v1/subscriptionPrices` per territory. Pricing all 175 territories took 175 sequential POSTs (over a minute per subscription), and a failure partway through left some territories priced and others not; Apple now applies the batch all-or-nothing. The REST `POST /api/v1/subscriptions/:id/prices` route benefits too, since it uses the same repository method.
- **Subscription price schedules no longer drop manual prices after the first 50** — `subscription-price-schedule get` (and the read-back after `set-batch`) fetched `/v1/subscriptions/{id}/prices` without a `limit`, so only Apple's default first page came back and the other territories were filled with the first price's equalizations, showing wrong prices where custom per-territory prices were set. It now requests `limit=200` and follows the pagination cursor.
- **The other per-territory price lists no longer stop at 50** — the same truncation affected `iap-price-schedule get` (manual prices), `iap-offer-codes prices list`, `subscription-offer-codes prices list`, `subscription-promotional-offers prices list` and `win-back-offers prices list`. They called Apple without a `limit` and read one page, so any territory past Apple's default 50 was missing. They now request `limit=200` and follow every page through a shared `APIClient.requestAllPages(_:nextCursor:)` helper, which `subscription-price-schedule get` uses too.
- **Offer price lists now show each price's territory and price point** — `iap-offer-codes prices list`, `subscription-offer-codes prices list`, `subscription-promotional-offers prices list` and `win-back-offers prices list` returned entries with only `id` and the offer ID, because Apple sends a price's territory and price point only when the request asks for them with `include=`. The requests now include both, so `territory` and the price-point ID are filled in, over CLI and REST.
- **More list commands no longer stop at Apple's first page** — `reviews list`, `devices list`, `bundle-ids list`, `profiles list` (with and without `--bundle-id-id`), `users list`, `versions list`, `builds uploads list`, `xcode-cloud builds list` and `diagnostics list` read a single page with no `limit`, so anything past Apple's default page size (50 for most endpoints, 20 for bundle IDs) was silently dropped. They now request `limit=200` and follow every page through `APIClient.requestAllPages`. On a real account, `builds uploads list` went from 50 to 122 entries and `bundle-ids list` from 20 to 85.
- **`profiles list` shows each profile's bundle ID again** — without `--bundle-id-id`, every profile came back with `bundleIdId: ""` (and a broken `listProfiles` affordance), because the bundle ID linkage is only returned when the request asks for it with `include=bundleId`. The request now includes it.

---

## [0.18.3] - 2026-09-22

### Added
- **Product Page Optimization tests** — `asc experiments list|get|create|update|start|stop|delete`, `asc experiment-treatments list|create|update|delete`, and `asc experiment-treatment-localizations list|create|delete` manage App Store product page A/B tests (ASC API `appStoreVersionExperiments` v2). A test is app-scoped; `create` takes `--name`, `--platform` and `--traffic-proportion 1-100`; `start`/`stop` map to `PATCH { started: true|false }`. New `AppStoreVersionExperiment` (+ `AppStoreVersionExperimentState` with `isEditable`/`isPendingReview`/`isApproved`/`isFinished`, and `isRunning`/`canStart` on the model), `ExperimentTreatment` and `ExperimentTreatmentLocalization` domain types in `Domain/Apps/Experiments/`, backed by `ExperimentRepository`. Affordances are state-aware: `createTreatment`/`update`/`delete` only while editable, `start` only when approved and unstarted, `stop` only while running. `App` gains a `listExperiments` affordance for discovery. REST equivalents under `/api/v1/apps/:appId/experiments`, `/api/v1/experiments/:id[/start|/stop|/experiment-treatments]`, `/api/v1/experiment-treatments/:id[/experiment-treatment-localizations]` and `/api/v1/experiment-treatment-localizations/:id` via `ExperimentsController`. See `docs/features/product-page-optimization/README.md`.

---

## [0.18.2] - 2026-07-16

### Added
- **`asc iris resolution-center get --submission-id <id> [--plain-text]`** — reads App Review's Resolution Center for a review submission: the reviewer's actual rejection message text plus structured rejection reasons (guideline section/description/code). This data has no official App Store Connect API surface (Apple's OpenAPI spec contains no `resolutionCenter*`/`reviewRejection*` paths); the command composes three iris private-API calls (`resolutionCenterThreads` → `resolutionCenterMessages?include=fromActor,rejections` → `reviewRejections`) behind cookie auth, mirroring the existing iris/official split (`asc iap submit` vs `asc iris iap-submissions`). `--plain-text` converts HTML message bodies to terminal-friendly text. New `ResolutionCenterDetail`/`ResolutionCenterMessage`/`ReviewRejectionReason` domain types and `IrisResolutionCenterRepository` in `Domain/Iris/ResolutionCenter/`. Discovery is wired via CAEOAS: `ReviewSubmission` (when `hasIssues`) and `ReviewSubmissionItem` (when `isRejected`) now expose a `getResolutionDetails` affordance pointing at the iris command — the official-API commands stay zero-iris. REST equivalent: `GET /api/v1/iris/review-submissions/:id/resolution-center?plain-text=true` via `IrisResolutionCenterController`. Attachments App Review adds to messages are listed in the detail (`attachments[]` with `fileName`/`fileSize`/`downloadUrl`) and downloadable with `--out <dir>`; downloads are gated to https on Apple/CDN hosts (`ResolutionCenterAttachment.isValidDownloadURL`). See `docs/features/resolution-center/README.md`.

---

## [0.18.1] - 2026-05-31

### Added
- **`asc sales-reports summary --from <date> --to <date>`** — aggregates daily Sales reports across a date range into a single rollup with derived metrics: `downloads` (first installs of phone/Mac apps, excluding Apple Watch `3F` redownloads), `updates`, `inAppPurchases`, `payers` (distinct SKUs with non-zero customer price), `customerSpend` (per `Customer Currency`, since `Customer Price` is in customer-local currency and cross-currency summing is meaningless), `proceeds` (per `Currency of Proceeds`, the developer's actual payout). CLI-only like the other report commands.
- **`asc sales-reports download --version <schema>`** — exposes Apple's `filter[version]` query parameter on `/v1/salesReports`. Previously omitted by `SDKReportRepository`, so Apple always returned its default schema. Invalid values now surface Apple's helpful `PARAMETER_ERROR.INVALID` message naming the latest supported version (e.g. `1_1` for `SALES/SUMMARY/DAILY`). `ReportRepository.downloadSalesReport` gains a trailing `version: String?` parameter; pass `nil` to keep the previous default behavior.
- **`asc review-submissions get --submission-id <id>` and `asc review-submissions items list --submission-id <id> [--state <ITEM_STATE>]`** — drill into a review submission to find *which* attached item Apple rejected. The new `items list` subcommand surfaces per-item state (`READY_FOR_REVIEW`/`ACCEPTED`/`APPROVED`/`REJECTED`/`REMOVED`) and the linked resource id (typically the rejected `AppStoreVersion`), so an agent can navigate from an `UNRESOLVED_ISSUES` submission to the offending version with one call. `ReviewSubmission` gains `getSubmission`/`listItems` affordances on every record and a conditional `listRejectedItems` affordance when `hasIssues == true`. New `ReviewSubmissionItem` + `ReviewSubmissionItemState` + `ReviewSubmissionItemLinkedResource` domain types in `Domain/Submissions/`; `SubmissionRepository` gains `getSubmission(id:)` and `listSubmissionItems(submissionId:)`. REST equivalents: `GET /api/v1/review-submissions/:id` and `GET /api/v1/review-submissions/:id/items?state=REJECTED` via `ReviewSubmissionsController`. Note: Apple's free-text rejection reasoning still lives only in App Store Connect's Resolution Center web UI — the public API exposes the state machine, not the narrative. See `docs/features/review-submissions/README.md`.

### Fixed
- **`asc app-availability get` no longer crashes with `PARAMETER_ERROR.INVALID` ("maximum allowable limit is '50'")** — Apple caps `include=territoryAvailabilities` on `/v1/apps/{id}/appAvailabilityV2` at 50 entries, and silently truncates relationship includes regardless. `SDKAppAvailabilityRepository.getAppAvailability` now matches the iOS-SDK multi-call pattern documented in CLAUDE.md: one call to the parent for `availableInNewTerritories` (no `include`), then a second call to the dedicated `/v2/appAvailabilities/{id}/territoryAvailabilities` endpoint with `limit: 200` for the full territory list. Added a regression test that round-trips 175 territories.

---

## [0.18.0] - 2026-05-13

### Added
- **`asc versions update` now accepts `--copyright`, `--release-type`, and `--earliest-release-date`** — closes the App Store submission gap where the version's copyright line, release type (`MANUAL` / `AFTER_APPROVAL` / `SCHEDULED`), and earliest release date could only be set via the web. The underlying `VersionRepository.updateVersion(...)` already supported these fields; the CLI now wires them through. `--version` is now optional, so any subset of these fields can be patched independently (e.g. `asc versions update --version-id v-1 --copyright "© 2026 Acme"`).

## Older releases

[0.17](docs/changelog/0.17.md) · [0.16](docs/changelog/0.16.md) · [0.1](docs/changelog/0.1.md)

[Unreleased]: https://github.com/tddworks/asc-cli/compare/v0.18.4...HEAD
[0.18.4]: https://github.com/tddworks/asc-cli/compare/v0.18.3...v0.18.4
[0.18.3]: https://github.com/tddworks/asc-cli/compare/v0.18.2...v0.18.3
[0.18.2]: https://github.com/tddworks/asc-cli/compare/v0.18.1...v0.18.2
[0.18.1]: https://github.com/tddworks/asc-cli/compare/v0.18.0...v0.18.1
[0.18.0]: https://github.com/tddworks/asc-cli/compare/v0.17.9...v0.18.0
