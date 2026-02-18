# Design: asc-swift

A Swift CLI and interactive TUI for App Store Connect, built for **agent-first use** on a clean three-layer architecture.

## Design Philosophy: Agent-First CLI

The primary consumer of this CLI is an **AI agent**, not a human typing at a shell. This shapes every design decision:

| Concern | Human CLI | Agent CLI (this project) |
|---------|-----------|--------------------------|
| Output format | Pretty tables | JSON (default) |
| Errors | Readable prose | Structured JSON |
| Field coverage | Display-friendly subset | Complete — agents read everything |
| Response content | Data only | Data + what to do next |
| Enum values | Display names | Raw API strings + semantic booleans |
| Parent IDs | Implied by context | Explicit in every response |

### Rich Domain Models

Domain models are **complete and semantic** — not display-optimised. Every model:

- Carries its **parent ID** so agents can correlate responses without re-querying
- Exposes **semantic boolean properties** that agents use for decisions (`isLive`, `isEditable`, `isPending`, `isComplete`)
- Uses **raw API enum strings** as the Codable representation for stability

```
// Agents can answer "should I submit this version?" without extra calls:
version.isEditable  // true when state allows editing
version.isPending   // true when waiting on Apple — agent should wait, not act
version.isLive      // true when on the App Store
```

### Resource Hierarchy

Commands mirror the App Store Connect API hierarchy exactly:

```
App
└── AppStoreVersion  (platform: iOS/macOS/tvOS/watchOS/visionOS)
    └── AppStoreVersionLocalization  (locale: en-US, zh-Hans, …)
        └── AppScreenshotSet  (displayType: iPhone 6.7", iPad 12.9", …)
            └── AppScreenshot
```

Each level has its own command:
```
asc apps list
asc versions list --app-id <id>
asc localizations list --version-id <id>
asc screenshot-sets list --localization-id <id>
asc screenshots list --set-id <id>
```

---

## Command Affordances

**Command Affordances** is this project's CLI equivalent of REST HATEOAS.

In REST, HATEOAS (Hypermedia as the Engine of Application State) embeds URLs in responses so clients can navigate without knowing the API structure upfront. In CLI, **Command Affordances** embeds ready-to-run commands in responses so agents can navigate without memorising the command tree.

| REST HATEOAS | CLI Command Affordances |
|---|---|
| Embeds `_links` with URLs | Embeds `affordances` with CLI commands |
| Client follows a URL | Agent executes a command |
| Drives HTTP state transitions | Drives CLI navigation |

### Example

An agent calls `asc versions list --app-id app-abc` and receives:

```json
{
  "data": [
    {
      "id": "v1",
      "appId": "app-abc",
      "versionString": "2.1.0",
      "platform": "IOS",
      "state": "READY_FOR_SALE",
      "isLive": true,
      "isEditable": false,
      "isPending": false,
      "affordances": {
        "listLocalizations": "asc localizations list --version-id v1",
        "listVersions":      "asc versions list --app-id app-abc"
      }
    }
  ]
}
```

The agent reads `affordances.listLocalizations` and executes it directly — no command-tree knowledge required.

### Properties of Command Affordances

1. **Self-describing** — the response tells the agent what it can do next
2. **State-aware** — affordances reflect the resource's current state (e.g. `submit` only appears when `isEditable == true`)
3. **Copy-paste ready** — values are literal CLI strings that work immediately

### Implementation

`Affordances` is a protocol that domain-layer response types adopt. Each resource computes its own affordances from its ID fields and state:

```swift
protocol AffordanceProviding {
    var affordances: [String: String] { get }
}

extension AppStoreVersion: AffordanceProviding {
    var affordances: [String: String] {
        var cmds = [
            "listLocalizations": "asc localizations list --version-id \(id)",
            "listVersions":      "asc versions list --app-id \(appId)",
        ]
        if isEditable {
            cmds["submitForReview"] = "asc versions submit --version-id \(id)"
        }
        return cmds
    }
}
```

