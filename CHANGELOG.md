# Changelog

All notable changes to asc-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/tddworks/asc-cli/compare/v0.1.53...HEAD
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
