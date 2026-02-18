# Design: asc-swift

A Swift CLI and interactive TUI for App Store Connect, built on a clean three-layer architecture.

## Architecture

```
Sources/
├── Domain/           # Pure business logic, protocols, rich models (zero deps except Mockable)
├── Infrastructure/   # Implementations: API client, auth provider
└── ASCCommand/       # CLI executable + TUI: argument parsing, output formatting, interactive UI
```

Dependency flow: `ASCCommand -> Infrastructure -> Domain`

### Domain Layer

Pure value types and `@Mockable` protocols. No networking, no frameworks.

| Directory | Contents |
|-----------|----------|
| `Auth/` | `AuthCredentials` value object, `AuthProvider` protocol, `AuthError` enum |
| `Apps/` | `App` model (id, name, bundleId, sku, locale), `AppRepository` protocol |
| `Builds/` | `Build` model (version, state, expired), `BuildRepository` protocol |
| `TestFlight/` | `BetaGroup`, `BetaTester` models, `TestFlightRepository` protocol |
| `Screenshots/` | `AppScreenshotSet`, `AppScreenshot`, `ScreenshotDisplayType` (32 display types), `ScreenshotRepository` protocol |
| `Shared/` | `PaginatedResponse<T>`, `OutputFormat` enum, `APIError` |

All repository protocols return `PaginatedResponse<T>` for list operations and throw on failure.

### Infrastructure Layer

Implements Domain protocols using [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk).

| File | Role |
|------|------|
| `Auth/EnvironmentAuthProvider.swift` | Resolves credentials from environment variables |
| `Apps/OpenAPIAppRepository.swift` | `AppRepository` implementation |
| `Builds/OpenAPIBuildRepository.swift` | `BuildRepository` implementation |
| `TestFlight/OpenAPITestFlightRepository.swift` | `TestFlightRepository` implementation |
| `Screenshots/OpenAPIScreenshotRepository.swift` | `ScreenshotRepository` implementation |
| `Client/ClientFactory.swift` | Wires authenticated client from `AuthProvider` |

### ASCCommand Layer (CLI + TUI)

#### CLI Commands

```
asc
├── apps list           # List apps (--output json|table|markdown, --pretty, --limit)
├── builds list         # List builds (--app, --limit)
├── testflight
│   ├── groups          # List beta groups (--app, --limit)
│   └── testers         # List beta testers (--group, --limit)
├── screenshots
│   ├── sets            # List screenshot sets for a localization (--localization)
│   └── list            # List screenshots in a set (--set)
├── auth check          # Verify credentials
├── version             # Print version
└── tui                 # Launch interactive TUI
```

Key files:
- `ASC.swift` -- `@main` entry point, registers all subcommands
- `GlobalOptions.swift` -- `--output`, `--pretty`, `--timeout` flags
- `OutputFormatter.swift` -- JSON / table / markdown rendering
- `ClientProvider.swift` -- Factory for authenticated repository instances

#### TUI Mode (`asc tui`)

Interactive terminal UI built with [TauTUI](https://github.com/steipete/TauTUI). Purely a presentation layer -- reuses the same Domain protocols and Infrastructure implementations as the CLI.

**Files:**

| File | Role |
|------|------|
| `Commands/TUI/TUICommand.swift` | `AsyncParsableCommand` entry point. Creates `ProcessTerminal`, `TUI`, `TUIApp`, starts event loop |
| `Commands/TUI/TUIApp.swift` | `@MainActor` navigation coordinator. Manages screen stack, component swapping, data loading |

**Navigation model:**

`TUIApp` uses a stack-based state machine with an `enum Screen`:

```
MainMenu ──Enter──> Apps List ──Enter──> App Detail
    │                   └──Escape──> MainMenu
    ├──Enter──> Builds List ──Enter──> Build Detail
    │               └──Escape──> MainMenu
    └──Enter──> TestFlight Menu ──Enter──> Beta Groups / Beta Testers
                    └──Escape──> MainMenu
```

- **Enter** drills into the selected item
- **Escape** pops back to the previous screen
- **Quit** menu item or Escape from main menu exits cleanly
- Arrow keys navigate within `SelectList` components

**Component lifecycle:**

1. `showScreen()` removes the current component from the TUI tree
2. For data screens (apps, builds, groups, testers): shows a loading `Text`, fires an async `Task` to fetch via the repository
3. On fetch completion: creates a `SelectList` from the data, calls `showComponent()` which adds it to the TUI tree, sets focus, and requests a re-render
4. Detail views use `EscapeWrapper` -- a thin `Component` that intercepts `.key(.escape)` and delegates rendering to an inner `Text`

**Clean shutdown:**

`TUIApp` stores a `CheckedContinuation` via `waitForExit()`. When the user quits, `quit()` calls `tui.stop()` and resumes the continuation, letting the `run()` method return normally.

## Testing

Swift Testing with backtick-style test names and `@Mockable` for protocol mocking.

```
Tests/
├── DomainTests/
│   ├── Apps/         # AppTests, AppRepositoryTests (with MockAppRepository)
│   ├── Builds/       # BuildTests
│   ├── Auth/         # AuthCredentialsTests
│   ├── Shared/       # PaginatedResponseTests
│   ├── Screenshots/  # ScreenshotDisplayTypeTests, AppScreenshotSetTests, AppScreenshotTests, ScreenshotRepositoryTests
│   └── TestHelpers/  # MockRepositoryFactory
├── InfrastructureTests/
│   └── Auth/         # EnvironmentAuthProviderTests
└── ASCCommandTests/
    └── OutputFormatterTests
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk) | Type-safe App Store Connect API client |
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | CLI argument parsing |
| [Mockable](https://github.com/Kolos65/Mockable) | Protocol mocking for tests |
| [TauTUI](https://github.com/steipete/TauTUI) | Component-based terminal UI framework |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ASC_KEY_ID` | API key ID |
| `ASC_ISSUER_ID` | Issuer ID |
| `ASC_PRIVATE_KEY_PATH` | Path to `.p8` private key file |
