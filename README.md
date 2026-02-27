# asc-cli

[![CI](https://github.com/tddworks/asc-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/tddworks/asc-cli/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/tddworks/asc-cli/graph/badge.svg?token=v0k1Vzubrx)](https://codecov.io/gh/tddworks/asc-cli)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/macOS-15%2B-blue)](https://www.apple.com/macos/)

A Swift CLI and interactive TUI for [App Store Connect](https://appstoreconnect.apple.com), designed **agent-first** — structured for AI agents and automation, usable by humans too.

## Design Principles

### Agent-First Output

JSON is the default output format. Every response is complete: parent IDs, full state, and semantic booleans so agents can make decisions without extra round-trips.

```json
{
  "id": "v1",
  "appId": "app-abc",
  "versionString": "2.1.0",
  "platform": "IOS",
  "state": "READY_FOR_SALE",
  "isLive": true,
  "isEditable": false,
  "isPending": false
}
```

### CAEOAS — Commands As the Engine Of Application State

REST has **HATEOAS**: responses embed URLs so clients navigate without knowing the API upfront.
This CLI has **CAEOAS**: responses embed ready-to-run commands so agents navigate without memorising the command tree.

| | REST HATEOAS | CLI CAEOAS |
|---|---|---|
| Embed | `_links` with URLs | `affordances` with CLI commands |
| Client action | Follow a URL | Execute a command |
| Drives | HTTP state transitions | CLI navigation |

Every response includes an `affordances` field. Agents read it and execute — no API knowledge required:

```shell
$ asc versions list --app-id app-abc
```

```jsonc
{
  "id": "v1",
  "appId": "app-abc",
  "versionString": "2.1.0",
  "platform": "IOS",
  "state": "PREPARE_FOR_SUBMISSION",
  "isEditable": true,
  "affordances": {
    "listLocalizations": "asc version-localizations list --version-id v1",  // navigate down → localizations
    "listVersions":      "asc versions list --app-id app-abc",              // navigate up → sibling versions
    "checkReadiness":    "asc versions check-readiness --version-id v1",    // pre-flight submission check
    "submitForReview":   "asc versions submit --version-id v1"              // only present when isEditable == true
  }
}
```

**State-aware**: affordances reflect current state. `submitForReview` only appears when `isEditable == true` — the response itself tells the agent what's valid right now.

## Features

- **Agent-first JSON output** — complete models with parent IDs, semantic booleans, and state-aware affordances
- **CAEOAS** — responses tell agents exactly what to run next
- **Persistent auth** — `asc auth login` saves credentials to `~/.asc/credentials.json`; no env vars needed after setup
- **Full resource hierarchy** — Apps → Versions → Localizations → Screenshot Sets → Screenshots
- **Version localizations** — update What's New, description, keywords, and URLs per locale
- **App info localizations** — read and write per-locale name, subtitle, and privacy policy
- **Screenshots** — create screenshot sets and upload images (3-step ASC upload flow)
- **App Previews** — create preview sets and upload video previews (`.mp4`, `.mov`, `.m4v`) with optional thumbnail timecode
- **Create & submit** — create versions, link builds, check readiness, submit for App Store review
- **Builds upload** — upload IPA/PKG with 5-step flow; list/get/delete upload records
- **TestFlight** — list groups; add/remove/import/export testers; distribute builds to groups; update What's New notes
- **Code signing** — manage bundle IDs, certificates, devices, and provisioning profiles
- **In-App Purchases** — create and list IAPs; set per-territory pricing; submit for review; manage per-locale name and description
- **Subscriptions** — create subscription groups and tiers (weekly–yearly); manage per-locale name and description
- **Version readiness check** — pre-flight check aggregating all Apple submission requirements
- **TUI mode** — interactive terminal UI for human browsing
- **Swift 6.2** — strict concurrency, async/await throughout
- **Clean architecture** — Domain / Infrastructure / Command layers with Chicago School TDD

## Requirements

- macOS 13+
- Swift 6.2+
- App Store Connect API key ([create one here](https://appstoreconnect.apple.com/access/integrations/api))

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
asc auth login \
  --key-id YOUR_KEY_ID \
  --issuer-id YOUR_ISSUER_ID \
  --private-key-path ~/.asc/AuthKey_XXXXXX.p8

asc auth check   # → shows source: "file"
```

Credentials are saved to `~/.asc/credentials.json`. All `asc` commands pick them up automatically — no environment variables needed per session.

```bash
asc auth logout  # remove saved credentials
```

### Environment variables (alternative)

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
# or: export ASC_PRIVATE_KEY="<PEM content>"
```

**Resolution order:** `~/.asc/credentials.json` → environment variables.

## Usage

### Command Reference

```
# Auth
asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>
asc auth logout
asc auth check

# Apps & Versions
asc apps list                                                         # list all apps
asc versions list --app-id <id>                                       # list versions
asc versions create --app-id <id> --version <v> --platform ios        # create version
asc versions check-readiness --version-id <id>                        # pre-flight check
asc versions set-build --version-id <id> --build-id <id>             # link build
asc versions submit --version-id <id>                                 # submit for review

# Version Localizations
asc version-localizations list --version-id <id>
asc version-localizations create --version-id <id> --locale zh-Hans
asc version-localizations update --localization-id <id> --whats-new "Bug fixes"

# Screenshots
asc screenshot-sets list --localization-id <id>
asc screenshot-sets create --localization-id <id> --display-type APP_IPHONE_67
asc screenshots list --set-id <id>
asc screenshots upload --set-id <id> --file ./screen.png

# App Previews
asc app-preview-sets list --localization-id <id>
asc app-preview-sets create --localization-id <id> --preview-type IPHONE_67
asc app-previews list --set-id <id>
asc app-previews upload --set-id <id> --file ./preview.mp4 [--preview-frame-time-code 00:00:05]

# App Info
asc app-infos list --app-id <id>
asc app-info-localizations list --app-info-id <id>
asc app-info-localizations create --app-info-id <id> --locale zh-Hans --name "我的应用"
asc app-info-localizations update --localization-id <id> --name "My App" --subtitle "Do things faster"

# Builds
asc builds list [--app-id <id>]
asc builds upload --app-id <id> --file MyApp.ipa --version 1.0.0 --build-number 42
asc builds uploads list --app-id <id>
asc builds uploads get --upload-id <id>
asc builds uploads delete --upload-id <id>
asc builds add-beta-group --build-id <id> --beta-group-id <id>
asc builds remove-beta-group --build-id <id> --beta-group-id <id>
asc builds update-beta-notes --build-id <id> --locale en-US --notes "What's new"

# TestFlight
asc testflight groups list [--app-id <id>]
asc testflight testers list --beta-group-id <id>
asc testflight testers add --beta-group-id <id> --email user@example.com
asc testflight testers remove --beta-group-id <id> --tester-id <id>
asc testflight testers import --beta-group-id <id> --file testers.csv
asc testflight testers export --beta-group-id <id>

# In-App Purchases
asc iap list --app-id <id>
asc iap create --app-id <id> --reference-name <n> --product-id <id> --type consumable
asc iap submit --iap-id <id>
asc iap price-points list --iap-id <id> [--territory USA]
asc iap prices set --iap-id <id> --base-territory USA --price-point-id <id>
asc iap-localizations list --iap-id <id>
asc iap-localizations create --iap-id <id> --locale en-US --name <n>

# Subscriptions
asc subscription-groups list --app-id <id>
asc subscription-groups create --app-id <id> --reference-name <n>
asc subscriptions list --group-id <id>
asc subscriptions create --group-id <id> --name <n> --product-id <id> --period ONE_MONTH
asc subscription-localizations list --subscription-id <id>
asc subscription-localizations create --subscription-id <id> --locale en-US --name <n>
asc subscriptions submit --subscription-id <id>
asc subscription-offers list --subscription-id <id>
asc subscription-offers create --subscription-id <id> --duration ONE_MONTH --mode FREE_TRIAL --periods 1
asc subscription-offers create --subscription-id <id> --duration THREE_MONTHS --mode PAY_AS_YOU_GO --periods 3 --price-point-id <id>

# Code Signing
asc bundle-ids list [--platform ios|macos|universal] [--identifier com.example.app]
asc bundle-ids create --name "My App" --identifier com.example.app --platform ios
asc bundle-ids delete --bundle-id-id <id>
asc certificates list [--type IOS_DISTRIBUTION]
asc certificates create --type IOS_DISTRIBUTION --csr-content "$(cat MyApp.certSigningRequest)"
asc certificates revoke --certificate-id <id>
asc devices list [--platform ios|macos]
asc devices register --name "My iPhone" --udid <udid> --platform ios
asc profiles list [--bundle-id-id <id>] [--type IOS_APP_STORE]
asc profiles create --name "My Profile" --type IOS_APP_STORE --bundle-id-id <id> --certificate-ids <id>
asc profiles delete --profile-id <id>

# Interactive
asc tui                                                               # interactive browser
```

### Agent Workflow Example

```bash
# 0. One-time setup — no env vars needed after this
asc auth login --key-id KEY --issuer-id ISSUER --private-key-path ~/.asc/AuthKey_KEY.p8

# 1. Find your app — response includes affordances.listVersions and affordances.listAppInfos
asc apps list

# 2. Upload a build and wait for processing
asc builds upload --app-id APP_ID --file ./MyApp.ipa --version 1.2.0 --build-number 55 --wait

# 3. Distribute to TestFlight beta group
GROUP_ID=$(asc testflight groups list --app-id APP_ID | jq -r '.data[0].id')
BUILD_ID=$(asc builds list --app-id APP_ID | jq -r '.data[0].id')
asc builds add-beta-group --build-id "$BUILD_ID" --beta-group-id "$GROUP_ID"
asc builds update-beta-notes --build-id "$BUILD_ID" --locale en-US --notes "What's new in 1.2.0"

# 4. Prepare the App Store version
VERSION_ID=$(asc versions list --app-id APP_ID | jq -r '.data[0].id')
asc versions set-build --version-id "$VERSION_ID" --build-id "$BUILD_ID"

# 5. Update per-locale content
LOC_ID=$(asc version-localizations list --version-id "$VERSION_ID" | jq -r '.data[0].id')
asc version-localizations update --localization-id "$LOC_ID" --whats-new "Bug fixes and performance improvements"
asc screenshots upload --set-id SET_ID --file ./hero.png

# 6. Pre-flight check — affordances.submit appears only when isReadyToSubmit == true
asc versions check-readiness --version-id "$VERSION_ID" --pretty

# 7. Submit for review
asc versions submit --version-id "$VERSION_ID"
```

### Output Formats

```bash
asc apps list                        # JSON (default)
asc apps list --output table         # Aligned table
asc apps list --output markdown      # Markdown table
asc apps list --output json --pretty # Pretty-printed JSON
```

### TUI Mode

```bash
asc tui
```

Navigate interactively: **arrow keys** to move, **Enter** to drill in, **Escape** to go back.

## Feature Guides

Detailed documentation for each feature area:

- [Auth Login](docs/features/auth-login.md) — persistent credential storage, login/logout/check
- [Version Localizations](docs/features/version-localizations.md) — What's New, description, keywords, and URLs
- [Screenshots](docs/features/screenshots.md) — screenshot sets and image uploads
- [App Previews](docs/features/app-previews.md) — preview sets and video uploads (`.mp4`, `.mov`, `.m4v`)
- [App Info Localizations](docs/features/app-info-localizations.md) — per-locale name, subtitle, and privacy policy
- [TestFlight](docs/features/testflight.md) — beta groups, tester management, CSV import/export
- [Builds Upload](docs/features/builds-upload.md) — upload IPA/PKG, TestFlight distribution, beta notes
- [Code Signing](docs/features/code-signing.md) — bundle IDs, certificates, devices, profiles
- [Version Check-Readiness](docs/features/version-check-readiness.md) — pre-flight submission checks
- [In-App Purchases & Subscriptions](docs/features/iap-subscriptions.md) — IAPs, subscription groups, tiers, and per-locale metadata

## Development

```bash
swift build          # Build
swift test           # Run tests (226 tests, Chicago School TDD)
swift format --in-place --recursive Sources Tests  # Format
```

## Architecture

```
Sources/
├── Domain/          # Pure value types, @Mockable repository protocols — zero I/O
├── Infrastructure/  # SDK adapters (appstoreconnect-swift-sdk), parent ID injection
└── ASCCommand/      # CLI commands, output formatting, TUI
```

Unidirectional dependency: `ASCCommand → Infrastructure → Domain`

See [docs/desgin.md](docs/desgin.md) for the full architecture and CAEOAS pattern documentation.

## Dependencies

- [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk) — App Store Connect API
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) — CLI parsing
- [TauTUI](https://github.com/steipete/TauTUI) — Terminal UI framework
- [Mockable](https://github.com/Kolos65/Mockable) — Protocol mocking for tests

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Sponsors

Apps that use and support asc-cli development:

<a href="https://appnexus.app">
  <img src="https://appnexus.app/favicon.ico" width="64" height="64" alt="AppNexus" style="border-radius:14px">
  <br>
  <b>AppNexus for App Store Connect</b>
</a>

## License

MIT
