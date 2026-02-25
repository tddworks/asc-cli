# Version Localizations Feature

Manage per-locale content for an App Store version — What's New text, description, keywords, and URLs. These fields are distinct from app-level metadata managed through `AppInfoLocalization`.

## CLI Usage

### List Localizations

List all locale entries for a given App Store version.

```bash
asc version-localizations list --version-id <VERSION_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--version-id` | *(required)* | App Store version ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc version-localizations list --version-id 74ed4466-8dc4-4ec7-b2ce-3c1bbe620964 --pretty
```

**JSON output:**

```json
{
  "data": [
    {
      "id": "9584409e-a626-46d4-9b65-4cac006f4197",
      "versionId": "74ed4466-8dc4-4ec7-b2ce-3c1bbe620964",
      "locale": "en-US",
      "affordances": {
        "listLocalizations": "asc version-localizations list --version-id 74ed4466-...",
        "listScreenshotSets": "asc screenshot-sets list --localization-id 9584409e-...",
        "updateLocalization": "asc version-localizations update --localization-id 9584409e-..."
      }
    }
  ]
}
```

**Table output:**

```
ID                                    Locale
------------------------------------  -------
9584409e-a626-46d4-9b65-4cac006f4197  en-US
b1c2d3e4-...                          zh-Hans
```

---

### Create Localization

Add a new locale entry to a version.

```bash
asc version-localizations create --version-id <VERSION_ID> --locale <LOCALE>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--version-id` | *(required)* | App Store version ID |
| `--locale` | *(required)* | Locale identifier (e.g. `en-US`, `zh-Hans`, `ja`) |
| `--output` | `json` | Output format |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc version-localizations create --version-id 74ed4466-... --locale fr-FR
```

---

### Update Localization

Update the What's New text, description, keywords, or URLs for an existing localization. All content fields are optional — only provided fields are sent to the API.

```bash
asc version-localizations update --localization-id <LOCALIZATION_ID> \
  [--whats-new <text>] \
  [--description <text>] \
  [--keywords <text>] \
  [--marketing-url <url>] \
  [--support-url <url>] \
  [--promotional-text <text>]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--localization-id` | *(required)* | Localization ID |
| `--whats-new` | *(optional)* | What's New / release notes text |
| `--description` | *(optional)* | App description |
| `--keywords` | *(optional)* | Keywords (comma-separated) |
| `--marketing-url` | *(optional)* | Marketing URL |
| `--support-url` | *(optional)* | Support URL |
| `--promotional-text` | *(optional)* | Promotional text |
| `--output` | `json` | Output format |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Set What's New text for the English locale
asc version-localizations update \
  --localization-id 9584409e-... \
  --whats-new "Bug fixes and performance improvements"

# Update multiple fields at once
asc version-localizations update \
  --localization-id 9584409e-... \
  --whats-new "Bug fixes" \
  --keywords "productivity,tasks,calendar"
```

**JSON output (only non-nil fields appear):**

```json
{
  "data": [
    {
      "id": "9584409e-a626-46d4-9b65-4cac006f4197",
      "versionId": "74ed4466-8dc4-4ec7-b2ce-3c1bbe620964",
      "locale": "en-US",
      "whatsNew": "Bug fixes and performance improvements",
      "affordances": {
        "listLocalizations": "asc version-localizations list --version-id 74ed4466-...",
        "listScreenshotSets": "asc screenshot-sets list --localization-id 9584409e-...",
        "updateLocalization": "asc version-localizations update --localization-id 9584409e-..."
      }
    }
  ]
}
```

---

## Typical Workflow

```bash
# 1. Find your app
asc apps list --output table

# 2. Find the version to update
asc versions list --app-id <APP_ID> --output table

# 3. List existing localizations (get localization IDs)
asc version-localizations list --version-id <VERSION_ID> --output table

# 4a. Update What's New for English
asc version-localizations update \
  --localization-id <EN_LOC_ID> \
  --whats-new "Bug fixes and performance improvements"

# 4b. Update What's New for Chinese (Simplified)
asc version-localizations update \
  --localization-id <ZH_LOC_ID> \
  --whats-new "修复了已知问题，提升了性能"

# 4c. Create a new locale if it doesn't exist yet
asc version-localizations create --version-id <VERSION_ID> --locale fr-FR

# 5. Upload screenshots for each locale
asc screenshot-sets list --localization-id <LOC_ID>
asc screenshots upload --set-id <SET_ID> --file ./screenshots/en-US/hero.png

