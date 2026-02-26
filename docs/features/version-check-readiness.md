# Version Check-Readiness Feature

Pre-flight submission check for App Store versions. Aggregates all known Apple submission requirements into a single readiness report — enabling CI pipelines to gate submissions confidently without attempting a blind submit.

## CLI Usage

### Check Version Readiness

```bash
asc versions check-readiness --version-id <VERSION_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--version-id` | *(required)* | App Store version ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc versions check-readiness --version-id 74ed4466-8dc4-4ec7-b2ce-3c1bbe620964 --pretty
```

**JSON output (version ready to submit):**

```json
{
  "data": [
    {
      "affordances": {
        "checkReadiness": "asc versions check-readiness --version-id 74ed4466-...",
        "listLocalizations": "asc version-localizations list --version-id 74ed4466-...",
        "submit": "asc versions submit --version-id 74ed4466-..."
      },
      "appId": "6748760927",
      "buildCheck": {
        "buildVersion": "2.1.0 (102)",
        "linked": true,
        "notExpired": true,
        "pass": true,
        "valid": true
      },
      "id": "74ed4466-8dc4-4ec7-b2ce-3c1bbe620964",
      "isReadyToSubmit": true,
      "localizationCheck": {
        "localizations": [
          {
            "hasDescription": true,
            "hasKeywords": true,
            "hasSupportUrl": true,
            "hasWhatsNew": true,
            "isPrimary": true,
            "locale": "en-US",
            "pass": true,
            "screenshotSetCount": 3
          }
        ],
        "pass": true
      },
      "pricingCheck": { "pass": true },
      "reviewContactCheck": { "pass": true },
      "state": "PREPARE_FOR_SUBMISSION",
      "stateCheck": { "pass": true },
      "versionString": "2.1.0"
    }
  ]
}
```

**JSON output (version not ready — missing build):**

```json
{
  "data": [
    {
      "affordances": {
        "checkReadiness": "asc versions check-readiness --version-id 74ed4466-...",
        "listLocalizations": "asc version-localizations list --version-id 74ed4466-..."
      },
      "appId": "6748760927",
      "buildCheck": {
        "linked": false,
        "notExpired": false,
        "pass": false,
        "valid": false
      },
      "id": "74ed4466-...",
      "isReadyToSubmit": false,
      "localizationCheck": {
        "localizations": [],
        "pass": false
      },
      "pricingCheck": { "pass": true },
      "reviewContactCheck": { "pass": true },
      "state": "PREPARE_FOR_SUBMISSION",
      "stateCheck": { "pass": true },
      "versionString": "2.1.0"
    }
  ]
}
```

**JSON output (secondary locale has no screenshots — primary passes, still ready):**

```json
{
  "localizationCheck": {
    "localizations": [
      {
        "hasDescription": true,
        "hasKeywords": true,
        "hasSupportUrl": false,
        "hasWhatsNew": false,
        "isPrimary": true,
        "locale": "en-US",
        "pass": true,
        "screenshotSetCount": 2
      },
      {
        "hasDescription": true,
        "hasKeywords": false,
        "hasSupportUrl": false,
        "hasWhatsNew": false,
        "isPrimary": false,
        "locale": "zh-Hans",
        "pass": false,
        "screenshotSetCount": 0
      }
    ],
    "pass": true
  },
  "isReadyToSubmit": true
}
```

**Note:** `affordances.submit` only appears when `isReadyToSubmit == true`. `reviewContactCheck` failing does NOT block submission — it is a SHOULD FIX warning only.

**Table output:**

```
ID                                    Version  State                   Ready
------------------------------------  -------  ----------------------  -----
74ed4466-8dc4-4ec7-b2ce-3c1bbe620964  2.1.0    PREPARE_FOR_SUBMISSION  yes
```

---

## Check Severity

| Check | Field | Severity | Blocks submission? |
|-------|-------|----------|--------------------|
| Version state is editable | `stateCheck` | MUST FIX | Yes |
| Build linked, valid, not expired | `buildCheck` | MUST FIX | Yes |
| App price schedule configured | `pricingCheck` | MUST FIX | Yes |
| Primary locale has description + screenshots | `localizationCheck` | MUST FIX | Yes |
| Review contact info (email + phone) | `reviewContactCheck` | SHOULD FIX | No |
| Secondary locale description + screenshots | `localizationCheck.localizations[isPrimary=false].pass` | SHOULD FIX | No (Apple rejects post-submit) |

`isReadyToSubmit = stateCheck.pass && buildCheck.pass && pricingCheck.pass && localizationCheck.pass`

`localizationCheck.pass` = `true` when the primary locale (`isPrimary == true`) has a description and at least one screenshot set. It is `false` when there are no localizations at all.

---

## Typical Workflow

```bash
# 1. Find your app
asc apps list --output table

