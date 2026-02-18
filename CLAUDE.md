# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build
swift build                  # Debug build
swift build -c release       # Release build

# Test
swift test                               # All tests
swift test --filter 'AppTests'           # Tests matching a pattern
swift test --enable-code-coverage        # With coverage

# Format
swift format --in-place --recursive Sources Tests

# Run
swift run asc <args>
make run ARGS="apps list"
```

## Architecture

Three strict layers with a unidirectional dependency flow: `ASCCommand → Infrastructure → Domain`

```
Sources/
├── Domain/        # Pure value types, @Mockable protocols — zero I/O
├── Infrastructure/# Implements Domain protocols via appstoreconnect-swift-sdk
└── ASCCommand/    # CLI entry point, output formatting, TUI
```

### Domain Layer

All models are `public struct` + `Sendable` + `Equatable` + `Codable`. The JSON encoding is the public schema.

**Design rules:**
- Every model carries its **parent ID** (e.g. `AppStoreVersion.appId`, `AppScreenshot.setId`) — the App Store Connect API doesn't return parent IDs, so Infrastructure injects them
- State enums expose **semantic booleans** (`isLive`, `isEditable`, `isPending`, `isComplete`) for agent decision-making
- All repositories and providers are `@Mockable` protocols

### Infrastructure Layer

Adapts `appstoreconnect-swift-sdk` to Domain protocols. The critical pattern: mappers always inject the parent ID from the request parameter into every mapped response object.

### ASCCommand Layer

- `ASC.swift` — `@main` entry, registers all subcommands
- `GlobalOptions.swift` — `--output` (default: json), `--pretty`, `--timeout`
- `OutputFormatter.swift` — JSON/table/markdown rendering; `formatAgentItems()` merges affordances
- `ClientProvider.swift` — factory wiring auth → authenticated repositories

## Key Design Patterns

### CAEOAS (Commands As the Engine Of Application State)

CLI equivalent of REST HATEOAS. Every response includes an `affordances` field with ready-to-run CLI commands so an AI agent can navigate without knowing the command tree. Affordances are **state-aware** — e.g. `submitForReview` only appears when `isEditable == true`.

All domain models implement `AffordanceProviding`:
```swift
protocol AffordanceProviding {
    var affordances: [String: String] { get }
}
```

`OutputFormatter.formatAgentItems()` merges affordances into the encoded JSON output.

### Resource Hierarchy

Commands mirror the App Store Connect API hierarchy exactly:
```
App → AppStoreVersion → AppStoreVersionLocalization → AppScreenshotSet → AppScreenshot
```

## Testing

Chicago School TDD — state-based, not interaction-based. Tests verify what domain objects return and compute, not how they call collaborators.
- If code can't be tested, that's a design problem, not a testing exception.
- Framework: Apple's `@Testing` macro (not XCTest)
- Mocking: `@Mockable` annotation on protocols + `given().willReturn()` in tests
- Test naming: backtick style — `` func `version is live when state is readyForSale`() ``
- `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` — shared test data factory

## Authentication

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
# OR use ASC_PRIVATE_KEY with the PEM content directly
```

Resolved by `EnvironmentAuthProvider` in Infrastructure.