# 6. Submit for review
asc versions submit --version-id <VERSION_ID>
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  ASCCommand                                                      │
│  VersionLocalizationsCommand                                     │
│    ├── VersionLocalizationsList   (list --version-id)            │
│    ├── VersionLocalizationsCreate (create --version-id --locale) │
│    └── VersionLocalizationsUpdate (update --localization-id      │
│           [--whats-new] [--description] [--keywords] ...)        │
└────────────────────────────┬─────────────────────────────────────┘
                             │ uses VersionLocalizationRepository
┌────────────────────────────▼─────────────────────────────────────┐
│  Domain/Apps/Versions/Localizations/                             │
│  AppStoreVersionLocalization                                     │
│    id, versionId, locale                                         │
│    whatsNew?, description?, keywords?                            │
│    marketingUrl?, supportUrl?, promotionalText?                  │
│    (nil-safe Codable — omits nil fields from JSON output)        │
│                                                                  │
│  VersionLocalizationRepository (@Mockable)                       │
│    listLocalizations(versionId:)                                 │
│    createLocalization(versionId:locale:)                         │
│    updateLocalization(localizationId:whatsNew:...)               │
└────────────────────────────┬─────────────────────────────────────┘
                             │ implements
┌────────────────────────────▼─────────────────────────────────────┐
│  Infrastructure/Apps/Versions/Localizations/                     │
│  SDKLocalizationRepository                                       │
│    GET  /v1/appStoreVersions/{id}/appStoreVersionLocalizations   │
│    POST /v1/appStoreVersionLocalizations                         │
│    PATCH /v1/appStoreVersionLocalizations/{id}                   │
│    marketingURL/supportURL: URL? ↔ String? conversion            │
└──────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`

**Note:** `VersionLocalizationRepository` is separate from `ScreenshotRepository`. Localization text concerns (what's new, description) are decoupled from screenshot management (sets, images). Each command group has its own repository.

---

## Domain Models

### `AppStoreVersionLocalization`

Per-locale version content. All text fields are optional — the API returns only populated fields, and the CLI only sends fields you provide.

```swift
public struct AppStoreVersionLocalization: Sendable, Equatable, Identifiable {
    public let id: String
    public let versionId: String      // Parent ID, always injected by Infrastructure
    public let locale: String         // "en-US", "zh-Hans", "ja", etc.
    public let whatsNew: String?      // Release notes
    public let description: String?   // App description
    public let keywords: String?      // Comma-separated keywords
    public let marketingUrl: String?  // Marketing URL
    public let supportUrl: String?    // Support URL
    public let promotionalText: String?
}
```

**Nil-safe encoding:** Uses `encodeIfPresent` — nil optional fields are omitted from JSON output, keeping agent responses clean.

**Affordances (always present):**
```
"listScreenshotSets"  → asc screenshot-sets list --localization-id <id>
"listLocalizations"   → asc version-localizations list --version-id <versionId>
"updateLocalization"  → asc version-localizations update --localization-id <id>
```

### `VersionLocalizationRepository`

```swift
@Mockable
public protocol VersionLocalizationRepository: Sendable {
    func listLocalizations(versionId: String) async throws -> [AppStoreVersionLocalization]
    func createLocalization(versionId: String, locale: String) async throws -> AppStoreVersionLocalization
    func updateLocalization(
        localizationId: String,
        whatsNew: String?,
        description: String?,
        keywords: String?,
        marketingUrl: String?,
        supportUrl: String?,
        promotionalText: String?
    ) async throws -> AppStoreVersionLocalization
}
```

---

## File Map

```
Sources/
├── Domain/Apps/Versions/Localizations/
│   ├── AppStoreVersionLocalization.swift   # Value type + nil-safe Codable + AffordanceProviding
│   └── VersionLocalizationRepository.swift # @Mockable protocol (3 methods)
│
├── Infrastructure/Apps/Versions/Localizations/
│   └── SDKLocalizationRepository.swift     # Implements VersionLocalizationRepository; maps SDK → domain
│
└── ASCCommand/Commands/VersionLocalizations/
    ├── VersionLocalizationsCommand.swift   # Command group + VersionLocalizationsList
    ├── VersionLocalizationsCreate.swift    # Create subcommand
    └── VersionLocalizationsUpdate.swift    # Update subcommand