# 2. Find the version in PREPARE_FOR_SUBMISSION state
asc versions list --app-id <APP_ID> --output table

# 3. Run the pre-flight check
asc versions check-readiness --version-id <VERSION_ID> --pretty

# 4a. If isReadyToSubmit == true → copy affordances.submit and run it
asc versions submit --version-id <VERSION_ID>

# 4b. If buildCheck.linked == false → link a build first
asc versions set-build --version-id <VERSION_ID> --build-id <BUILD_ID>

# 4c. If pricingCheck.pass == false → configure pricing in App Store Connect web UI
#     (no asc CLI command for pricing setup)

# 4d. If localizationCheck.pass == false → add description and screenshots to primary locale
asc version-localizations list --version-id <VERSION_ID>

# 5. Re-run check until ready
asc versions check-readiness --version-id <VERSION_ID> --pretty
```

### CI gate script

```bash
#!/bin/bash
set -e

RESULT=$(asc versions check-readiness --version-id "$VERSION_ID")
IS_READY=$(echo "$RESULT" | jq -r '.data[0].isReadyToSubmit')

if [ "$IS_READY" = "true" ]; then
  echo "Version is ready. Submitting..."
  asc versions submit --version-id "$VERSION_ID"
else
  echo "Version is NOT ready. Issues:"
  echo "$RESULT" | jq '.data[0] | {stateCheck, buildCheck, pricingCheck, localizationCheck}'
  exit 1
fi
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  ASCCommand                                                     │
│  VersionsCommand                                                │
│    └── VersionsCheckReadiness (check-readiness --version-id)   │
│          orchestrates 6 repositories                            │
│          → VersionReadiness (MUST FIX + SHOULD FIX report)     │
└───────────────────────┬─────────────────────────────────────────┘
                        │ uses 6 repository protocols
┌───────────────────────▼─────────────────────────────────────────┐
│  Domain/Apps/Versions/                                          │
│  VersionReadiness — id, appId, versionString, state,           │
│                     isReadyToSubmit, stateCheck,               │
│                     buildCheck, pricingCheck,                  │
│                     localizationCheck, reviewContactCheck      │
│  ReadinessCheck — pass, message?                               │
│  BuildReadinessCheck — linked, valid, notExpired, buildVersion?│
│  LocalizationReadinessCheck — localizations, pass (computed)   │
│  LocalizationReadiness — locale, isPrimary, hasDescription,    │
│                          hasKeywords, hasSupportUrl,           │
│                          hasWhatsNew, screenshotSetCount        │
│                                                                 │
│  AppStoreReviewDetail — id, versionId,                         │
│                         contactPhone?, contactEmail?,          │
│                         demoAccountRequired, ...               │
│                                                                 │
│  VersionRepository    → getVersion(id:)        (+ existing)    │
│  ReviewDetailRepository → getReviewDetail(versionId:)          │
│  PricingRepository    → hasPricing(appId:)                     │
│  BuildRepository      → getBuild(id:)          (existing)      │
│  VersionLocalizationRepository → listLocalizations (existing)  │
│  ScreenshotRepository → listScreenshotSets(localizationId:)    │
│                                                (existing)      │
└───────────────────────┬─────────────────────────────────────────┘
                        │ implements
