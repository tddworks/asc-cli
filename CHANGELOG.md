# Changelog

All notable changes to asc-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/tddworks/asc-cli/compare/v0.1.24...HEAD
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