Tests/
├── DomainTests/Apps/Versions/Localizations/
│   ├── AppStoreVersionLocalizationTests.swift   # Field carrying, nil defaults, affordances
│   └── VersionLocalizationRepositoryTests.swift # list/create/update mock patterns
├── InfrastructureTests/Apps/Versions/Localizations/
│   └── SDKLocalizationRepositoryTests.swift     # Parent ID injection, field mapping, URL conversion
├── ASCCommandTests/Commands/VersionLocalizations/
│   ├── VersionLocalizationsListTests.swift   # Exact JSON output, affordances
│   ├── VersionLocalizationsCreateTests.swift # Exact JSON output, arg passing
│   └── VersionLocalizationsUpdateTests.swift # Exact JSON output, all flags
└── DomainTests/Apps/
    └── AffordancesTests.swift                # updateLocalization affordance test
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeVersionLocalizationRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeVersionLocalizationRepository()` |
| `Sources/ASCCommand/Commands/Screenshots/ScreenshotsImport.swift` | Split `repo` into `localizationRepo` + `screenshotRepo` |
| `Tests/ASCCommandTests/Commands/Screenshots/ScreenshotsImportTests.swift` | Updated to use two repos |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | Extended `makeLocalization` with all text fields |

---

## App Store Connect API Reference

| Endpoint | SDK call | Repository method |
|----------|----------|-------------------|
| `GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations` | `.appStoreVersions.id(id).appStoreVersionLocalizations.get()` | `listLocalizations` |
| `POST /v1/appStoreVersionLocalizations` | `.appStoreVersionLocalizations.post(body)` | `createLocalization` |
| `PATCH /v1/appStoreVersionLocalizations/{id}` | `.appStoreVersionLocalizations.id(id).patch(body)` | `updateLocalization` |

**URL field handling:** The SDK uses `marketingURL: URL?` and `supportURL: URL?` (Swift `URL` type). The domain model stores them as `String?`. `SDKLocalizationRepository` converts with `URL(string:)` on input and `.absoluteString` on output.

---

## Testing

Tests follow **Chicago school TDD** — assert on exact state and output values.

```swift
// Domain: model carries parent ID
@Test func `localization carries versionId`() {
    let loc = MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-99")
    #expect(loc.versionId == "v-99")
}

// Domain: affordance included always
@Test func `localization affordances include updateLocalization command`() {
    let loc = MockRepositoryFactory.makeLocalization(id: "loc-42", versionId: "v-1")
    #expect(loc.affordances["updateLocalization"] == "asc version-localizations update --localization-id loc-42")
}

// Infrastructure: parent ID injection
@Test func `listLocalizations injects versionId into each localization`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(AppStoreVersionLocalizationsResponse(
        data: [AppStoreVersionLocalization(type: .appStoreVersionLocalizations, id: "loc-1", attributes: .init(locale: "en-US"))],
        links: .init(this: "")
    ))
    let repo = SDKLocalizationRepository(client: stub)
    let result = try await repo.listLocalizations(versionId: "v-42")
    #expect(result.allSatisfy { $0.versionId == "v-42" })
}

// Command: exact JSON output assertion
@Test func `execute json output`() async throws {
    let mockRepo = MockVersionLocalizationRepository()
    given(mockRepo).updateLocalization(
        localizationId: .any, whatsNew: .any, description: .any,
        keywords: .any, marketingUrl: .any, supportUrl: .any, promotionalText: .any
    ).willReturn(
        AppStoreVersionLocalization(id: "loc-1", versionId: "v-1", locale: "en-US", whatsNew: "Bug fixes")
    )
    let cmd = try LocalizationsUpdate.parse(["--localization-id", "loc-1", "--whats-new", "Bug fixes", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)
    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "listLocalizations" : "asc version-localizations list --version-id v-1",
            "listScreenshotSets" : "asc screenshot-sets list --localization-id loc-1",
            "updateLocalization" : "asc version-localizations update --localization-id loc-1"
          },
          "id" : "loc-1",
          "locale" : "en-US",
          "versionId" : "v-1",
          "whatsNew" : "Bug fixes"
        }
      ]
    }
    """)
}
```

Run the full suite:
```bash
swift test
```

---

## Extending the Feature

### Bulk update all locales for a version

```bash
# Script: update What's New for all localizations of a version
for LOC_ID in $(asc version-localizations list --version-id $VERSION_ID | jq -r '.data[].id'); do
  asc version-localizations update --localization-id $LOC_ID --whats-new "Bug fixes"
done
```

### Adding delete localization

```swift
// 1. Domain protocol (VersionLocalizationRepository.swift)
func deleteLocalization(localizationId: String) async throws

// 2. Infrastructure SDK call
APIEndpoint.v1.appStoreVersionLocalizations.id(localizationId).delete

// 3. New subcommand: LocalizationsDelete
```

### Relationship to screenshots

`VersionLocalizationRepository` handles text content. For screenshots, continue using `ScreenshotRepository`:

```
asc version-localizations list → localization ID
asc screenshot-sets list --localization-id <id>  ← ScreenshotRepository
asc screenshots upload --set-id <id> --file <path>
```