---

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
| `Apps/` | `App`, `AppStoreVersion` (+ `AppStorePlatform`, `AppStoreVersionState`), `AppRepository` protocol |
| `Builds/` | `Build` model (version, state, expired), `BuildRepository` protocol |
| `TestFlight/` | `BetaGroup`, `BetaTester` models, `TestFlightRepository` protocol |
| `Screenshots/` | `AppStoreVersionLocalization`, `AppScreenshotSet`, `AppScreenshot`, `ScreenshotDisplayType` (32 display types), `ScreenshotRepository` protocol |
| `Auth/` | `AuthCredentials` value object, `AuthProvider` protocol, `AuthError` enum |
| `Shared/` | `PaginatedResponse<T>`, `OutputFormat` enum, `APIError` |

**Key domain design rules:**

- Every model carries its **parent ID** (e.g. `AppStoreVersion.appId`, `AppScreenshot.setId`)
- State enums expose **semantic booleans** (`isLive`, `isEditable`, `isPending`, `isComplete`)
- All models are `Sendable`, `Equatable`, `Codable` — the JSON encoding IS the public schema

### Infrastructure Layer

Implements Domain protocols using [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk).

| File | Role |
|------|------|
| `Auth/EnvironmentAuthProvider.swift` | Resolves credentials from environment variables |
| `Apps/OpenAPIAppRepository.swift` | `AppRepository` — injects `appId` into each mapped `AppStoreVersion` |
| `Builds/OpenAPIBuildRepository.swift` | `BuildRepository` implementation |
| `TestFlight/OpenAPITestFlightRepository.swift` | `TestFlightRepository` implementation |
| `Screenshots/OpenAPIScreenshotRepository.swift` | `ScreenshotRepository` — injects parent IDs at each level |
| `Client/ClientFactory.swift` | Wires authenticated client from `AuthProvider` |

Mappers always inject the parent ID from the request parameter into the response models, since the App Store Connect API does not include parent IDs in response bodies.

### ASCCommand Layer (CLI + TUI)

#### CLI Commands

```
asc
├── apps list                                         # List apps
├── versions list --app-id <id>                       # List App Store versions (per platform)
├── localizations list --version-id <id>             # List localizations for a version
├── screenshot-sets list --localization-id <id>      # List screenshot sets
├── screenshots list --set-id <id>                   # List screenshots in a set
├── builds list [--app-id <id>]                      # List builds
├── testflight
│   ├── groups  [--app-id <id>]                      # List beta groups
│   └── testers [--group-id <id>]                    # List beta testers
├── auth check                                        # Verify credentials
├── version                                           # Print version
└── tui                                               # Launch interactive TUI
```

Key files:
- `ASC.swift` — `@main` entry point, registers all subcommands
- `GlobalOptions.swift` — `--output`, `--pretty`, `--timeout` flags (default output: JSON)
- `OutputFormatter.swift` — JSON / table / markdown rendering
- `ClientProvider.swift` — Factory for authenticated repository instances

#### TUI Mode (`asc tui`)

Interactive terminal UI built with [TauTUI](https://github.com/steipete/TauTUI). Purely a presentation layer — reuses the same Domain protocols and Infrastructure implementations as the CLI.

Navigation follows the real App Store Connect resource hierarchy:

```
Main Menu
├── Apps List
│   └── App Menu (Info | Screenshots)
│       └── Screenshots → Version List (iOS 2.1.0 / macOS 1.5.0 / …)
│           └── Localization List (en-US / zh-Hans / …)  [auto-skips if one locale]
│               └── Screenshot Sets List (iPhone 6.7" / iPad 12.9" / …)
│                   └── Screenshots (filename, size, state)
├── Builds List → Build Detail
└── TestFlight Menu → Beta Groups / Beta Testers
```

---

## Testing

Chicago School TDD — state-based, not interaction-based. Tests verify what domain objects **return and compute**, not how they call collaborators.

```
Tests/
├── DomainTests/
│   ├── Apps/         # AppTests, AppStoreVersionTests, AppStoreVersionStateTests, AppRepositoryTests
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

Test naming: backtick style (`func \`version is live when state is readyForSale\`()`). Mocking: `@Mockable` + `given().willReturn()`.

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
