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

All models are `public struct` + `Sendable` + `Equatable` + `Codable`. The JSON encoding is the public schema. Models with optional text fields use custom `Codable` with `encodeIfPresent` to omit nil values from JSON output.

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
- `Commands/Web/` — `asc web-server` serves the REST API; `RESTRoutes.configure` composes `*Controller` structs (Hummingbird). Every new list/read command **must** also be exposed here (see "REST exposure" below)

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

### REST exposure (every feature must ship both CLI and REST)

The `asc web-server` command exposes the same functionality as the CLI over HTTP so an agent can drive it as a REST service. **A feature is not complete until it is reachable via REST.**

Required steps when adding a new list/read command (or any command that returns data an agent might want over HTTP):

1. **Make the domain model `Presentable`** — `tableHeaders` + `tableRow`. Needed because `restFormat` is `<T: Encodable & AffordanceProviding & Presentable>`
2. **Use `structuredAffordances` (not raw `affordances`)** on the model — the REST renderer derives `_links` from `Affordance` values; returning a plain `[String: String]` leaves `_links` empty
3. **Give the command an `affordanceMode` parameter** — `func execute(repo:…, affordanceMode: AffordanceMode = .cli)` forwards to `formatter.formatAgentItems(items, affordanceMode: affordanceMode)`. The same `execute` runs for both `cli` and `rest` modes
4. **Add/extend a controller** under `Sources/ASCCommand/Commands/Web/Controllers/` — inject the repository, register a `group.get("/…")` route, parse query params via `request.uri.queryParameters` (use the same names as the CLI flags, e.g. `?state=&limit=&expired-only=&before=`), call the repository, return `try restFormat(items)`
5. **Wire the controller** in `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` (construct with `factory.make…Repository(authProvider: auth)`)
6. **Advertise the resource** from `APIRoot.structuredAffordances` so `GET /api/v1` lists the new top-level resource
7. **Add a REST test** in `Tests/ASCCommandTests/Commands/Web/RESTRoutesTests.swift` — call `execute(repo:affordanceMode: .rest)` and assert the output contains `"_links"` and the resolved REST paths
8. **CLI and REST query-param names must match** — if the CLI uses `--expired-only`, the REST query param is `?expired-only=true`; both go through the same repository method

Shared helpers (all in `Sources/ASCCommand/Commands/Web/RESTRoutes.swift`):
- `restFormat(items)` — REST equivalent of `formatter.formatAgentItems(items, affordanceMode: .rest)`
- `jsonError(message, status:)` — JSON error response (lives in `Infrastructure/Web/ASCWebServer.swift`; `import Infrastructure`)

Controllers are structs with dependencies injected at init (Hummingbird pattern). Repositories are constructed once in `RESTRoutes.configure`, never per request.

### Resource Hierarchy

Commands mirror the App Store Connect API hierarchy exactly:
```
App → AppStoreVersion → AppStoreVersionLocalization → AppScreenshotSet → AppScreenshot
App → AppInfo → AppInfoLocalization
App → AppInfo → AgeRatingDeclaration
AppCategory (top-level, not nested under App)
App → CustomerReview → CustomerReviewResponse
App → Build → BetaBuildLocalization
App → BuildUpload
App → TestFlight (BetaGroup → BetaTester)
App → CiProduct (XcodeCloud) → CiWorkflow → CiBuildRun
AppStoreVersion → VersionReadiness
AppStoreVersion → AppStoreReviewDetail
CodeSigning: BundleID → Profile
App → PerformanceMetric (via perfPowerMetrics)
Build → PerformanceMetric (via perfPowerMetrics)
Build → DiagnosticSignatureInfo → DiagnosticLogEntry
```

