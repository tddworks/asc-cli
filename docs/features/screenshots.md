# Screenshots Feature

Manage App Store screenshot sets and individual screenshots for an app version localization via the App Store Connect API.

## CLI Usage

### List Screenshot Sets

List all screenshot sets for a given App Store version localization. Each set represents one display type (e.g. iPhone 6.7", iPad Pro 12.9").

```bash
asc screenshot-sets list --localization-id <LOCALIZATION_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--localization-id` | *(required)* | App Store version localization ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Default JSON output
asc screenshot-sets list --localization-id abc123def456

# Table view
asc screenshot-sets list --localization-id abc123def456 --output table

# Pipe into jq
asc screenshot-sets list --localization-id abc123def456 | jq '.[].screenshotDisplayType'
```

**Table output:**

```
ID                    Display Type              Device   Count
--------------------  ------------------------  -------  -----
set-aaa               iPhone 6.7"               iPhone   5
set-bbb               iPad Pro 12.9" (3rd gen)  iPad     3
set-ccc               Mac                       mac      0
```

---

### Create Screenshot Set

Create a new screenshot set for a display type within a localization.

```bash
asc screenshot-sets create --localization-id <LOCALIZATION_ID> --display-type <TYPE>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--localization-id` | *(required)* | App Store version localization ID |
| `--display-type` | *(required)* | Display type raw value (e.g. `APP_IPHONE_67`) |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc screenshot-sets create --localization-id abc123 --display-type APP_IPHONE_67
```

---

### List Screenshots

List individual screenshots within a screenshot set.

```bash
asc screenshots list --set-id <SET_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--set-id` | *(required)* | Screenshot set ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Default JSON output
asc screenshots list --set-id set-aaa

# Table view — shows file name, size, dimensions, delivery state
asc screenshots list --set-id set-aaa --output table

# Markdown for documentation
asc screenshots list --set-id set-aaa --output markdown
```

**Table output:**

```
ID        File Name         Size     Dimensions    State
--------  ----------------  -------  ------------  ---------------
img-001   screen_01.png     2.8 MB   2796 × 1290   Complete
img-002   screen_02.png     2.4 MB   2796 × 1290   Complete
img-003   pending.png       0 B      -             Awaiting Upload
```

---

### Upload Screenshot

Upload a screenshot image file to a screenshot set. Internally orchestrates the three-step ASC API flow (reserve → S3 upload → commit).

```bash
asc screenshots upload --set-id <SET_ID> --file <PATH>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--set-id` | *(required)* | Screenshot set ID |
| `--file` | *(required)* | Local path to the image file |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc screenshots upload --set-id set-aaa --file ./screens/iphone_hero.png
```

---

## Typical Workflow

```bash
# 1. Find your app
asc apps list --output table

# 2. Find or create a version
asc versions list --app <APP_ID> --output table

# 3. List localizations for the version
asc version-localizations list --version-id <VERSION_ID> --output table

# 4. List screenshot sets for a localization
asc screenshot-sets list --localization-id <LOCALIZATION_ID> --output table

# 5. Create a set if needed
asc screenshot-sets create --localization-id <LOCALIZATION_ID> --display-type APP_IPHONE_67

# 6. Upload screenshots
asc screenshots upload --set-id <SET_ID> --file ./screens/screen01.png

# 7. Verify upload
asc screenshots list --set-id <SET_ID> --output table
```

Each response includes an `affordances` field with ready-to-run follow-up commands, so an AI agent can navigate the hierarchy without knowing the full command tree.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                      Screenshots Feature                              │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ASC API                   Infrastructure            Domain           │
│  ┌──────────────────────┐  ┌────────────────────┐  ┌─────────────┐   │
│  │ GET /v1/             │  │                    │  │AppScreenshot│   │
│  │ appStoreVersionLocal │─▶│ SDKScreenshot      │─▶│Set (struct) │   │
│  │ izations/{id}/       │  │ Repository         │  └─────────────┘   │
│  │ appScreenshotSets    │  │                    │  ┌─────────────┐   │
│  │                      │  │ (implements        │─▶│AppScreenshot│   │
│  │ POST /v1/            │  │  ScreenshotRepo-   │  │ (struct)    │   │
│  │ appScreenshotSets    │  │  sitory)           │  └─────────────┘   │
│  │                      │  │                    │  ┌─────────────┐   │
│  │ GET /v1/             │  │ Upload: 3 API      │─▶│Screenshot   │   │
│  │ appScreenshotSets/   │─▶│ calls internally   │  │DisplayType  │   │
│  │ {id}/appScreenshots  │  │ (reserve → S3 →    │  │ (enum)      │   │
│  │                      │  │  commit)           │  └─────────────┘   │
│  │ POST /v1/            │  │                    │  ┌─────────────┐   │
│  │ appScreenshots       │  └────────────────────┘  │AppStoreVer- │   │
│  │ PATCH /v1/           │                          │sionLocaliz- │   │
│  │ appScreenshots/{id}  │                          │ation        │   │
│  └──────────────────────┘                          └─────────────┘   │
│                                                           │           │
│                                                           ▼           │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  ASCCommand Layer                                             │   │
│  │  asc screenshot-sets list --localization-id <id>             │   │
│  │  asc screenshot-sets create --localization-id <id>           │   │
│  │  asc screenshots list --set-id <id>                          │   │
│  │  asc screenshots upload --set-id <id> --file <path>          │   │
│  └───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`

The domain layer has zero dependency on the SDK or networking. Infrastructure adapts SDK types to domain types. Commands depend only on `ScreenshotRepository` (the protocol), never on the SDK directly.

---

## Domain Models

### `ScreenshotDisplayType`

An enum mapping all ASC display type raw values to human-readable names and device categories.

```swift
public enum ScreenshotDisplayType: String, Sendable, CaseIterable {
    case iphone67 = "APP_IPHONE_67"
    case ipadPro3gen129 = "APP_IPAD_PRO_3GEN_129"
    case desktop = "APP_DESKTOP"
    case appleVisionPro = "APP_APPLE_VISION_PRO"
    // ... 39 cases total

