# Screenshots Feature

Browse App Store screenshot sets and individual screenshots for an app version localization via the App Store Connect API.

## CLI Usage

### List Screenshot Sets

List all screenshot sets for a given App Store version localization. Each set represents one display type (e.g. iPhone 6.7", iPad Pro 12.9").

```bash
asc screenshots sets --localization <LOCALIZATION_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--localization` | *(required)* | App Store version localization ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Default JSON output
asc screenshots sets --localization abc123def456

# Table view
asc screenshots sets --localization abc123def456 --output table

# Pipe into jq
asc screenshots sets --localization abc123def456 | jq '.[].screenshotDisplayType'
```

**Table output:**

```
ID                    Display Type         Device   Count
--------------------  -------------------  -------  -----
set-aaa               iPhone 6.7"          iPhone   5
set-bbb               iPad Pro 12.9" (3rd) iPad     3
set-ccc               Mac                  mac      0
```

---

### List Screenshots

List individual screenshots within a screenshot set.

```bash
asc screenshots list --set <SET_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--set` | *(required)* | Screenshot set ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Default JSON output
asc screenshots list --set set-aaa

# Table view — shows file name, size, dimensions, delivery state
asc screenshots list --set set-aaa --output table

# Markdown for documentation
asc screenshots list --set set-aaa --output markdown
```

**Table output:**

```
ID        File Name         Size     Dimensions    State
--------  ----------------  -------  ------------  --------
img-001   screen_01.png     2.8 MB   2796 × 1290   Complete
img-002   screen_02.png     2.4 MB   2796 × 1290   Complete
img-003   pending.png       0 B      -             Awaiting Upload
```

---

## Typical Workflow

Finding screenshot set IDs requires knowing the localization ID first:

```bash
# 1. Find your app
asc apps list --output table

# 2. Find builds for the app
asc builds list --app <APP_ID> --output table

# 3. Get the localization ID from your App Store Connect dashboard
#    or via a future `asc versions` command once implemented

# 4. List screenshot sets for the localization
asc screenshots sets --localization <LOCALIZATION_ID> --output table

# 5. Inspect screenshots in a specific set
asc screenshots list --set <SET_ID> --output table
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Screenshots Feature                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ASC API                 Infrastructure            Domain            │
│  ┌──────────────────┐    ┌──────────────────────┐  ┌─────────────┐  │
│  │ GET /v1/         │    │                      │  │AppScreenshot│  │
│  │ appStoreVersion  │───▶│ SDKScreenshot        │─▶│Set (struct) │  │
│  │ Localizations/   │    │ Repository           │  └─────────────┘  │
│  │ {id}/screenshot  │    │                      │  ┌─────────────┐  │
│  │ Sets             │    │ (implements          │─▶│AppScreenshot│  │
│  │                  │    │  ScreenshotRepo-     │  │ (struct)    │  │
│  │ GET /v1/         │    │  sitory)             │  └─────────────┘  │
│  │ appScreenshot    │───▶│                      │  ┌─────────────┐  │
│  │ Sets/{id}/       │    └──────────────────────┘  │Screenshot   │  │
│  │ appScreenshots   │                              │DisplayType  │  │
│  └──────────────────┘                              │ (enum)      │  │
│                                                    └─────────────┘  │
│                                                          │           │
│                                                          ▼           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  ASCCommand Layer                                            │   │
│  │  asc screenshots sets --localization <id>                    │   │
│  │  asc screenshots list --set <id>                             │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
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
    // ... 32 cases total

    // User asks: "Is this iPhone or iPad?"
    public var deviceCategory: DeviceCategory { ... }

    // User asks: "What should I call this in the UI?"
    public var displayName: String { ... }  // e.g. "iPhone 6.7\""
}
```

**Device categories:** `iPhone`, `iPad`, `mac`, `watch`, `appleTV`, `appleVisionPro`, `iMessage`

### `AppScreenshotSet`

A container of screenshots for one display type within a localization. ASC creates one set per supported display type.

```swift
public struct AppScreenshotSet: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let screenshotDisplayType: ScreenshotDisplayType
    public let screenshotsCount: Int

    // Convenience
    public var isEmpty: Bool                                   // no screenshots uploaded yet
    public var deviceCategory: ScreenshotDisplayType.DeviceCategory
    public var displayTypeName: String                         // e.g. "iPhone 6.7\""
}
```

### `AppScreenshot`

An individual screenshot within a set.

```swift
public struct AppScreenshot: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetDeliveryState?  // nil if not yet determined
    public let imageWidth: Int?
    public let imageHeight: Int?

    // Convenience
    public var isComplete: Bool              // assetState == .complete
    public var fileSizeDescription: String   // "2.8 MB", "512 B"
    public var dimensionsDescription: String? // "2796 × 1290", or nil
}
```