┌───────────────────────▼─────────────────────────────────────────┐
│  Infrastructure                                                 │
│  SDKVersionRepository    GET /v1/appStoreVersions/{id}         │
│                          ?include=app,build                     │
│                          → extracts appId + buildId            │
│  SDKReviewDetailRepository                                      │
│                          GET /v1/appStoreVersions/{id}/         │
│                               appStoreReviewDetail             │
│  SDKPricingRepository    GET /v1/apps/{id}/appPriceSchedule    │
│                          catches error → returns false         │
│  (SDKBuildRepository, SDKLocalizationRepository,               │
│   OpenAPIScreenshotRepository — all existing)                  │
└─────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`

---

## Domain Models

### `VersionReadiness`

Top-level readiness report. `id` equals the version ID for correlation.

```swift
public struct VersionReadiness: Sendable, Equatable, Identifiable, Codable {
    public let id: String            // = versionId
    public let appId: String
    public let versionString: String
    public let state: AppStoreVersionState
    public let isReadyToSubmit: Bool // true iff all MUST FIX checks pass

    // MUST FIX (all must pass for isReadyToSubmit)
    public let stateCheck: ReadinessCheck
    public let buildCheck: BuildReadinessCheck
    public let pricingCheck: ReadinessCheck
    public let localizationCheck: LocalizationReadinessCheck
    // SHOULD FIX (warning only, does not block submission)
    public let reviewContactCheck: ReadinessCheck
}
```

**Affordances:**
```
"checkReadiness"    → asc versions check-readiness --version-id <id>   (always)
"listLocalizations" → asc version-localizations list --version-id <id> (always)
"submit"            → asc versions submit --version-id <id>            (only when isReadyToSubmit)
```

### `ReadinessCheck`

A single pass/fail check with an optional failure message.

```swift
public struct ReadinessCheck: Sendable, Equatable, Codable {
    public let pass: Bool
    public let message: String?   // nil when pass; omitted from JSON when nil

    public static func pass() -> ReadinessCheck
    public static func fail(_ message: String) -> ReadinessCheck
}
```

### `BuildReadinessCheck`

Build-specific MUST FIX check. `pass` is a computed property, explicitly encoded to JSON.

```swift
public struct BuildReadinessCheck: Sendable, Equatable, Codable {
    public let linked: Bool         // version.buildId != nil
    public let valid: Bool          // build.processingState == .valid
    public let notExpired: Bool     // !build.expired
    public let buildVersion: String? // "1.2.0 (55)" — nil when not linked

    public var pass: Bool { linked && valid && notExpired }
}
```

### `LocalizationReadinessCheck`

Wrapper for all per-locale checks. `pass` is computed from the primary locale.

```swift
public struct LocalizationReadinessCheck: Sendable, Equatable, Codable {
    public let localizations: [LocalizationReadiness]

    /// True when the primary locale has a description and at least one screenshot set.
    public var pass: Bool {
        localizations.first(where: { $0.isPrimary })?.pass ?? false
    }
}
```

### `LocalizationReadiness`

Per-locale detail. `isPrimary` marks the first locale returned by the API (the app's default locale). Secondary locale failures are informational — only primary locale failure blocks submission.

```swift
public struct LocalizationReadiness: Sendable, Equatable, Codable {
    public let locale: String
    public let isPrimary: Bool          // first locale returned by API = primary
    public let hasDescription: Bool
    public let hasKeywords: Bool
    public let hasSupportUrl: Bool
    public let hasWhatsNew: Bool
    public let screenshotSetCount: Int  // sets with screenshotsCount > 0

