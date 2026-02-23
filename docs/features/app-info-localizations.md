# App Info Localizations Feature

Manage per-locale app metadata (name, subtitle, privacy policy) for an app via the App Store Connect API. These fields appear on the App Store listing and are distinct from version-specific release notes managed through `AppStoreVersionLocalization`.

## CLI Usage

### List App Infos

List the AppInfo records for an app. Each app has one AppInfo per active state (typically one).

```bash
asc app-infos list --app-id <APP_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-id` | *(required)* | App ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc app-infos list --app-id 6746148194 --pretty
```

**JSON output:**

```json
{
  "data": [
    {
      "id": "info-abc123",
      "appId": "6746148194",
      "affordances": {
        "listLocalizations": "asc app-info-localizations list --app-info-id info-abc123",
        "listAppInfos": "asc app-infos list --app-id 6746148194"
      }
    }
  ]
}
```

---

### List App Info Localizations

List all per-locale metadata entries for a given AppInfo.

```bash
asc app-info-localizations list --app-info-id <APP_INFO_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-info-id` | *(required)* | App info ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Default JSON output
asc app-info-localizations list --app-info-id info-abc123

# Table view
asc app-info-localizations list --app-info-id info-abc123 --output table
```

**Table output:**

```
ID          Locale    Name            Subtitle
----------  --------  --------------  --------------------
loc-001     en-US     My App          Do things faster
loc-002     zh-Hans   我的应用          更快地完成任务
loc-003     ja        マイアプリ         -
```

---

### Create App Info Localization

Create a new localization for a locale that doesn't exist yet.

```bash
asc app-info-localizations create --app-info-id <APP_INFO_ID> --locale <LOCALE> --name <NAME>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-info-id` | *(required)* | App info ID |
| `--locale` | *(required)* | Locale identifier (e.g. `en-US`, `zh-Hans`) |
| `--name` | *(required)* | App name (up to 30 characters) |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc app-info-localizations create \
  --app-info-id info-abc123 \
  --locale zh-Hans \
  --name "我的应用"
```

---

### Update App Info Localization

Update name, subtitle, or privacy policy URL for an existing localization. All fields are optional — only provided fields are changed.

```bash
asc app-info-localizations update --localization-id <LOCALIZATION_ID> [--name <n>] [--subtitle <s>] [--privacy-policy-url <url>]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--localization-id` | *(required)* | Localization ID |
| `--name` | *(optional)* | App name (up to 30 characters) |
| `--subtitle` | *(optional)* | Subtitle (up to 30 characters) |
| `--privacy-policy-url` | *(optional)* | Privacy policy URL |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Update name and subtitle
asc app-info-localizations update \
  --localization-id loc-001 \
  --name "My App" \
  --subtitle "Do things faster"

# Update only the privacy policy URL
asc app-info-localizations update \
  --localization-id loc-001 \
  --privacy-policy-url "https://example.com/privacy"
```

---

## Typical Workflow

```bash
# 1. Find your app
asc apps list --output table

# 2. Get the AppInfo ID (each app has one)
asc app-infos list --app-id <APP_ID> --output table

# 3. See what localizations already exist
asc app-info-localizations list --app-info-id <APP_INFO_ID> --output table

# 4a. Update an existing locale
asc app-info-localizations update \
  --localization-id <LOCALIZATION_ID> \
  --name "New Name" \
  --subtitle "New Subtitle"

# 4b. Add a new locale
asc app-info-localizations create \
  --app-info-id <APP_INFO_ID> \
  --locale zh-Hans \
  --name "应用名称"
```

