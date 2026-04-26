# <img src="homepage/static/icon-192.png" width="36" height="36" valign="middle" alt=""> asc-cli

**App Store Command Center** — inspired by the Terran Command Center from StarCraft.

[![CI](https://github.com/tddworks/asc-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/tddworks/asc-cli/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/tddworks/asc-cli/graph/badge.svg?token=v0k1Vzubrx)](https://codecov.io/gh/tddworks/asc-cli)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/macOS-15%2B-blue)](https://www.apple.com/macos/)

A CLI for App Store Connect — automate builds, releases, TestFlight, subscriptions, and screenshots from your terminal or CI pipeline. Outputs structured JSON so AI agents can drive the full release workflow.

## Quick Start

```bash
brew install tddworks/tap/asccli

asc auth login \
  --key-id YOUR_KEY_ID \
  --issuer-id YOUR_ISSUER_ID \
  --private-key-path ~/.asc/AuthKey_XXXXXX.p8 \
  --name personal        # optional alias; defaults to "default"

asc apps list          # find your app ID
asc init --app-id <id> # pin it — skip --app-id on every future command
```

## Features

| Category | What you can do |
| --- | --- |
| **Apps & Versions** | List apps, create versions, link builds, submit for App Store review |
| **Builds** | Archive Xcode projects, export IPA/PKG, upload to App Store Connect, distribute to TestFlight, update beta notes |
| **Metadata** | Update What's New, description, and keywords per locale |
| **App Info** | Set per-locale name, subtitle, privacy policy; manage categories and age rating |
| **Screenshots** | Create screenshot sets and upload images |
| **App Previews** | Upload video previews (`.mp4`, `.mov`, `.m4v`) per locale and device size |
| **App Shots** | AI-powered screenshot generation — single templates, gallery sets, plugin-provided themes (colors, decorations, animations), Gemini enhancement; two-step ThemeDesign workflow for batch styling without extra AI calls |
| **TestFlight** | Manage beta groups; add/remove/import/export testers; submit builds for beta review |
| **Monetization** | IAPs (consumable, non-consumable, non-renewing); subscriptions, intro offers, **promotional offers**, **win-back offers**, offer codes (3-level), **promoted purchases**; full lifecycle (update/delete/unsubmit), per-territory pricing (with `proceedsYear2`), review screenshots, and 1024×1024 promotional images |
| **Code Signing** | Bundle IDs, certificates, devices, provisioning profiles |
| **Authentication** | Multi-account credential management; named accounts, active-account switching |
| **Project Init** | `asc init` pins app context to `.asc/project.json`; auto-detects from `.xcodeproj` |
| **Customer Reviews** | Read customer reviews, respond to feedback, and manage review responses |
| **App Clips** | Manage App Clips, default experiences, and locale-specific card content |
| **Game Center** | Manage achievements and leaderboards for your game |
| **Plugins** | Install executable plugins in `~/.asc/plugins/` for custom event handlers |
| **Reports** | Sales, subscription, installs, and financial reports; multi-step analytics workflow |
| **Iris (Private API)** | Cookie-based auth; create apps, list apps via the iris private API that powers the ASC web UI |
| **Simulators** | List, boot, shutdown local iOS simulators; streaming via plugin |
| **AI Agents** | JSON output with CAEOAS affordances — agents navigate without knowing the command tree |

## Requirements

- macOS 13+
- App Store Connect API key ([create one here](https://appstoreconnect.apple.com/access/integrations/api))
- Swift 6.2+ _(only needed when building from source)_

## Installation

### Homebrew (recommended)

```bash
brew install tddworks/tap/asccli
```

### Build from source

```bash
git clone https://github.com/tddworks/asc-cli.git
cd asc-cli
swift build -c release
cp .build/release/asc /usr/local/bin/
```

## Authentication

### Persistent login (recommended)

```bash
# Single account (saves as "default")
asc auth login \
  --key-id YOUR_KEY_ID \
  --issuer-id YOUR_ISSUER_ID \
  --private-key-path ~/.asc/AuthKey_XXXXXX.p8

# Multiple accounts
asc auth login --key-id K1 --issuer-id I1 --private-key-path work.p8 --name work
asc auth login --key-id K2 --issuer-id I2 --private-key-path personal.p8 --name personal

asc auth update --vendor-number 88012345  # save vendor number for reports
asc auth list            # list all saved accounts
asc auth use work        # switch active account
asc auth check           # → shows active account name + source: "file"
asc auth logout          # remove active account
asc auth logout --name personal  # remove a specific account
```

Credentials are saved to `~/.asc/credentials.json`. All `asc` commands use the active account automatically — no environment variables needed per session. Account names must not contain spaces.

### Environment variables (alternative)

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
# or: export ASC_PRIVATE_KEY="<PEM content>"
```

**Resolution order:** `~/.asc/credentials.json` → environment variables.

## Command Reference

### Auth & Project

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path <path> [--name alias] [--vendor-number <n>]
asc auth update [--name alias] --vendor-number <number>
asc auth list
asc auth use <name>
asc auth check
asc auth logout [--name alias]

asc init                     # auto-detect app from *.xcodeproj bundle ID
asc init --name "My App"     # search by name
asc init --app-id <id>       # pin directly — no API call needed
```

### Apps & Versions

```bash
asc apps list
asc versions list --app-id <id>
asc versions create --app-id <id> --version <v> --platform ios
asc versions set-build --version-id <id> --build-id <id>
asc versions check-readiness --version-id <id>
asc versions submit --version-id <id>
asc version-review-detail get --version-id <id>
asc version-review-detail update --version-id <id> --contact-first-name Jane --contact-email dev@example.com
```

### Builds & TestFlight

```bash
asc builds list [--app-id <id>] [--platform <ios|macos|tvos|visionos>] [--version <version>]
asc builds next-number --app-id <id> --version <version> --platform <platform>
asc builds archive --scheme MyApp [--platform ios] [--export-method app-store] [--upload --app-id <id> --version 1.0.0 --build-number 42]
asc builds upload --app-id <id> --file MyApp.ipa --version 1.0.0 --build-number 42
asc builds uploads list --app-id <id>
asc builds uploads get --upload-id <id>
asc builds uploads delete --upload-id <id>
asc builds add-beta-group --build-id <id> --beta-group-id <id>
asc builds remove-beta-group --build-id <id> --beta-group-id <id>
asc builds update-beta-notes --build-id <id> --locale en-US --notes "What's new"

asc testflight groups list [--app-id <id>]
asc testflight testers list --beta-group-id <id>
asc testflight testers add --beta-group-id <id> --email user@example.com
asc testflight testers remove --beta-group-id <id> --tester-id <id>
asc testflight testers import --beta-group-id <id> --file testers.csv
asc testflight testers export --beta-group-id <id>

asc beta-review submissions list --build-id <id>
asc beta-review submissions create --build-id <id>
asc beta-review submissions get --submission-id <id>
asc beta-review detail get --app-id <id>
asc beta-review detail update --detail-id <id> [--contact-first-name <name>] [--notes <text>]

asc review-submissions list --app-id <id> [--state WAITING_FOR_REVIEW,IN_REVIEW,READY_FOR_REVIEW] [--limit 200]
```

### Xcode Cloud

```bash
asc xcode-cloud products list [--app-id <id>]
asc xcode-cloud workflows list --product-id <id>
asc xcode-cloud builds list --workflow-id <id>
asc xcode-cloud builds get --build-run-id <id>
asc xcode-cloud builds start --workflow-id <id> [--clean]
```

### Customer Reviews

```bash
# List all reviews for an app
asc reviews list --app-id <id>

# Get a specific review
asc reviews get --review-id <id>

# Respond to a review
asc review-responses create --review-id <id> --response-body "Thank you for your feedback!"

# Get the response to a review
asc review-responses get --review-id <id>

# Delete a response
asc review-responses delete --response-id <id>
```

### Game Center

```bash
# Get Game Center configuration (detail-id needed for subsequent commands)
asc game-center detail get --app-id <id>

# Achievements
asc game-center achievements list --detail-id <id>
asc game-center achievements create --detail-id <id> --reference-name "First Steps" --vendor-identifier first_steps --points 10
asc game-center achievements create --detail-id <id> --reference-name <n> --vendor-identifier <v> --points <n> [--show-before-earned] [--repeatable]
asc game-center achievements delete --achievement-id <id>

# Leaderboards
asc game-center leaderboards list --detail-id <id>
asc game-center leaderboards create --detail-id <id> --reference-name "All Time High" --vendor-identifier all_time_high --score-sort-type DESC
asc game-center leaderboards create --detail-id <id> --reference-name <n> --vendor-identifier <v> --score-sort-type ASC|DESC [--submission-type BEST_SCORE|MOST_RECENT_SCORE]
asc game-center leaderboards delete --leaderboard-id <id>
```

### Power & Performance

```bash
# App-level performance metrics (launch time, hang rate, memory, etc.)
asc perf-metrics list --app-id <id>
asc perf-metrics list --app-id <id> --metric-type LAUNCH
asc perf-metrics list --build-id <id> --metric-type HANG

# Diagnostic signatures (hang/disk-write/launch hotspots)
asc diagnostics list --build-id <id>
asc diagnostics list --build-id <id> --diagnostic-type HANGS

# Diagnostic logs (call stacks for a signature)
asc diagnostic-logs list --signature-id <id>
```

### Metadata

```bash
# Version localizations (What's New, description, keywords)
asc version-localizations list --version-id <id>
asc version-localizations create --version-id <id> --locale zh-Hans
asc version-localizations update --localization-id <id> --whats-new "Bug fixes"

# App info localizations (name, subtitle, privacy policy)
asc app-infos list --app-id <id>
asc app-infos update --app-info-id <id> --primary-category GAMES --primary-subcategory-one GAMES_ACTION
asc app-categories list [--platform IOS]
asc app-info-localizations list --app-info-id <id>
asc app-info-localizations create --app-info-id <id> --locale zh-Hans --name "我的应用"
asc app-info-localizations update --localization-id <id> --name "My App" --subtitle "Do things faster"
asc app-info-localizations delete --localization-id <id>

# Age rating
asc age-rating get --app-info-id <id>
asc age-rating update --declaration-id <id> --violence-realistic NONE --gambling false --kids-age-band NINE_TO_ELEVEN
```

### Screenshots & Previews

```bash
# Screenshots
asc screenshot-sets list --localization-id <id>
asc screenshot-sets create --localization-id <id> --display-type APP_IPHONE_67
asc screenshots list --set-id <id>
asc screenshots upload --set-id <id> --file ./screen.png

# Video previews
asc app-preview-sets list --localization-id <id>
asc app-preview-sets create --localization-id <id> --preview-type IPHONE_67
asc app-previews list --set-id <id>
asc app-previews upload --set-id <id> --file ./preview.mp4 [--preview-frame-time-code 00:00:05]
```

### App Shots (AI screenshot generation)

Two modes: **Gallery** (all screenshots styled as a coordinated set) and **Single Template** (one screenshot at a time). Optional AI themes via plugins add colors, backgrounds, and floating decorations.

```bash
# --- Templates (single shot) ---
asc app-shots templates list                              # browse available templates
asc app-shots templates list --size portrait --output table
asc app-shots templates apply --id top-hero \
  --screenshot screen.png --headline "Ship Faster" \
  --preview html > preview.html && open preview.html      # preview in browser
asc app-shots templates apply --id top-hero \
  --screenshot screen.png --headline "Ship Faster" \
  --preview image --image-output marketing.png            # export to PNG

# --- Gallery templates (multi-screen sets) ---
asc app-shots gallery-templates list --output table
asc app-shots gallery-templates get --id neon-pop --preview > gallery.html && open gallery.html

# --- Gallery mode (all screenshots at once) ---
asc app-shots gallery create \
  --app-name "MyApp" \
  --screenshots screen-0.png screen-1.png screen-2.png

# --- Themes (plugin-provided, AI-powered styling) ---
asc app-shots themes list                                 # browse themes
asc app-shots themes get --id space --pretty              # theme detail
asc app-shots themes apply --theme space --template top-hero \
  --screenshot screen.png --headline "Ship Faster"        # AI-styled HTML

# Two-step workflow: generate ThemeDesign once, apply to many (no extra AI calls)
asc app-shots themes design --id luxury > design.json
asc app-shots themes apply-design --design design.json \
  --template top-hero --screenshot screen-0.png --headline "Feature 1" \
  --preview html > s0.html
asc app-shots themes apply-design --design design.json \
  --template top-hero --screenshot screen-1.png --headline "Feature 2" \
  --preview image --image-output s1.png

# --- Gemini AI enhancement ---
asc app-shots config --gemini-api-key KEY                 # save key once
asc app-shots generate --file screen.png                  # enhance with Gemini
asc app-shots generate --file screen.png --device-type APP_IPHONE_67
asc app-shots generate --file screen.png --style-reference ~/ref.png
```

### Monetization

Full IAP and subscription management — lifecycle, pricing, offer codes, promotional/win-back offers, review screenshots, promotional images, and App Store promoted slots. Every command also serves as a REST endpoint when running `asc web-server`. Affordances embedded in JSON output are state-aware — they only suggest the next legal action.

```bash
# Quick taste — see the linked docs for the full command surface.
asc iap list --app-id <id>
asc iap create --app-id <id> --reference-name "Gold Coins" --product-id "com.app.gold" --type consumable
asc iap submit --iap-id <id>

asc subscription-groups create --app-id <id> --reference-name "Premium"
asc subscriptions create --group-id <gid> --name "Monthly" --product-id "com.app.monthly" --period ONE_MONTH
asc subscriptions prices set --subscription-id <sub> --territory USA --price-point-id <pp>

asc promoted-purchases create --app-id <id> --iap-id <iap> --visible --enabled
```

| Area | Documentation |
|------|---------------|
| In-app purchases & subscriptions overview | [docs/features/iap-subscriptions.md](docs/features/iap-subscriptions.md) |
| Lifecycle (update / delete / unsubmit across IAP, subscription, group, intro offers) | [iap-subscriptions/lifecycle.md](docs/features/iap-subscriptions/lifecycle.md) |
| IAP base-territory pricing & subscription per-territory pricing (incl. `proceedsYear2`) | [iap-subscriptions/pricing.md](docs/features/iap-subscriptions/pricing.md) |
| Offer codes (3-level: code → custom → one-time + redemption CSV) | [iap-subscriptions/offer-codes.md](docs/features/iap-subscriptions/offer-codes.md) |
| Subscription group localizations (Custom App Name per locale) | [iap-subscriptions/group-localizations.md](docs/features/iap-subscriptions/group-localizations.md) |
| Promotional offers (in-app, with per-territory inline pricing) | [iap-subscriptions/promotional-offers.md](docs/features/iap-subscriptions/promotional-offers.md) |
| Win-back offers (lapsed subscribers, eligibility rules + priority) | [iap-subscriptions/win-back-offers.md](docs/features/iap-subscriptions/win-back-offers.md) |
| Review screenshots & 1024×1024 promotional images | [iap-subscriptions/review-assets.md](docs/features/iap-subscriptions/review-assets.md) |
| Promoted purchases (App Store product page slots) | [docs/features/promoted-purchases.md](docs/features/promoted-purchases.md) |
| Territory availability (apps, IAPs, subscriptions) | [docs/features/iap-subscription-availability.md](docs/features/iap-subscription-availability.md) |

### Code Signing

```bash
asc bundle-ids list [--platform ios|macos|universal] [--identifier com.example.app]
asc bundle-ids create --name "My App" --identifier com.example.app --platform ios
asc bundle-ids delete --bundle-id-id <id>

asc certificates list [--type IOS_DISTRIBUTION] [--limit 200] [--expired-only] [--before 2026-11-01T00:00:00Z]
asc certificates create --type IOS_DISTRIBUTION --csr-content "$(cat MyApp.certSigningRequest)"
asc certificates revoke --certificate-id <id>

asc devices list [--platform ios|macos]
asc devices register --name "My iPhone" --udid <udid> --platform ios

asc profiles list [--bundle-id-id <id>] [--type IOS_APP_STORE]
asc profiles create --name "My Profile" --type IOS_APP_STORE --bundle-id-id <id> --certificate-ids <id>
asc profiles delete --profile-id <id>
```

### Team Management

```bash
# List all team members
asc users list

# Filter by role
asc users list --role DEVELOPER --output table

# Update a member's roles
asc users update --user-id <id> --role APP_MANAGER --role DEVELOPER

# Revoke access (e.g. on offboarding)
asc users remove --user-id <id>

# List pending invitations
asc user-invitations list

# Invite a new member
asc user-invitations invite --email new@example.com --first-name Alex --last-name Smith --role DEVELOPER

# Cancel a pending invitation
asc user-invitations cancel --invitation-id <id>
```

### Reports

```bash
# Daily sales (latest — --report-date optional for DAILY only)
# --vendor-number auto-resolved from active account if saved via auth login/update
asc sales-reports download --report-type SALES --sub-type SUMMARY --frequency DAILY

# Weekly/monthly/yearly require --report-date
asc sales-reports download --report-type SUBSCRIPTION --sub-type SUMMARY --frequency MONTHLY --report-date 2024-01

# Financial report (--report-date always required)
asc finance-reports download --report-type FINANCIAL --region-code US --report-date 2024-01

# Explicit vendor number override
asc sales-reports download --vendor-number <n> --report-type SALES --sub-type SUMMARY --frequency DAILY

# Analytics (multi-step workflow)
asc analytics-reports request --app-id <id> --access-type ONE_TIME_SNAPSHOT
asc analytics-reports list --app-id <id>
asc analytics-reports reports --request-id <id> --category COMMERCE
asc analytics-reports instances --report-id <id> --granularity DAILY
asc analytics-reports segments --instance-id <id>
```

### Plugins

```bash
asc plugins list
asc plugins install ./my-plugin
asc plugins uninstall --name slack-notify
asc plugins enable --name slack-notify
asc plugins disable --name slack-notify
asc plugins run --name slack-notify --event build.uploaded
```

### Iris (Private API)

```bash
# Check cookie session status
asc iris status --pretty

# List apps via iris
asc iris apps list --pretty

# Create a new app
asc iris apps create --name "My App" --bundle-id com.example.app --sku com.example.app --pretty

# Multi-platform with custom version
asc iris apps create --name "My App" --bundle-id com.example.app --sku MYSKU \
  --platforms IOS MAC_OS --version 2.0
```

Authentication: log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) in your browser — cookies are extracted automatically. For CI/CD, set `ASC_IRIS_COOKIES`.

### Simulators

```bash
# List available iOS simulators
asc simulators list --output table
asc simulators list --booted --pretty

# Boot / shutdown
asc simulators boot --udid <udid>
asc simulators shutdown --udid <udid>

# Start web server (opens asccli.app/command-center)
asc web-server
```

Streaming and interaction available via the [ASC Pro plugin](docs/features/plugin-ui-architecture.md).

### Output & TUI

```bash
asc apps list                        # JSON (default)
asc apps list --output table         # aligned table
asc apps list --output markdown      # markdown table
asc apps list --output json --pretty # pretty-printed JSON

asc tui   # interactive browser — arrow keys, Enter to drill in, Escape to go back
```

## Release Workflow

A full App Store release from build upload to review submission:

```bash
# 1. Upload build and wait for processing
# Option A: Archive from Xcode project and upload in one step
asc builds archive --scheme MyApp --upload --app-id APP_ID --version 1.2.0 --build-number 55
# Option B: Upload a pre-built IPA/PKG
asc builds upload --app-id APP_ID --file ./MyApp.ipa --version 1.2.0 --build-number 55 --wait

# 2. Distribute to TestFlight
GROUP_ID=$(asc testflight groups list --app-id APP_ID | jq -r '.data[0].id')
BUILD_ID=$(asc builds list --app-id APP_ID | jq -r '.data[0].id')
asc builds add-beta-group --build-id "$BUILD_ID" --beta-group-id "$GROUP_ID"
asc builds update-beta-notes --build-id "$BUILD_ID" --locale en-US --notes "What's new in 1.2.0"

# 3. Prepare the App Store version
VERSION_ID=$(asc versions list --app-id APP_ID | jq -r '.data[0].id')
asc versions set-build --version-id "$VERSION_ID" --build-id "$BUILD_ID"

# 4. Update What's New
LOC_ID=$(asc version-localizations list --version-id "$VERSION_ID" | jq -r '.data[0].id')
asc version-localizations update --localization-id "$LOC_ID" --whats-new "Bug fixes and performance improvements"

# 5. Pre-flight check, then submit
asc versions check-readiness --version-id "$VERSION_ID" --pretty
asc versions submit --version-id "$VERSION_ID"
```

## Feature Guides

Detailed documentation for each feature:

- [Auth](docs/features/asc-auth.md) — multi-account credential management; login, list, use, logout, check
- [Version Localizations](docs/features/version-localizations.md) — What's New, description, keywords
- [Screenshots](docs/features/screenshots.md) — screenshot sets and image uploads
- [App Previews](docs/features/app-previews.md) — preview sets and video uploads
- [App Info](docs/features/app-infos.md) — name, subtitle, privacy policy, categories, age rating
- [TestFlight](docs/features/testflight.md) — beta groups, tester management, CSV import/export
- [Beta Review](docs/features/beta-review.md) — submit builds for beta app review, manage review contact details
- [Review Submissions](docs/features/review-submissions.md) — list App Store review submissions filtered by state
- [Xcode Cloud](docs/features/xcode-cloud.md) — products, workflows, build runs, start builds
- [Builds Archive](docs/features/builds-archive.md) — archive Xcode projects, export IPA/PKG, optional upload chaining
- [Builds Upload](docs/features/builds-upload.md) — upload IPA/PKG, TestFlight distribution, beta notes
- [Code Signing](docs/features/code-signing.md) — bundle IDs, certificates, devices, profiles
- [Version Check-Readiness](docs/features/version-check-readiness.md) — pre-flight submission checks
- [In-App Purchases & Subscriptions](docs/features/iap-subscriptions.md) — IAPs, subscriptions, offers, pricing
- [App Shots](docs/features/app-shots.md) — templates, galleries, Gemini enhancement, and export
- [App Shots Themes](docs/features/app-shots-themes.md) — plugin-provided visual themes with two-step ThemeDesign workflow
- [Plugins](docs/features/plugins.md) — custom event handlers (Slack, Telegram, webhooks)
- [App Wall](docs/features/app-wall.md) — community showcase; `apps.json` format and architecture
- [Users & Roles](docs/features/users.md) — team member management, role assignment, invitation lifecycle; directory integration for automated access control
- [Customer Reviews](docs/features/customer-reviews.md) — list reviews, respond to feedback, manage review responses
- [Game Center](docs/features/game-center.md) — achievements (list, create, delete) and leaderboards (list, create, delete)
- [Power & Performance](docs/features/performance.md) — performance metrics (app/build), diagnostic signatures, diagnostic logs
- [Reports](docs/features/reports.md) — sales, finance, and analytics reports; TSV parsing, multi-step analytics workflow
- [Iris (Private API)](docs/features/iris.md) — cookie-based auth; create apps, list apps via the iris private API
- [Simulators](docs/features/simulators.md) — list, boot, shutdown; streaming via plugin
- [Web Server](docs/features/web-server-architecture.md) — Hummingbird API server with plugin system
- [Plugins](docs/features/plugin-ui-architecture.md) — extend CLI with routes, commands, affordances, and UI

## Design: CAEOAS

REST has **HATEOAS** — responses embed URLs so clients navigate without knowing the API. This CLI has **CAEOAS** (Commands As the Engine Of Application State): responses embed ready-to-run CLI commands so agents navigate without memorising the command tree.

```bash
$ asc versions list --app-id app-abc
```

```jsonc
{
  "id": "v1",
  "versionString": "2.1.0",
  "state": "PREPARE_FOR_SUBMISSION",
  "isEditable": true,
  "affordances": {
    "listLocalizations": "asc version-localizations list --version-id v1",
    "checkReadiness":    "asc versions check-readiness --version-id v1",
    "submitForReview":   "asc versions submit --version-id v1"  // only when isEditable == true
  }
}
```

Affordances are state-aware — `submitForReview` only appears when `isEditable == true`. See [docs/design.md](docs/desgin.md) for the full pattern.

## Use as a Swift Package (SPM)

`asc-cli` exposes an `ASCKit` library product so you can embed App Store Connect automation directly into your own Swift tool, script, or app without using the CLI binary.

### Add the dependency

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tddworks/asc-cli.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "MyTool",
        dependencies: [
            .product(name: "ASCKit", package: "asc-cli"),
        ]
    ),
]
```

### Example usage

```swift
import Domain
import Infrastructure

// 1. Provide credentials (inline, env vars, or your own AuthProvider)
let credentials = AuthCredentials(
    keyID: "YOUR_KEY_ID",
    issuerID: "YOUR_ISSUER_ID",
    privateKeyPEM: """
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
    """
)

// 2. A simple inline AuthProvider that wraps fixed credentials
struct StaticAuthProvider: AuthProvider {
    let credentials: AuthCredentials
    func resolve() throws -> AuthCredentials { credentials }
}

// 3. Create any repository via ClientFactory
let factory = ClientFactory()
let authProvider = StaticAuthProvider(credentials: credentials)

let appRepo = try factory.makeAppRepository(authProvider: authProvider)
let apps = try await appRepo.listApps(limit: 50)
apps.data.forEach { print($0.name, $0.bundleID) }

// Build repository example
let buildRepo = try factory.makeBuildRepository(authProvider: authProvider)
let builds = try await buildRepo.listBuilds(appId: "YOUR_APP_ID", limit: 10)
```

### Available factories (ClientFactory)

`ClientFactory` provides a `make*` method for every domain area:

| Method | Repository protocol |
|--------|---------------------|
| `makeAppRepository` | `AppRepository` |
| `makeBuildRepository` | `BuildRepository` |
| `makeVersionRepository` | `VersionRepository` |
| `makeTestFlightRepository` | `TestFlightRepository` |
| `makeScreenshotRepository` | `ScreenshotRepository` |
| `makeAppInfoRepository` | `AppInfoRepository` |
| `makeSubmissionRepository` | `SubmissionRepository` |
| `makeInAppPurchaseRepository` | `InAppPurchaseRepository` |
| `makeSubscriptionRepository` | `SubscriptionRepository` |
| `makeGameCenterRepository` | `GameCenterRepository` |
| `makeUserRepository` | `UserRepository` |
| `makeReportRepository` / `makeAnalyticsReportRepository` | `ReportRepository` / `AnalyticsReportRepository` |
| `makeCustomerReviewRepository` | `CustomerReviewRepository` |
| `makeCertificateRepository` / `makeProfileRepository` / `makeDeviceRepository` | Code-signing repositories |
| `makeXcodeCloudProductRepository` | `XcodeCloudProductRepository` |
| … and more | see `Sources/Infrastructure/Client/ClientFactory.swift` |


## Development

```bash
swift build          # build
swift test           # run tests (Chicago School TDD)
swift format --in-place --recursive Sources Tests
```

**Architecture:**

```
Sources/
├── Domain/          # Pure value types, @Mockable protocols — zero I/O
├── Infrastructure/  # SDK adapters (appstoreconnect-swift-sdk), parent ID injection
└── ASCCommand/      # CLI commands, output formatting, TUI
```

Unidirectional dependency: `ASCCommand → Infrastructure → Domain`

**Dependencies:**
- [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk)
- [swift-argument-parser](https://github.com/apple/swift-argument-parser)
- [TauTUI](https://github.com/steipete/TauTUI)
- [Mockable](https://github.com/Kolos65/Mockable)
- [SweetCookieKit](https://github.com/steipete/SweetCookieKit)

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Sponsors

Apps that use and support asc-cli development:

<a href="https://appnexus.app">
  <img src="https://appnexus.app/favicon.ico" width="64" height="64" alt="AppNexus" style="border-radius:14px">
  <br>
  <b>AppNexus for App Store Connect</b>
</a>

## App Wall

Apps built and published using asc-cli. To add yours, edit [`homepage/apps.json`](homepage/apps.json) and open a pull request — see [docs/features/app-wall.md](docs/features/app-wall.md) for the format.

View the live wall at [asccli.app/#app-wall](https://asccli.app/#app-wall).

## License

MIT