### `AppScreenshot.AssetDeliveryState`

```swift
public enum AssetDeliveryState: String, Sendable, Codable {
    case awaitingUpload = "AWAITING_UPLOAD"
    case uploadComplete = "UPLOAD_COMPLETE"
    case complete = "COMPLETE"
    case failed = "FAILED"

    public var isComplete: Bool  // ready for App Store submission
    public var hasFailed: Bool
    public var displayName: String
}
```

### `ScreenshotRepository`

The DI boundary between the command layer and the API. Annotated with `@Mockable` for testing.

```swift
@Mockable
public protocol ScreenshotRepository: Sendable {
    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]
    func listScreenshots(setId: String) async throws -> [AppScreenshot]
}
```

---

## File Map

```
Sources/
├── Domain/Screenshots/
│   ├── ScreenshotDisplayType.swift      # Enum: 32 display types with names + categories
│   ├── AppScreenshotSet.swift           # Value type: set container
│   ├── AppScreenshot.swift              # Value type: individual screenshot + AssetDeliveryState
│   └── ScreenshotRepository.swift       # @Mockable protocol
│
├── Infrastructure/Screenshots/
│   └── OpenAPIScreenshotRepository.swift  # SDKScreenshotRepository: maps SDK → domain
│
└── ASCCommand/Commands/Screenshots/
    └── ScreenshotsCommand.swift          # ScreenshotsCommand + ScreenshotSetsList + ScreenshotsList

Tests/
├── DomainTests/Screenshots/
│   ├── ScreenshotDisplayTypeTests.swift  # Category logic, display names, raw value round-trips
│   ├── AppScreenshotSetTests.swift       # isEmpty, delegation, equatability
│   ├── AppScreenshotTests.swift          # isComplete, formatting, asset state behavior
│   └── ScreenshotRepositoryTests.swift   # Mock protocol usage patterns
└── DomainTests/TestHelpers/
    └── MockRepositoryFactory.swift       # makeScreenshotSet(), makeScreenshot() factories
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeScreenshotRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeScreenshotRepository()` |
| `Sources/ASCCommand/ASC.swift` | Added `ScreenshotsCommand.self` to subcommands |

---

## App Store Connect API Reference

| Endpoint | SDK call | Used by |
|----------|----------|---------|
| `GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets` | `APIEndpoint.v1.appStoreVersionLocalizations.id(id).appScreenshotSets.get()` | `listScreenshotSets` |
| `GET /v1/appScreenshotSets/{id}/appScreenshots` | `APIEndpoint.v1.appScreenshotSets.id(id).appScreenshots.get()` | `listScreenshots` |

The SDK is from [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk). The infrastructure adapter (`SDKScreenshotRepository`) handles the mapping between SDK types and domain types and is marked `@unchecked Sendable` because `APIProvider` from the SDK predates Swift 6 concurrency.

---

## Testing

Tests follow the **Chicago school TDD** pattern: assert on state and return values, not on interactions.

```swift
// Stub the repository, assert on returned state
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

The screenshots feature is scoped to **read operations**. The natural next steps follow the same pattern:

### Adding Upload

Upload requires a three-step ASC API flow:

1. `POST /v1/appScreenshots` — reserve a slot, get upload operations
2. Upload the binary directly to the signed S3 URLs in `uploadOperations`
3. `PATCH /v1/appScreenshots/{id}` with `isUploaded: true` and `sourceFileChecksum` to commit

Add to `ScreenshotRepository`:

```swift
func createScreenshot(setId: String, fileName: String, fileSize: Int) async throws -> AppScreenshot
func commitScreenshot(id: String, checksum: String) async throws -> AppScreenshot
```

### Adding Delete

```swift
// Domain protocol
func deleteScreenshot(id: String) async throws
func deleteScreenshotSet(id: String) async throws

// SDK calls
APIEndpoint.v1.appScreenshots.id(id).delete
APIEndpoint.v1.appScreenshotSets.id(id).delete
```

### Adding Reorder

```swift
// PATCH /v1/appScreenshotSets/{id}/relationships/appScreenshots
func reorderScreenshots(setId: String, orderedIds: [String]) async throws
```

### Pattern to Follow

1. Add method to `ScreenshotRepository` protocol in `Sources/Domain/Screenshots/`
2. Implement in `SDKScreenshotRepository` in `Sources/Infrastructure/Screenshots/`
3. Add command in `Sources/ASCCommand/Commands/Screenshots/ScreenshotsCommand.swift`
4. Write domain tests first (Red → Green → Refactor)