    public var deviceCategory: DeviceCategory { ... }
    public var displayName: String { ... }  // e.g. "iPhone 6.7\""
}
```

**Device categories:** `iPhone`, `iPad`, `mac`, `watch`, `appleTV`, `appleVisionPro`, `iMessage`

### `AppStoreVersionLocalization`

A localization record tying a version to a locale (e.g. `en-US`). Carries its parent `versionId` for upward navigation.

```swift
public struct AppStoreVersionLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let versionId: String    // Parent ID, always injected by Infrastructure
    public let locale: String       // "en-US", "zh-Hans", etc.

    // Affordances
    "listScreenshotSets": "asc screenshot-sets list --localization-id <id>"
    "listLocalizations":  "asc version-localizations list --version-id <versionId>"
}
```

### `AppScreenshotSet`

A container of screenshots for one display type within a localization. ASC creates one set per supported display type.

```swift
public struct AppScreenshotSet: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let localizationId: String               // Parent ID, always injected
    public let screenshotDisplayType: ScreenshotDisplayType
    public let screenshotsCount: Int                // Defaults to 0

    // Convenience
    public var isEmpty: Bool                        // screenshotsCount == 0
    public var deviceCategory: ScreenshotDisplayType.DeviceCategory
    public var displayTypeName: String              // e.g. "iPhone 6.7\""

    // Affordances
    "listScreenshots":    "asc screenshots list --set-id <id>"
    "listScreenshotSets": "asc screenshot-sets list --localization-id <localizationId>"
}
```

### `AppScreenshot`

An individual screenshot within a set.

```swift
public struct AppScreenshot: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let setId: String                        // Parent ID, always injected
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetDeliveryState?      // nil if not yet determined
    public let imageWidth: Int?
    public let imageHeight: Int?

    // Convenience
    public var isComplete: Bool                     // assetState == .complete
    public var fileSizeDescription: String          // "2.8 MB", "512 B"
    public var dimensionsDescription: String?       // "2796 × 1290", or nil
}
```

### `AppScreenshot.AssetDeliveryState`

```swift
public enum AssetDeliveryState: String, Sendable, Codable {
    case awaitingUpload = "AWAITING_UPLOAD"
    case uploadComplete = "UPLOAD_COMPLETE"
    case complete       = "COMPLETE"
    case failed         = "FAILED"

    public var isComplete: Bool     // ready for App Store submission
    public var hasFailed: Bool
    public var displayName: String  // "Complete", "Failed", etc.
}
```

### `ScreenshotRepository`

The DI boundary between the command layer and the API. Annotated with `@Mockable` for testing.

```swift
@Mockable
public protocol ScreenshotRepository: Sendable {
    func listLocalizations(versionId: String) async throws -> [AppStoreVersionLocalization]
    func createLocalization(versionId: String, locale: String) async throws -> AppStoreVersionLocalization

    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]
    func createScreenshotSet(localizationId: String, displayType: ScreenshotDisplayType) async throws -> AppScreenshotSet

    func listScreenshots(setId: String) async throws -> [AppScreenshot]
    func uploadScreenshot(setId: String, fileURL: URL) async throws -> AppScreenshot
}
```

---

## File Map

```
Sources/
├── Domain/Screenshots/
│   ├── ScreenshotDisplayType.swift        # Enum: 39 display types with names + categories
│   ├── AppScreenshotSet.swift             # Value type: set container with affordances
│   ├── AppScreenshot.swift                # Value type: individual screenshot + AssetDeliveryState
│   └── ScreenshotRepository.swift         # @Mockable protocol
│
├── Infrastructure/Screenshots/
│   └── OpenAPIScreenshotRepository.swift  # SDKScreenshotRepository: maps SDK → domain
│
└── ASCCommand/Commands/
    ├── ScreenshotSets/
    │   └── ScreenshotSetsCommand.swift    # ScreenshotSetsCommand + ScreenshotSetsList + ScreenshotSetsCreate
    └── Screenshots/
        └── ScreenshotsCommand.swift       # ScreenshotsCommand + ScreenshotsList + ScreenshotsUpload

