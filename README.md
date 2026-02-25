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
- **Create & submit** — create versions, localizations, screenshot sets; upload screenshots; submit for App Store review
- **TestFlight** — list beta groups and testers
- **TUI mode** — interactive terminal UI for human browsing
- **Swift 6.2** — strict concurrency, async/await throughout
- **Clean architecture** — Domain / Infrastructure / Command layers

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
asc apps list                                              # list all apps
asc versions list --app-id <id>                           # list versions for an app
asc versions create --app-id <id> --version <v> --platform ios
asc versions submit --version-id <id>                     # submit for App Store review

# Localizations
asc version-localizations list --version-id <id>
asc version-localizations create --version-id <id> --locale zh-Hans
asc version-localizations update --localization-id <id> --whats-new "Bug fixes"

# Screenshots
asc screenshot-sets list --localization-id <id>
asc screenshot-sets create --localization-id <id> --display-type APP_IPHONE_67
asc screenshots list --set-id <id>
asc screenshots upload --set-id <id> --file ./screen.png

# App Info
asc app-infos list --app-id <id>
asc app-info-localizations list --app-info-id <id>
asc app-info-localizations create --app-info-id <id> --locale zh-Hans --name "我的应用"
asc app-info-localizations update --localization-id <id> --name "My App" --subtitle "Do things faster"

# Other
asc builds list [--app-id <id>]
asc testflight groups [--app-id <id>]
asc testflight testers --group-id <id>
asc tui                                                    # interactive browser
```

### Agent Workflow Example

```bash
# 0. One-time setup — no env vars needed after this
asc auth login --key-id KEY --issuer-id ISSUER --private-key-path ~/.asc/AuthKey_KEY.p8

# 1. Find your app — response includes affordances.listVersions and affordances.listAppInfos
asc apps list

# 2. List versions for a platform
asc versions list --app-id APP_ID

# 3. Navigate to localizations (command is in the version affordances)
asc version-localizations list --version-id VERSION_ID

# 4. Browse screenshot sets and upload new screenshots
asc screenshot-sets list --localization-id LOC_ID
asc screenshots upload --set-id SET_ID --file ./hero.png

# 5. Update What's New text for each locale
asc version-localizations update --localization-id LOC_ID --whats-new "Bug fixes and performance improvements"

# 6. Update app name / subtitle per locale
asc app-infos list --app-id APP_ID
asc app-info-localizations update --localization-id LOC_ID --name "My App" --subtitle "Do things faster"

# 7. Submit for review
asc versions submit --version-id VERSION_ID
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
- [Version Localizations](docs/features/version-localizations.md) — updating What's New, description, keywords, and URLs
- [Screenshots](docs/features/screenshots.md) — listing, creating sets, uploading images
- [App Info Localizations](docs/features/app-info-localizations.md) — managing per-locale name, subtitle, and privacy policy

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
