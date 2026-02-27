# App Previews

Manage App Store video previews and preview sets using the `asc app-preview-sets` and `asc app-previews` commands.

App Previews are short video clips that appear on an app's App Store product page. They are organized into **Preview Sets**, where each set targets a specific device type (e.g. iPhone 6.7", Apple TV). Preview sets belong to an `AppStoreVersionLocalization`.

---

## CLI Usage

### `asc app-preview-sets list`

List all preview sets for a version localization.

| Flag | Required | Description |
|------|----------|-------------|
| `--localization-id` | Yes | App Store version localization ID |
| `--output` | No | Output format: `json` (default), `table`, `markdown` |
| `--pretty` | No | Pretty-print JSON output |

```bash
asc app-preview-sets list --localization-id <id> --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "listPreviewSets": "asc app-preview-sets list --localization-id loc-1",
        "listPreviews": "asc app-previews list --set-id set-1"
      },
      "id": "set-1",
      "localizationId": "loc-1",
      "previewType": "IPHONE_67",
      "previewsCount": 2
    }
  ]
}
```

**Table output:**

| ID | Preview Type | Device | Count |
|----|-------------|--------|-------|
| set-1 | IPHONE_67 | iPhone | 2 |

---

### `asc app-preview-sets create`

Create a new preview set for a localization.

| Flag | Required | Description |
|------|----------|-------------|
| `--localization-id` | Yes | App Store version localization ID |
| `--preview-type` | Yes | Preview type raw value (see table below) |
| `--output` | No | Output format |
| `--pretty` | No | Pretty-print JSON |

```bash
asc app-preview-sets create --localization-id <id> --preview-type IPHONE_67 --pretty
```

**Supported preview type values:**

| Raw Value | Device |
|-----------|--------|
| `IPHONE_67` | iPhone 6.7" |
| `IPHONE_61` | iPhone 6.1" |
| `IPHONE_65` | iPhone 6.5" |
| `IPHONE_58` | iPhone 5.8" |
| `IPHONE_55` | iPhone 5.5" |
| `IPHONE_47` | iPhone 4.7" |
| `IPHONE_40` | iPhone 4.0" |
| `IPHONE_35` | iPhone 3.5" |
| `IPAD_PRO_3GEN_129` | iPad Pro 12.9" (3rd gen) |
| `IPAD_PRO_3GEN_11` | iPad Pro 11" (3rd gen) |
| `IPAD_PRO_129` | iPad Pro 12.9" |
| `IPAD_105` | iPad 10.5" |
| `IPAD_97` | iPad 9.7" |
| `DESKTOP` | Mac |
| `APPLE_TV` | Apple TV |
| `APPLE_VISION_PRO` | Apple Vision Pro |

---

### `asc app-previews list`

List all video previews in a preview set.

| Flag | Required | Description |
|------|----------|-------------|
| `--set-id` | Yes | App preview set ID |
| `--output` | No | Output format |
| `--pretty` | No | Pretty-print JSON |

```bash
asc app-previews list --set-id <id> --pretty
```

**JSON output (complete preview):**
```json
{
  "data": [
    {
      "affordances": {
        "listPreviews": "asc app-previews list --set-id set-1"
      },
      "assetDeliveryState": "COMPLETE",
      "fileName": "preview.mp4",
      "fileSize": 10485760,
      "id": "prev-1",
      "mimeType": "video\/mp4",
      "setId": "set-1",
      "videoDeliveryState": "COMPLETE"
    }
  ]
}
```

Note: `mimeType`, `assetDeliveryState`, `videoDeliveryState`, `videoURL`, and `previewFrameTimeCode` are omitted from JSON when `nil`.

**Table output:**

| ID | File Name | Size | Asset State | Video State |
|----|-----------|------|-------------|-------------|
| prev-1 | preview.mp4 | 10.0 MB | Complete | Complete |

---

### `asc app-previews upload`

Upload a video file to an app preview set. Performs a 3-step upload: reserve slot → PUT chunks → PATCH confirm with MD5.

| Flag | Required | Description |
|------|----------|-------------|
| `--set-id` | Yes | App preview set ID |
| `--file` | Yes | Path to video file (`.mp4`, `.mov`, `.m4v`) |
| `--preview-frame-time-code` | No | Frame timecode for the preview thumbnail (e.g. `00:00:05`) |
| `--output` | No | Output format |
| `--pretty` | No | Pretty-print JSON |

```bash
asc app-previews upload --set-id <id> --file ./preview.mp4 --preview-frame-time-code 00:00:05 --pretty
```

---

## Typical Workflow