    public var pass: Bool { hasDescription && screenshotSetCount > 0 }
}
```

### `AppStoreReviewDetail`

Contact info and demo account configuration for the App Review team. Not exposed in `VersionReadiness` output — only its `hasContact` computed property feeds `reviewContactCheck`.

```swift
public struct AppStoreReviewDetail: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let versionId: String        // parent ID, always injected
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountRequired: Bool
    public let demoAccountName: String?
    public let demoAccountPassword: String?

    public var hasContact: Bool { contactEmail != nil && contactPhone != nil }
    public var demoAccountConfigured: Bool {
        !demoAccountRequired || (demoAccountName != nil && demoAccountPassword != nil)
    }
}
```

### Repository Protocols

```swift
@Mockable
public protocol ReviewDetailRepository: Sendable {
    func getReviewDetail(versionId: String) async throws -> AppStoreReviewDetail
}

@Mockable
public protocol PricingRepository: Sendable {
    func hasPricing(appId: String) async throws -> Bool
}
```

`VersionRepository` was extended with:
```swift
func getVersion(id: String) async throws -> AppStoreVersion
```

`AppStoreVersion` was extended with:
- `buildId: String?` — optional, omitted from JSON when nil
- `checkReadiness` affordance — always present regardless of state

---

## File Map

```
Sources/
├── Domain/Apps/Versions/
│   ├── AppStoreVersion.swift           # + buildId: String?, checkReadiness affordance
│   ├── VersionRepository.swift         # + getVersion(id:)
│   ├── AppStoreReviewDetail.swift      # contact + demo account model
│   ├── ReviewDetailRepository.swift    # @Mockable protocol
│   ├── VersionReadiness.swift          # readiness report + sub-types
│   └── AppStoreVersionState.swift      # (existing; isEditable drives stateCheck)
│
├── Domain/Apps/Pricing/
│   └── PricingRepository.swift         # @Mockable protocol (hasPricing)
│
├── Infrastructure/Apps/Versions/
│   ├── SDKVersionRepository.swift      # + getVersion(id:) with ?include=app,build
│   └── SDKReviewDetailRepository.swift # GET .../appStoreReviewDetail
│
├── Infrastructure/Apps/Pricing/
│   └── SDKPricingRepository.swift      # GET .../appPriceSchedule; catch→false
│
└── ASCCommand/Commands/Versions/
    ├── VersionsCommand.swift            # + VersionsCheckReadiness in subcommands
    └── VersionsCheckReadiness.swift     # orchestrates 6 repos → VersionReadiness

Tests/
├── DomainTests/Apps/Versions/
│   ├── VersionReadinessTests.swift     # ReadinessCheck, BuildReadinessCheck,
│   │                                   # LocalizationReadinessCheck, LocalizationReadiness,
│   │                                   # affordances, Codable
│   └── AppStoreReviewDetailTests.swift # hasContact, demoAccountConfigured, Codable
│
├── DomainTests/Apps/
│   └── AffordancesTests.swift          # + checkReadiness on AppStoreVersion
│                                       # + VersionReadiness affordances
│
├── InfrastructureTests/Apps/Versions/
│   └── SDKReviewDetailRepositoryTests.swift  # contact mapping + versionId injection
│
├── InfrastructureTests/Apps/Pricing/
│   └── SDKPricingRepositoryTests.swift  # hasPricing true/false; ThrowingStubAPIClient
│
└── ASCCommandTests/Commands/Versions/
    └── VersionsCheckReadinessTests.swift # 5 scenarios: ready / no build /
                                          # not editable state / multi-locale /
                                          # contact missing (still ready)
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeReviewDetailRepository` + `makePricingRepository` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeReviewDetailRepository()` + `makePricingRepository()` |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | Added `makeVersion(buildId:)`, `makeReviewDetail(...)`, `makeVersionReadiness(...)` |
| `Tests/ASCCommandTests/Commands/Versions/VersionsListTests.swift` | Updated expected JSON: added `checkReadiness` affordance |
| `Tests/ASCCommandTests/Commands/Versions/VersionsCreateTests.swift` | Updated expected JSON: added `checkReadiness` affordance |

---

## App Store Connect API Reference

