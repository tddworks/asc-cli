# asc-swift

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

### Command Affordances

The CLI equivalent of REST HATEOAS. Every response includes an `affordances` field with ready-to-run commands for the next step — agents navigate without memorising the command tree.

```json
{
  "id": "v1",
  "appId": "app-abc",
  "versionString": "2.1.0",
  "platform": "IOS",
  "state": "READY_FOR_SALE",
  "isLive": true,
  "affordances": {
    "listLocalizations": "asc localizations list --version-id v1",
    "listVersions":      "asc versions list --app-id app-abc"
  }
}
```

The agent reads `affordances.listLocalizations` and executes it. No API knowledge required. State-aware: affordances only appear when valid (e.g. `submit` only when `isEditable == true`).

## Features

- **Agent-first JSON output** — complete models with parent IDs and semantic booleans
- **Command Affordances** — HATEOAS for CLI: responses tell agents what to run next
- **Full resource hierarchy** — Apps → Versions → Localizations → Screenshot Sets → Screenshots
- **TUI mode** — interactive terminal UI for human browsing
- **Swift 6.2** — strict concurrency, async/await throughout
- **Clean architecture** — Domain / Infrastructure / Command layers

## Requirements

- macOS 13+
- Swift 6.2+
- App Store Connect API key ([create one here](https://appstoreconnect.apple.com/access/integrations/api))

## Installation

```bash
git clone https://github.com/tddworks/asc-swift.git
cd asc-swift
swift build -c release
cp .build/release/asc /usr/local/bin/
```

## Authentication

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"

asc auth check
```

## Usage

### Resource Hierarchy

Commands follow the App Store Connect resource hierarchy:

```
asc apps list
asc versions list --app-id <id>
asc localizations list --version-id <id>
asc screenshot-sets list --localization-id <id>
asc screenshots list --set-id <id>
asc builds list [--app-id <id>]
asc testflight groups  [--app-id <id>]
asc testflight testers [--group-id <id>]
```

### Agent Workflow Example

```bash
# 1. Find your app
asc apps list
# → includes affordances.listVersions for each app

# 2. Get versions (one per platform: iOS, macOS, …)
asc versions list --app-id APP_ID
# → includes affordances.listLocalizations for each version

# 3. Get localizations
asc localizations list --version-id VERSION_ID

# 4. Get screenshot sets for a localization
asc screenshot-sets list --localization-id LOC_ID

# 5. Get screenshots in a set
asc screenshots list --set-id SET_ID
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

## Development

```bash
swift build          # Build
swift test           # Run tests (95 tests, Chicago School TDD)
```

## Architecture

```
Sources/
├── Domain/       # Value types, repository protocols, rich domain models
├── Infrastructure/  # SDK adapters (appstoreconnect-swift-sdk)
└── ASCCommand/   # CLI commands + TUI
```

See [docs/desgin.md](docs/desgin.md) for full architecture documentation including the Command Affordances pattern.

## Dependencies

- [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk) — App Store Connect API
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) — CLI parsing
- [TauTUI](https://github.com/steipete/TauTUI) — Terminal UI framework
- [Mockable](https://github.com/Kolos65/Mockable) — Protocol mocking for tests

## License

MIT