```bash
# 1. Get version localizations
LOCALE_ID=$(asc version-localizations list --version-id <version-id> | jq -r '.data[0].id')

# 2. Create a preview set for iPhone 6.7"
SET_ID=$(asc app-preview-sets create \
  --localization-id "$LOCALE_ID" \
  --preview-type IPHONE_67 \
  | jq -r '.data[0].id')

# 3. Upload a video preview
asc app-previews upload \
  --set-id "$SET_ID" \
  --file ./previews/iphone-preview.mp4 \
  --preview-frame-time-code 00:00:03 \
  --pretty

# 4. List previews to check delivery state
asc app-previews list --set-id "$SET_ID" --pretty
```

---

## Architecture

```
ASCCommand
  AppPreviewSetsCommand (app-preview-sets list | create)
  AppPreviewsCommand    (app-previews list | upload)
         │
         ▼
Infrastructure
  OpenAPIPreviewRepository
    listPreviewSets(localizationId:)    → GET /v1/appStoreVersionLocalizations/{id}/appPreviewSets
    createPreviewSet(localizationId:previewType:) → POST /v1/appPreviewSets
    listPreviews(setId:)                → GET /v1/appPreviewSets/{id}/appPreviews
    uploadPreview(setId:fileURL:previewFrameTimeCode:)
      step 1: POST /v1/appPreviews       (reserve slot + get upload ops)
      step 2: PUT  <presigned URLs>      (upload video chunks)
      step 3: PATCH /v1/appPreviews/{id} (confirm with MD5)
         │
         ▼
Domain
  PreviewRepository  (@Mockable protocol)
  AppPreviewSet      (struct: id, localizationId, previewType, previewsCount)
  AppPreview         (struct: id, setId, fileName, fileSize, mimeType?,
                             assetDeliveryState?, videoDeliveryState?,
                             videoURL?, previewFrameTimeCode?)
  PreviewType        (enum: 16 cases, IPHONE_67 … APPLE_VISION_PRO)
```

---

## Domain Models

### `AppPreviewSet`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Preview set identifier |
| `localizationId` | `String` | Parent localization ID (injected) |
| `previewType` | `PreviewType` | Device target for the previews |
| `previewsCount` | `Int` | Number of previews in the set |

**Computed properties:**
- `isEmpty: Bool` — true when `previewsCount == 0`
- `deviceCategory: PreviewType.DeviceCategory` — iPhone / iPad / mac / appleTV / appleVisionPro
- `displayTypeName: String` — human-readable device name (e.g. `"iPhone 6.7\""`)

**Affordances:**
```json
{
  "listPreviews": "asc app-previews list --set-id <id>",
  "listPreviewSets": "asc app-preview-sets list --localization-id <localizationId>"
}
```

---

### `AppPreview`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Preview identifier |
| `setId` | `String` | Parent preview set ID (injected) |
| `fileName` | `String` | Video filename |
| `fileSize` | `Int` | File size in bytes |
| `mimeType` | `String?` | MIME type (e.g. `video/mp4`) |
| `assetDeliveryState` | `AssetDeliveryState?` | Upload delivery state |
| `videoDeliveryState` | `VideoDeliveryState?` | Video encoding state |
| `videoURL` | `String?` | Streaming URL (available after encoding) |
| `previewFrameTimeCode` | `String?` | Thumbnail timecode |

**Computed properties:**
- `isComplete: Bool` — true when `videoDeliveryState == .complete`
- `hasFailed: Bool` — true when either delivery state is `.failed`
- `fileSizeDescription: String` — human-readable size (e.g. `"10.0 MB"`)

**`AssetDeliveryState` (upload progress — 4 states):**

| Case | Raw Value | Description |
|------|-----------|-------------|
| `.awaitingUpload` | `AWAITING_UPLOAD` | Slot reserved, upload pending |
| `.uploadComplete` | `UPLOAD_COMPLETE` | File uploaded, awaiting processing |
| `.complete` | `COMPLETE` | Ready for display |
| `.failed` | `FAILED` | Upload failed |

**`VideoDeliveryState` (video encoding — 5 states, unique to previews):**

| Case | Raw Value | Description |
|------|-----------|-------------|
| `.awaitingUpload` | `AWAITING_UPLOAD` | Upload not started |
| `.uploadComplete` | `UPLOAD_COMPLETE` | Upload done, encoding pending |
| `.processing` | `PROCESSING` | Video encoding in progress |
| `.complete` | `COMPLETE` | Encoding complete |
| `.failed` | `FAILED` | Encoding failed |

**Affordances:**
```json
{
  "listPreviews": "asc app-previews list --set-id <setId>"
}
```

---

### `PreviewType`

Enum with 16 cases, matching App Store Connect API raw values directly (no `APP_` prefix, unlike `ScreenshotDisplayType`).