Each response includes an `affordances` field with ready-to-run follow-up commands for AI agents.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                  App Info Localizations Feature                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ASC API                   Infrastructure            Domain           │
│  ┌──────────────────────┐  ┌────────────────────┐  ┌─────────────┐   │
│  │ GET /v1/apps/        │  │                    │  │  AppInfo    │   │
│  │ {id}/appInfos        │─▶│ SDKAppInfo         │─▶│  (struct)   │   │
│  │                      │  │ Repository         │  └─────────────┘   │
│  │ GET /v1/appInfos/    │  │                    │  ┌─────────────┐   │
│  │ {id}/appInfoLocal-   │─▶│ (implements        │─▶│AppInfoLocal-│   │
│  │ izations             │  │  AppInfoRepository)│  │ization      │   │
│  │                      │  │                    │  │ (struct)    │   │
│  │ POST /v1/appInfo-    │  │                    │  └─────────────┘   │
│  │ Localizations        │─▶│                    │  ┌─────────────┐   │
│  │                      │  │                    │  │AppInfoRepo- │   │
│  │ PATCH /v1/appInfo-   │  │                    │  │sitory       │   │
│  │ Localizations/{id}   │─▶│                    │  │(@Mockable)  │   │
│  └──────────────────────┘  └────────────────────┘  └─────────────┘   │
│                                                                       │
│  Resource hierarchy:                                                  │
│  App → AppInfo → AppInfoLocalization (name, subtitle, privacy URLs)  │
│  (distinct from App → AppStoreVersion → AppStoreVersionLocalization) │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  ASCCommand Layer                                             │   │
│  │  asc app-infos list --app-id <id>                            │   │
│  │  asc app-info-localizations list --app-info-id <id>          │   │
│  │  asc app-info-localizations create --app-info-id <id>        │   │
│  │  asc app-info-localizations update --localization-id <id>    │   │
│  └───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`

---

## Domain Models

### `AppInfo`

A thin container that groups all localizations for an app's metadata. Each app typically has one active AppInfo.

```swift
public struct AppInfo: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String    // Parent ID, always injected by Infrastructure

    // Affordances
    "listLocalizations": "asc app-info-localizations list --app-info-id <id>"
    "listAppInfos":      "asc app-infos list --app-id <appId>"
}
```

### `AppInfoLocalization`

Per-locale app metadata: name, subtitle, and privacy URLs.

```swift
public struct AppInfoLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appInfoId: String        // Parent ID, always injected by Infrastructure
    public let locale: String           // "en-US", "zh-Hans", etc.
    public let name: String?            // App name (up to 30 chars)
    public let subtitle: String?        // Subtitle (up to 30 chars)
    public let privacyPolicyUrl: String?
    public let privacyChoicesUrl: String?
    public let privacyPolicyText: String?

    // Affordances
    "listLocalizations": "asc app-info-localizations list --app-info-id <appInfoId>"
    "updateLocalization": "asc app-info-localizations update --localization-id <id>"
}
```

### `AppInfoRepository`

The DI boundary between the command layer and the API. Annotated with `@Mockable` for testing.

```swift
@Mockable
public protocol AppInfoRepository: Sendable {
    func listAppInfos(appId: String) async throws -> [AppInfo]
    func listLocalizations(appInfoId: String) async throws -> [AppInfoLocalization]
    func createLocalization(appInfoId: String, locale: String, name: String) async throws -> AppInfoLocalization
    func updateLocalization(id: String, name: String?, subtitle: String?, privacyPolicyUrl: String?) async throws -> AppInfoLocalization
}
```

### Updated `App` affordances

`App` now also exposes `listAppInfos`:

```swift
extension App: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "listVersions": "asc versions list --app-id \(id)",
            "listAppInfos": "asc app-infos list --app-id \(id)",
        ]
    }
}
```

---

## File Map

```
Sources/
├── Domain/AppInfos/
│   ├── AppInfo.swift                    # Value type + AffordanceProviding
│   ├── AppInfoLocalization.swift        # Value type + AffordanceProviding
│   └── AppInfoRepository.swift          # @Mockable protocol (4 methods)
├── Domain/Apps/
│   └── App.swift                        # Modified: added listAppInfos affordance
│
├── Infrastructure/AppInfos/
│   └── SDKAppInfoRepository.swift       # Implements AppInfoRepository; maps SDK → domain
│
└── ASCCommand/Commands/
    ├── AppInfos/
    │   └── AppInfosCommand.swift        # AppInfosCommand + AppInfosList
    └── AppInfoLocalizations/
        └── AppInfoLocalizationsCommand.swift  # + AppInfoLocalizationsList + AppInfoLocalizationsCreate + AppInfoLocalizationsUpdate