| Endpoint | SDK call | Repository method |
|----------|----------|-------------------|
| `GET /v1/appStoreVersions/{id}?include=app,build` | `.appStoreVersions.id(id).get(parameters: .init(include: [.app, .build]))` | `getVersion(id:)` |
| `GET /v1/appStoreVersions/{id}/appStoreReviewDetail` | `.appStoreVersions.id(id).appStoreReviewDetail.get()` | `getReviewDetail(versionId:)` |
| `GET /v1/apps/{id}/appPriceSchedule` | `.apps.id(appId).appPriceSchedule.get()` | `hasPricing(appId:)` — catches errors, returns `false` |
| `GET /v1/builds/{id}` | `.builds.id(id).get()` | `getBuild(id:)` (existing) |
| `GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations` | `.appStoreVersions.id(id).appStoreVersionLocalizations.get()` | `listLocalizations(versionId:)` (existing) |
| `GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets` | `.appStoreVersionLocalizations.id(id).appScreenshotSets.get()` | `listScreenshotSets(localizationId:)` (existing) |

**Key detail:** `GET /v1/appStoreVersions/{id}` does not include `appId` in the response body — it must be extracted from `response.data.relationships?.app?.data?.id`. The `buildId` comes from `response.data.relationships?.build?.data?.id`.

---

## Testing

Tests follow **Chicago School TDD** — assert on exact state and output values.

```swift
// Domain: primary locale pass drives localizationCheck.pass
@Test func `localization check passes when primary locale has description and screenshots`() {
    let check = LocalizationReadinessCheck(localizations: [
        LocalizationReadiness(locale: "en-US", isPrimary: true,
                              hasDescription: true, hasKeywords: true,
                              hasSupportUrl: false, hasWhatsNew: false,
                              screenshotSetCount: 2)
    ])
    #expect(check.pass == true)
}

// Domain: no localizations → localizationCheck.pass false
@Test func `localization check fails when no localizations`() {
    let check = LocalizationReadinessCheck(localizations: [])
    #expect(check.pass == false)
}

// Command: secondary locale without screenshots does not block submission
@Test func `secondary locale without screenshots does not block submission`() async throws {
    // en-US (primary, isPrimary: true): has screenshots → pass: true
    // zh-Hans (secondary, isPrimary: false): no screenshots → pass: false
    // localizationCheck.pass = true (primary passes)
    // isReadyToSubmit = true
}

// Command: reviewContactCheck failure is SHOULD FIX only — does not block submission
@Test func `missing review contact does not block submission`() async throws {
    // reviewContactCheck.pass = false, but isReadyToSubmit = true
    // (primary localization passes; only MUST FIX checks gate submission)
}
```

Run the full suite:
```bash
swift test
```

---

## Extending the Feature

### Add demo account check to MUST FIX

```swift
// In VersionsCheckReadiness.swift
let demoCheck: ReadinessCheck = reviewDetail.demoAccountConfigured
    ? .pass()
    : .fail("Demo account is required but not fully configured")

// Add to VersionReadiness and update isReadyToSubmit:
let isReadyToSubmit = stateCheck.pass && buildCheck.pass && pricingCheck.pass
    && localizationCheck.pass && demoCheck.pass
```

### Surface readiness as part of `versions list`

Include a lightweight `isEditable` boolean on `AppStoreVersion` output — the `checkReadiness` affordance already guides agents to fetch the full report on demand.

### Use in AI agent pipeline

```bash
# Agent workflow: find first ready version and submit
VERSIONS=$(asc versions list --app-id "$APP_ID")
VERSION_ID=$(echo "$VERSIONS" | jq -r '.data[] | select(.state == "PREPARE_FOR_SUBMISSION") | .id' | head -1)

READINESS=$(asc versions check-readiness --version-id "$VERSION_ID")
if [ "$(echo "$READINESS" | jq -r '.data[0].isReadyToSubmit')" = "true" ]; then
  # Copy submit affordance directly from response
  SUBMIT_CMD=$(echo "$READINESS" | jq -r '.data[0].affordances.submit')
  eval "$SUBMIT_CMD"
fi
```