```swift
public enum PreviewType: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    case iphone67 = "IPHONE_67"
    case appleTV = "APPLE_TV"
    case appleVisionPro = "APPLE_VISION_PRO"
    // ... 13 more
}
```

---

## File Map

```
Sources/
├── Domain/Apps/Versions/Localizations/PreviewSets/
│   ├── PreviewType.swift          — PreviewType enum (16 cases)
│   ├── AppPreviewSet.swift        — AppPreviewSet struct + AffordanceProviding
│   ├── PreviewRepository.swift    — @Mockable protocol
│   └── AppPreviews/
│       └── AppPreview.swift       — AppPreview struct + custom Codable + AffordanceProviding
├── Infrastructure/Apps/Versions/Localizations/PreviewSets/
│   └── OpenAPIPreviewRepository.swift  — 3-step upload, parent ID injection
└── ASCCommand/Commands/
    ├── AppPreviewSets/
    │   └── AppPreviewSetsCommand.swift  — list, create
    └── AppPreviews/
        └── AppPreviewsCommand.swift     — list, upload

Tests/
├── DomainTests/Apps/Versions/Localizations/PreviewSets/
│   ├── AppPreviewSetTests.swift
│   └── AppPreviews/
│       └── AppPreviewTests.swift
├── InfrastructureTests/Apps/Versions/Localizations/PreviewSets/
│   └── OpenAPIPreviewRepositoryTests.swift
└── ASCCommandTests/Commands/
    ├── AppPreviewSets/
    │   └── AppPreviewSetsCommandTests.swift
    └── AppPreviews/
        └── AppPreviewsCommandTests.swift

Wiring files:
├── Sources/Domain/TestHelpers/MockRepositoryFactory.swift  — makePreviewSet(), makePreview()
├── Sources/Infrastructure/Client/ClientFactory.swift       — makePreviewRepository()
├── Sources/ASCCommand/ClientProvider.swift                 — makePreviewRepository()
└── Sources/ASCCommand/ASC.swift                           — AppPreviewSetsCommand, AppPreviewsCommand
```

---

## API Reference

| Operation | Endpoint | SDK Call | Repository Method |
|-----------|----------|----------|-------------------|
| List preview sets | `GET /v1/appStoreVersionLocalizations/{id}/appPreviewSets` | `.appStoreVersionLocalizations.id(id).appPreviewSets.get(parameters:)` | `listPreviewSets(localizationId:)` |
| Create preview set | `POST /v1/appPreviewSets` | `.appPreviewSets.post(body)` | `createPreviewSet(localizationId:previewType:)` |
| List previews | `GET /v1/appPreviewSets/{id}/appPreviews` | `.appPreviewSets.id(id).appPreviews.get()` | `listPreviews(setId:)` |
| Upload preview (step 1) | `POST /v1/appPreviews` | `.appPreviews.post(body)` | `uploadPreview(setId:fileURL:previewFrameTimeCode:)` |
| Upload preview (step 2) | `PUT <presigned-url>` | `URLSession` | (same) |
| Upload preview (step 3) | `PATCH /v1/appPreviews/{id}` | `.appPreviews.id(id).patch(body)` | (same) |

---

## Testing

```swift
@Test func `listed preview sets include affordances for navigation`() async throws {
    let mockRepo = MockPreviewRepository()
    given(mockRepo).listPreviewSets(localizationId: .any).willReturn([
        AppPreviewSet(id: "set-1", localizationId: "loc-1", previewType: .iphone67, previewsCount: 3),
    ])

    let cmd = try AppPreviewSetsList.parse(["--localization-id", "loc-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "listPreviewSets" : "asc app-preview-sets list --localization-id loc-1",
            "listPreviews" : "asc app-previews list --set-id set-1"
          },
          "id" : "set-1",
          "localizationId" : "loc-1",
          "previewType" : "IPHONE_67",
          "previewsCount" : 3
        }
      ]
    }
    """)
}
```

Run all tests:
```bash
swift test
swift test --filter AppPreviewSetsCommandTests
swift test --filter AppPreviewsCommandTests
swift test --filter OpenAPIPreviewRepositoryTests
```

---

## Extending

**Delete a preview:**
```swift
// In PreviewRepository:
func deletePreview(previewId: String) async throws
// SDK: DELETE /v1/appPreviews/{id}

// In AppPreview affordances (add when isComplete):
"deletePreview": "asc app-previews delete --preview-id \(id)"
```

**Delete a preview set:**
```swift
// In PreviewRepository:
func deletePreviewSet(setId: String) async throws
// SDK: DELETE /v1/appPreviewSets/{id}

// In AppPreviewSet affordances (add when isEmpty):
"deletePreviewSet": "asc app-preview-sets delete --set-id \(id)"
```