Tests/
├── DomainTests/AppInfos/
│   ├── AppInfoTests.swift               # Parent ID, affordances, equatability
│   └── AppInfoLocalizationTests.swift   # Parent ID, optional fields, affordances
├── DomainTests/Apps/
│   └── AffordancesTests.swift           # Modified: added AppInfo + AppInfoLocalization affordance tests
├── InfrastructureTests/AppInfos/
│   └── SDKAppInfoRepositoryTests.swift  # Parent ID injection, field mapping
├── ASCCommandTests/Commands/AppInfos/
│   └── AppInfosListTests.swift          # JSON output with affordances, arg passing
├── ASCCommandTests/Commands/AppInfoLocalizations/
│   ├── AppInfoLocalizationsListTests.swift    # JSON output with affordances, arg passing
│   └── AppInfoLocalizationsUpdateTests.swift  # Arg passing, affordances present
└── DomainTests/TestHelpers/
    └── MockRepositoryFactory.swift      # Modified: added makeAppInfo(), makeAppInfoLocalization()
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeAppInfoRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeAppInfoRepository()` |
| `Sources/ASCCommand/ASC.swift` | Added `AppInfosCommand.self`, `AppInfoLocalizationsCommand.self` |
| `Tests/ASCCommandTests/OutputFormatterTests.swift` | Updated App affordance snapshots |

---

## App Store Connect API Reference

| Endpoint | SDK call | Used by |
|----------|----------|---------|
| `GET /v1/apps/{id}/appInfos` | `.apps.id(id).appInfos.get()` | `listAppInfos` |
| `GET /v1/appInfos/{id}/appInfoLocalizations` | `.appInfos.id(id).appInfoLocalizations.get()` | `listLocalizations` |
| `POST /v1/appInfoLocalizations` | `.appInfoLocalizations.post(body)` | `createLocalization` |
| `PATCH /v1/appInfoLocalizations/{id}` | `.appInfoLocalizations.id(id).patch(body)` | `updateLocalization` |

The SDK is from [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk). `SDKAppInfoRepository` is marked `@unchecked Sendable` because `APIProvider` predates Swift 6 concurrency. The `updateLocalization` mapper extracts `appInfoId` from the PATCH response's `relationships.appInfo.data.id`.

---

## Testing

Tests follow the **Chicago school TDD** pattern: assert on state and return values, not on interactions.

```swift
@Test func `localization carries appInfoId`() {
    let loc = AppInfoLocalization(id: "loc-1", appInfoId: "info-42", locale: "en-US")
    #expect(loc.appInfoId == "info-42")
}

@Test func `listLocalizations injects appInfoId into each localization`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(AppInfoLocalizationsResponse(
        data: [
            AppInfoLocalization(type: .appInfoLocalizations, id: "loc-1", attributes: .init(locale: "en-US")),
        ],
        links: .init(this: "")
    ))
    let repo = SDKAppInfoRepository(client: stub)
    let result = try await repo.listLocalizations(appInfoId: "info-42")
    #expect(result.allSatisfy { $0.appInfoId == "info-42" })
}
```

Run the full test suite:

```bash
swift test
```

---

## Extending the Feature

### Adding delete localization

```swift
// 1. Domain protocol (AppInfoRepository.swift)
func deleteLocalization(id: String) async throws

// 2. Infrastructure SDK call
APIEndpoint.v1.appInfoLocalizations.id(id).delete

// 3. New subcommand in AppInfoLocalizationsCommand
```

### Adding category management

AppInfo also carries primary/secondary category relationships. To update categories:

```swift
func updateAppInfo(id: String, primaryCategoryId: String, secondaryCategoryId: String?) async throws -> AppInfo

// SDK: PATCH /v1/appInfos/{id} with AppInfoUpdateRequest
```
