# asc-swift

A Swift CLI and interactive TUI for [App Store Connect](https://appstoreconnect.apple.com). Browse apps, builds, and TestFlight data from your terminal.

## Features

- **CLI mode** -- JSON, table, and markdown output for scripting and automation
- **TUI mode** -- Interactive terminal UI for browsing without memorizing flags
- **Swift 6.2** -- Full strict concurrency, async/await throughout
- **Clean architecture** -- Domain / Infrastructure / Command layers with protocol-based design

## Requirements

- macOS 13+
- Swift 6.2+
- App Store Connect API key ([create one here](https://appstoreconnect.apple.com/access/integrations/api))

## Installation

```bash
git clone https://github.com/tddworks/asc-swift.git
cd asc-swift
swift build
```

The binary is at `.build/debug/asc`, or install it:

```bash
swift build -c release
cp .build/release/asc /usr/local/bin/
```

## Authentication

Set these environment variables with your App Store Connect API key:

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
```

Verify your credentials:

```bash
asc auth check
```

## Usage

### CLI Mode

```bash
# List apps
asc apps list
asc apps list --output table --pretty
asc apps list --output markdown --limit 10

# List builds
asc builds list
asc builds list --app APP_ID --output table

# TestFlight
asc testflight groups --app APP_ID
asc testflight testers --group GROUP_ID

# Check version
asc version
```

**Output formats:**

| Format | Flag | Description |
|--------|------|-------------|
| JSON | `--output json` (default) | Minified JSON |
| Table | `--output table` | Aligned columns |
| Markdown | `--output markdown` | Markdown table |

Add `--pretty` for pretty-printed JSON.

### TUI Mode

```bash
asc tui
```

Navigate interactively:

- **Arrow keys** -- move selection
- **Enter** -- drill into item
- **Escape** -- go back
- **Quit** menu item -- exit

The TUI displays a main menu with Apps, Builds, TestFlight, and Quit. Select a category to browse your data, drill into details, and press Escape to navigate back.

## Development

```bash
make build    # Build
make test     # Run tests
make format   # Format code
make clean    # Clean build artifacts
make dev      # Build and show help
make run ARGS="apps list --output table"  # Run with arguments
```

## Architecture

```
Sources/
├── Domain/           # Models, protocols (App, Build, BetaGroup, BetaTester)
├── Infrastructure/   # API client implementations (appstoreconnect-swift-sdk)
└── ASCCommand/       # CLI commands + TUI (swift-argument-parser, TauTUI)
```

See [desgin.md](desgin.md) for detailed architecture documentation.

## Dependencies

- [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk) -- App Store Connect API
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) -- CLI parsing
- [TauTUI](https://github.com/steipete/TauTUI) -- Terminal UI framework
- [Mockable](https://github.com/Kolos65/Mockable) -- Protocol mocking for tests

## License

MIT