Domain folders are nested to mirror the resource hierarchy:
```
Domain/
├── Apps/                          → App, AppRepository
│   ├── Versions/                  → AppStoreVersion, AppStoreVersionState, VersionReadiness,
│   │   │                            VersionRepository, ReviewDetailRepository,
│   │   │                            AppStoreReviewDetail, ReviewDetailUpdate
│   │   └── Localizations/         → AppStoreVersionLocalization, VersionLocalizationRepository
│   │       └── ScreenshotSets/    → AppScreenshotSet, ScreenshotDisplayType, ScreenshotRepository
│   │           └── Screenshots/   → AppScreenshot
│   ├── AppInfos/                  → AppInfo, AppInfoLocalization, AppInfoRepository,
│   │                                AppCategory, AppCategoryRepository,
│   │                                AgeRatingDeclaration, AgeRatingDeclarationRepository
│   ├── Reviews/                   → CustomerReview, CustomerReviewResponse, ReviewResponseState,
│   │                                CustomerReviewRepository
│   ├── Builds/                    → Build, BuildUpload, BetaBuildLocalization,
│   │                                BuildRepository, BuildUploadRepository, BetaBuildLocalizationRepository
│   ├── Pricing/                   → PricingRepository
│   ├── TestFlight/                → BetaGroup, BetaTester, TestFlightRepository
│   └── Performance/              → PerformanceMetric, PerformanceMetricCategory, DiagnosticSignatureInfo,
│                                    DiagnosticType, DiagnosticLogEntry, PerfMetricsRepository, DiagnosticsRepository
├── CodeSigning/                   → BundleID, Certificate, Device, Profile + their repositories
│   ├── BundleIDs/                 → BundleID, BundleIDRepository
│   ├── Certificates/              → Certificate, CertificateRepository
│   ├── Devices/                   → Device, DeviceRepository
│   └── Profiles/                  → Profile, ProfileRepository
├── Submissions/                   → ReviewSubmission, ReviewSubmissionState, SubmissionRepository
├── Auth/                          → AuthCredentials, AuthProvider, AuthStatus, AuthStorage, CredentialSource, AuthError
├── Projects/                      → ProjectConfig, ProjectConfigStorage
├── Skills/                        → Skill, SkillCheckResult, SkillConfig, SkillRepository, SkillConfigStorage
└── Shared/                        → AffordanceProviding, APIError, OutputFormat, PaginatedResponse
```
Infrastructure and test folders mirror this exact structure.

### Project Context (`.asc/project.json`)

`asc init` saves the app ID, name, and bundle ID to `.asc/project.json` in the current directory:

```bash
asc init              # auto-detect from *.xcodeproj bundle ID
asc init --name "X"   # search by name
asc init --app-id <id>
```

`FileProjectConfigStorage` (Infrastructure) reads/writes `.asc/project.json` relative to cwd. `ProjectConfig` (Domain) carries `appId`, `appName`, `bundleId` + CAEOAS affordances.

## Testing

We follow the Chicago School of TDD — state-based, not interaction-based. Tests should verify what domain objects return and compute, rather than how they call their collaborators.

**ALWAYS write tests first, then implement.** Never write implementation code without a failing test. This is non-negotiable.

- If code is difficult to test, treat that as a design problem, not an exception to testing.
- The proper TDD workflow:
    1. **Think from user's mental model**: How would the user describe this behavior? What would they expect to see? For example: "a version is live when its state is readyForSale", "submit is only available when the version is editable".
    2. **Write the test**: Name it after the user's expectation. Assert the exact output values (e.g. `"IOS"`, `"READY_FOR_SALE"`, `"expired": true`).
    3. **Run the test**: It **must fail** (red). If it passes, the test is not testing new behaviour.
    4. **Implement**: Write just enough code to make the test pass (green).
    5. **Refactor**: Clean up while keeping tests green.
- Test cases should reflect the user's mental model — describe what the user sees and expects, not internal implementation details.
- Never modify a test to make it pass — if a test fails unexpectedly, the specification (step 1) was wrong. Fix the thinking, not the test.
- If you find yourself writing implementation before tests, stop and reverse course.
- Framework: Apple's `@Testing` macro (not XCTest)
- Mocking: `@Mockable` annotation on protocols + `given().willReturn()` in tests
- Test naming: backtick style — `` func `version is live when state is readyForSale`() ``
- `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` — shared test data factory

## Two Localization Types

The codebase has two distinct localization concepts with separate repositories:

| Type | Domain folder | Repository | Commands | Data |
|------|--------------|------------|----------|------|
| `AppStoreVersionLocalization` | `Domain/Localizations/` | `VersionLocalizationRepository` | `asc version-localizations *` | whatsNew, description, keywords, screenshots |
| `AppInfoLocalization` | `Domain/AppInfos/` | `AppInfoRepository` | `asc app-info-localizations *` | name, subtitle, privacyPolicyUrl, privacyChoicesUrl, privacyPolicyText |

`ScreenshotRepository` (in `Domain/ScreenshotSets/`) handles screenshot sets and screenshot images — **no localization methods**.

## Documentation

After every code change — new feature, improvement, or bug fix — update all affected docs before considering the task done.

### What to update

| Change type | Files to update |
|-------------|-----------------|
| New feature / command | `docs/features/<feature>.md` (create, include a **REST Endpoints** section), `CHANGELOG.md` ([Unreleased]), `README.md` (feature list + CLI examples), `skills/` (relevant skill files), `Sources/ASCCommand/Commands/Web/Controllers/` (new or extended controller), `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` (wire controller), `Sources/Domain/Shared/APIRoot.swift` (advertise new top-level resource), `Tests/ASCCommandTests/Commands/Web/RESTRoutesTests.swift` (REST test) |
| Improvement / enhancement | `docs/features/<feature>.md` (update affected sections), `CHANGELOG.md` ([Unreleased]) |
| Bug fix | `CHANGELOG.md` ([Unreleased]) |
| Architecture / API change | `CLAUDE.md` (update architecture / patterns sections), `docs/features/<feature>.md` |
| Auth / config change | `CLAUDE.md` (Authentication section), `README.md` |

### Per-file rules

**`docs/features/<feature>.md`** — write from actual code (read files first, never from memory). Structure:
1. CLI Usage — flags table + examples + output samples (json + table)
2. REST Endpoints — path table + query-param mapping (CLI flag → REST query) + curl example
3. Typical Workflow — end-to-end bash script showing the happy path
4. Architecture — three-layer ASCII diagram + dependency note
5. Domain Models — every public struct/enum/protocol with fields, computed properties, affordances
6. File Map — `Sources/` and `Tests/` trees + wiring files table (must list the REST controller)
7. API Reference — endpoint → SDK call → repository method
8. Testing — representative test snippet + `swift test` command
9. Extending — natural next steps with stub code

**`CHANGELOG.md`** — add entry under `[Unreleased]` using Keep a Changelog format:
- `### Added` for new features/commands
- `### Changed` for improvements to existing behaviour
- `### Fixed` for bug fixes

**`README.md`** — update the feature/command table and any usage examples that changed.

**`skills/<feature>`** — always use the `/skill-creator` skill to create or update feature skills

Key skills to keep in sync:
- `implement-feature/SKILL.md` — workflow + checklist
- `asc-cli/references/commands.md` — command reference
- Feature-specific skills (`asc-testflight`, `asc-beta-review`, `asc-builds-upload`, `asc-code-signing`, `asc-check-readiness`, `asc-app-previews`, `asc-app-shots`, `asc-review-detail`, `asc-plugins`, etc.)

**`CLAUDE.md`** — update when architecture patterns, file locations, or design rules change.

---

## Authentication

**Option A — Persistent login (recommended):**

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey_XXXXXX.p8 [--vendor-number <number>]
asc auth update --vendor-number <number>  # add vendor number to existing account
asc auth logout   # remove saved credentials
asc auth check    # verify credentials; shows source: "file" or "environment"
```

Credentials saved to `~/.asc/credentials.json`. Vendor number (optional) is used by `sales-reports` and `finance-reports` commands — auto-resolved from the active account when `--vendor-number` is omitted.

**Option B — Environment variables:**

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
# OR use ASC_PRIVATE_KEY with the PEM content directly
```

**Resolution order:** `~/.asc/credentials.json` → environment variables, handled by `CompositeAuthProvider` in Infrastructure. `EnvironmentAuthProvider` is the fallback.