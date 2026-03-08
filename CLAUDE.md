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
App → AppInfo → AppInfoLocalization
App → AppInfo → AgeRatingDeclaration
AppCategory (top-level, not nested under App)
App → Build → BetaBuildLocalization
App → BuildUpload
App → TestFlight (BetaGroup → BetaTester)
App → CiProduct (XcodeCloud) → CiWorkflow → CiBuildRun
AppStoreVersion → VersionReadiness
AppStoreVersion → AppStoreReviewDetail
CodeSigning: BundleID → Profile
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
│   ├── Builds/                    → Build, BuildUpload, BetaBuildLocalization,
│   │                                BuildRepository, BuildUploadRepository, BetaBuildLocalizationRepository
│   ├── Pricing/                   → PricingRepository
│   └── TestFlight/                → BetaGroup, BetaTester, TestFlightRepository
├── CodeSigning/                   → BundleID, Certificate, Device, Profile + their repositories
│   ├── BundleIDs/                 → BundleID, BundleIDRepository
│   ├── Certificates/              → Certificate, CertificateRepository
│   ├── Devices/                   → Device, DeviceRepository
│   └── Profiles/                  → Profile, ProfileRepository
├── Submissions/                   → ReviewSubmission, ReviewSubmissionState, SubmissionRepository
├── Auth/                          → AuthCredentials, AuthProvider, AuthStatus, AuthStorage, CredentialSource, AuthError
├── Projects/                      → ProjectConfig, ProjectConfigStorage
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

- If code is difficult to test, treat that as a design problem, not an exception to testing.
- Implement strictly in TDD order: tests first, then implementation
- The proper TDD workflow:
    1. **Think**: What should `execute()` return in JSON mode? For example: raw field values like `"IOS"`, `"READY_FOR_SALE"`, `"expired": true`.
    2. **Write the test**: Assert those exact output values.
    3. **Run the test**: It should fail (red) if the functionality is not yet implemented.
    4. **Implement**: Write just enough code to make the test pass (green).
- Changing a test after it fails means the specification was wrong, which means step 1 (thinking) was skipped.
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
| New feature / command | `docs/features/<feature>.md` (create), `CHANGELOG.md` ([Unreleased]), `README.md` (feature list + CLI examples), `.claude/skills/` (relevant skill files) |
| Improvement / enhancement | `docs/features/<feature>.md` (update affected sections), `CHANGELOG.md` ([Unreleased]) |
| Bug fix | `CHANGELOG.md` ([Unreleased]) |
| Architecture / API change | `CLAUDE.md` (update architecture / patterns sections), `docs/features/<feature>.md` |
| Auth / config change | `CLAUDE.md` (Authentication section), `README.md` |

### Per-file rules

**`docs/features/<feature>.md`** — write from actual code (read files first, never from memory). Structure:
1. CLI Usage — flags table + examples + output samples (json + table)
2. Typical Workflow — end-to-end bash script showing the happy path
3. Architecture — three-layer ASCII diagram + dependency note
4. Domain Models — every public struct/enum/protocol with fields, computed properties, affordances
5. File Map — `Sources/` and `Tests/` trees + wiring files table
6. API Reference — endpoint → SDK call → repository method
7. Testing — representative test snippet + `swift test` command
8. Extending — natural next steps with stub code

**`CHANGELOG.md`** — add entry under `[Unreleased]` using Keep a Changelog format:
- `### Added` for new features/commands
- `### Changed` for improvements to existing behaviour
- `### Fixed` for bug fixes

**`README.md`** — update the feature/command table and any usage examples that changed.

**`.claude/skills/`** — keep skills in sync whenever commands are added or flags change:
- If the skill **exists**: update the relevant `SKILL.md` or reference file, then re-package with `package_skill.py`.
- If the skill **does not exist**: use the `skill-creator` skill to create it from scratch (init → edit → package).

Key skills to keep in sync:
- `implement-feature/SKILL.md` — workflow + checklist
- `asc-cli/references/commands.md` — command reference
- Feature-specific skills (`asc-testflight`, `asc-builds-upload`, `asc-code-signing`, `asc-check-readiness`, `asc-app-previews`, `asc-app-shots`, `asc-review-detail`, `asc-plugins`, etc.)

**`CLAUDE.md`** — update when architecture patterns, file locations, or design rules change.

---

## Authentication

**Option A — Persistent login (recommended):**

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey_XXXXXX.p8
asc auth logout   # remove saved credentials
asc auth check    # verify credentials; shows source: "file" or "environment"
```

Credentials saved to `~/.asc/credentials.json`.

**Option B — Environment variables:**

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="~/.asc/AuthKey_XXXXXX.p8"
# OR use ASC_PRIVATE_KEY with the PEM content directly
```

**Resolution order:** `~/.asc/credentials.json` → environment variables, handled by `CompositeAuthProvider` in Infrastructure. `EnvironmentAuthProvider` is the fallback.