Tests/
├── DomainTests/Screenshots/
│   ├── ScreenshotDisplayTypeTests.swift   # Category logic, display names, raw value round-trips
│   ├── AppScreenshotSetTests.swift        # isEmpty, delegation, parent ID injection
│   ├── AppScreenshotTests.swift           # isComplete, formatting, asset state behavior
│   └── ScreenshotRepositoryTests.swift    # Mock protocol usage patterns
├── InfrastructureTests/Screenshots/
│   ├── SDKScreenshotRepositoryTests.swift       # Mapping + parent ID injection for list methods
│   └── SDKScreenshotRepositoryCreateTests.swift # Mapping for create methods
├── ASCCommandTests/Commands/Screenshots/
│   ├── ScreenshotsListTests.swift         # JSON output and argument passing
│   └── ScreenshotsUploadTests.swift       # JSON output and argument passing
├── ASCCommandTests/Commands/ScreenshotSets/
│   ├── ScreenshotSetsListTests.swift      # JSON output includes affordances
│   └── ScreenshotSetsCreateTests.swift    # JSON output and argument passing
└── DomainTests/TestHelpers/
    └── MockRepositoryFactory.swift        # makeScreenshotSet(), makeScreenshot(), makeLocalization()
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeScreenshotRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeScreenshotRepository()` |
| `Sources/ASCCommand/ASC.swift` | Added `ScreenshotSetsCommand.self` + `ScreenshotsCommand.self` |

---

## App Store Connect API Reference

| Endpoint | SDK call | Used by |
|----------|----------|---------|
| `GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations` | `.appStoreVersions.id(id).appStoreVersionLocalizations.get()` | `listLocalizations` |
| `POST /v1/appStoreVersionLocalizations` | `.appStoreVersionLocalizations.post(body)` | `createLocalization` |
| `GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets` | `.appStoreVersionLocalizations.id(id).appScreenshotSets.get()` | `listScreenshotSets` |
| `POST /v1/appScreenshotSets` | `.appScreenshotSets.post(body)` | `createScreenshotSet` |
| `GET /v1/appScreenshotSets/{id}/appScreenshots` | `.appScreenshotSets.id(id).appScreenshots.get()` | `listScreenshots` |
| `POST /v1/appScreenshots` | `.appScreenshots.post(body)` | `uploadScreenshot` step 1: reserve |
| *(S3 direct upload)* | `URLSession` with MD5 checksum | `uploadScreenshot` step 2: binary |
| `PATCH /v1/appScreenshots/{id}` | `.appScreenshots.id(id).patch(body)` | `uploadScreenshot` step 3: commit |

The SDK is from [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk). `SDKScreenshotRepository` is marked `@unchecked Sendable` because `APIProvider` predates Swift 6 concurrency.

---

## Testing

Tests follow the **Chicago school TDD** pattern: assert on state and return values, not on interactions.

```swift
@Test
func `list screenshot sets returns sets for localization`() async throws {
    let mock = MockScreenshotRepository()
    given(mock).listScreenshotSets(localizationId: .any).willReturn([
        MockRepositoryFactory.makeScreenshotSet(id: "set-1", displayType: .iphone67),
    ])

    let result = try await mock.listScreenshotSets(localizationId: "loc-123")
    #expect(result[0].screenshotDisplayType == .iphone67)
}
```

Run the full test suite:

```bash
swift test
# or
make test
```

---

## Extending the Feature

The natural next steps follow the same layer-by-layer pattern:

### Adding Delete

```swift
// 1. Domain protocol (ScreenshotRepository.swift)
func deleteScreenshot(id: String) async throws
func deleteScreenshotSet(id: String) async throws

// 2. Infrastructure SDK calls
APIEndpoint.v1.appScreenshots.id(id).delete
APIEndpoint.v1.appScreenshotSets.id(id).delete

// 3. New subcommands in ScreenshotsCommand / ScreenshotSetsCommand
```

### Adding Reorder

```swift
// PATCH /v1/appScreenshotSets/{id}/relationships/appScreenshots
func reorderScreenshots(setId: String, orderedIds: [String]) async throws
```

### Pattern to Follow

1. Add method to `ScreenshotRepository` protocol in `Sources/Domain/Screenshots/`
2. Implement in `SDKScreenshotRepository` in `Sources/Infrastructure/Screenshots/`
3. Add subcommand in `Sources/ASCCommand/Commands/Screenshots/` or `ScreenshotSets/`
4. Write domain tests first (Red → Green → Refactor)