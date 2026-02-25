# Builds Upload Feature

Upload IPA/PKG builds to App Store Connect, link builds to versions, manage TestFlight distribution and "What's New" notes.

## CLI Usage

### Upload a Build

Upload an `.ipa` (iOS/tvOS/visionOS) or `.pkg` (macOS) file to App Store Connect.

```bash
asc builds upload --app-id <APP_ID> --file <PATH> --version <VERSION> --build-number <BUILD>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-id` | *(required)* | App Store Connect app ID |
| `--file` | *(required)* | Path to `.ipa` or `.pkg` file |
| `--version` | *(required)* | `CFBundleShortVersionString` (e.g. `1.0.0`) |
| `--build-number` | *(required)* | `CFBundleVersion` (e.g. `42`) |
| `--platform` | auto-detected | `ios`, `macos`, `tvos`, `visionos` — defaults to `ios` (`.pkg` → `macos`) |
| `--wait` | `false` | Poll until processing completes |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Upload iOS build — auto-detects platform from .ipa extension
asc builds upload --app-id 123456789 --file ./MyApp.ipa --version 1.0.0 --build-number 42

# Upload macOS build — auto-detects platform from .pkg extension
asc builds upload --app-id 123456789 --file ./MyApp.pkg --version 1.0.0 --build-number 42

# Upload and wait for processing to finish
asc builds upload --app-id 123456789 --file ./MyApp.ipa --version 1.0.0 --build-number 42 --wait

# Table view
asc builds upload --app-id 123456789 --file ./MyApp.ipa --version 1.0.0 --build-number 42 --output table
```

**JSON output:**

```json
{
  "data": [
    {
      "affordances": {
        "checkStatus": "asc builds uploads get --upload-id abc123",
        "listBuilds": "asc builds list --app-id 123456789"
      },
      "appId": "123456789",
      "buildNumber": "42",
      "id": "abc123",
      "platform": "IOS",
      "state": "COMPLETE",
      "version": "1.0.0"
    }
  ]
}
```

**Note:** `listBuilds` affordance only appears when `state == "COMPLETE"`.

---

### List Build Uploads

List all build upload records for an app.

```bash
asc builds uploads list --app-id <APP_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-id` | *(required)* | App Store Connect app ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

---

### Get a Build Upload

Fetch a specific build upload record by ID.

```bash
asc builds uploads get --upload-id <UPLOAD_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--upload-id` | *(required)* | Build upload ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Note:** `appId` is empty in this response (ASC API limitation); `listBuilds` affordance is suppressed.

---

### Delete a Build Upload

Delete a pending upload record.

```bash
asc builds uploads delete --upload-id <UPLOAD_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--upload-id` | *(required)* | Build upload ID |

---

### Add Beta Group to a Build

Make a build available to a TestFlight beta group.

```bash
asc builds add-beta-group --build-id <BUILD_ID> --beta-group-id <GROUP_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--build-id` | *(required)* | Build ID |
| `--beta-group-id` | *(required)* | Beta group ID |

---

### Remove Beta Group from a Build

```bash
asc builds remove-beta-group --build-id <BUILD_ID> --beta-group-id <GROUP_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--build-id` | *(required)* | Build ID |
| `--beta-group-id` | *(required)* | Beta group ID |

---

### Update TestFlight "What's New" Notes

Set or update the beta "What's New" text for a build locale. Creates the localization if it doesn't exist.

```bash
asc builds update-beta-notes --build-id <BUILD_ID> --locale <LOCALE> --notes "<TEXT>"
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--build-id` | *(required)* | Build ID |
| `--locale` | *(required)* | Locale code (e.g. `en-US`) |
| `--notes` | *(required)* | TestFlight "What's New" text |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**JSON output:**

```json
{
  "data": [
    {
      "affordances": {
        "updateNotes": "asc builds update-beta-notes --build-id build-1 --locale en-US --notes <text>"
      },
      "buildId": "build-1",
      "id": "bbl-1",
      "locale": "en-US",
      "whatsNew": "Bug fixes and performance improvements."
    }
  ]
}
```

---

### Link Build to App Store Version

Associate a processed build with an App Store version before submitting for review.

```bash
asc versions set-build --version-id <VERSION_ID> --build-id <BUILD_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--version-id` | *(required)* | App Store version ID |
| `--build-id` | *(required)* | Build ID |

---

## Typical Workflow

End-to-end: upload a build, wait for processing, add beta testers, update notes, link to a version for release.

```bash
# 1. Upload and wait for processing
UPLOAD=$(asc builds upload \
  --app-id 123456789 \
  --file ./MyApp.ipa \
  --version 1.2.0 \
  --build-number 55 \
  --wait --pretty)
echo "$UPLOAD"

# 2. Find the processed build ID
BUILD_ID=$(asc builds list --app-id 123456789 | jq -r '.data[0].id')

# 3. Add a beta group for TestFlight distribution
GROUP_ID=$(asc testflight groups list --app-id 123456789 | jq -r '.data[0].id')
asc builds add-beta-group --build-id "$BUILD_ID" --beta-group-id "$GROUP_ID"

# 4. Set "What's New" notes for all locales
asc builds update-beta-notes --build-id "$BUILD_ID" --locale en-US \
  --notes "What's new in 1.2.0: Performance improvements, bug fixes."

# 5. Find the version and link the build for App Store release
VERSION_ID=$(asc versions list --app-id 123456789 | jq -r '.data[0].id')
asc versions set-build --version-id "$VERSION_ID" --build-id "$BUILD_ID"

# 6. Submit for review
asc versions submit --version-id "$VERSION_ID"
```

---

## Architecture

```
ASCCommand                Infrastructure              Domain
──────────────────────────────────────────────────────────────
BuildsUpload              SDKBuildUploadRepository   BuildUpload
  uploadBuild()    ──────►  5-step upload flow  ────► BuildUploadState
BuildsUploadsGet            listBuildUploads()         BuildUploadPlatform
BuildsUploadsList           getBuildUpload()            BuildUploadRepository
BuildsUploadsDelete         deleteBuildUpload()
BuildsAddBetaGroup        OpenAPIBuildRepository      (extends BuildRepository)
BuildsRemoveBetaGroup       addBetaGroups()
BuildsUpdateBetaNotes     SDKBetaBuildLocalizationRepository
  upsertBetaBuildLocalization()  ──────────────►      BetaBuildLocalization
VersionsSetBuild           SDKVersionRepository        BetaBuildLocalizationRepository
  setBuild()       ──────►  PATCH appStoreVersions ──► (extends VersionRepository)
```

**Dependencies:** `appstoreconnect-swift-sdk`, `CryptoKit` (MD5 checksum for upload confirmation)

---

## Domain Models

### `BuildUpload`

Represents a build upload session.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Upload session ID |
| `appId` | `String` | Parent app ID (injected by infrastructure) |
| `version` | `String` | `CFBundleShortVersionString` |
| `buildNumber` | `String` | `CFBundleVersion` |
| `platform` | `BuildUploadPlatform` | Target platform |
| `state` | `BuildUploadState` | Current upload state |
| `createdDate` | `Date?` | Session creation time (omitted if nil) |
| `uploadedDate` | `Date?` | Completion time (omitted if nil) |

**Affordances:**

| Key | Command | Condition |
|-----|---------|-----------|
| `checkStatus` | `asc builds uploads get --upload-id <id>` | always |
| `listBuilds` | `asc builds list --app-id <appId>` | `state == .complete && !appId.isEmpty` |

### `BuildUploadState`

| Value | Raw | Semantic |
|-------|-----|---------|
| `.awaitingUpload` | `AWAITING_UPLOAD` | `isPending == true` |
| `.processing` | `PROCESSING` | `isPending == true` |
| `.failed` | `FAILED` | `hasFailed == true` |
| `.complete` | `COMPLETE` | `isComplete == true` |

### `BuildUploadPlatform`

| Value | Raw | CLI arg |
|-------|-----|---------|
| `.iOS` | `IOS` | `ios` |
| `.macOS` | `MAC_OS` | `macos` |
| `.tvOS` | `TV_OS` | `tvos` |
| `.visionOS` | `VISION_OS` | `visionos` |

### `BetaBuildLocalization`

TestFlight "What's New" text per locale per build.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Localization ID |
| `buildId` | `String` | Parent build ID (injected by infrastructure) |
| `locale` | `String` | Locale code (e.g. `en-US`) |
| `whatsNew` | `String?` | TestFlight notes (omitted if nil) |

**Affordances:**

| Key | Command |
|-----|---------|
| `updateNotes` | `asc builds update-beta-notes --build-id <buildId> --locale <locale> --notes <text>` |

---

## File Map

### Sources

```
Sources/Domain/Apps/Builds/
  BuildUpload.swift                     — BuildUpload model, BuildUploadState, BuildUploadPlatform
  BuildUploadRepository.swift           — @Mockable BuildUploadRepository protocol
  BetaBuildLocalization.swift           — BetaBuildLocalization model
  BetaBuildLocalizationRepository.swift — @Mockable BetaBuildLocalizationRepository protocol
  BuildRepository.swift                 — Extended with addBetaGroups/removeBetaGroups
Sources/Domain/Apps/Versions/
  VersionRepository.swift               — Extended with setBuild

Sources/Infrastructure/Apps/Builds/
  SDKBuildUploadRepository.swift        — 5-step upload + list/get/delete
  SDKBetaBuildLocalizationRepository.swift — upsert (GET+PATCH or POST)
  OpenAPIBuildRepository.swift          — addBetaGroups/removeBetaGroups via relationships endpoint
Sources/Infrastructure/Apps/Versions/
  SDKVersionRepository.swift            — setBuild via PATCH with build relationship
Sources/Infrastructure/Client/
  ClientFactory.swift                   — makeBuildUploadRepository, makeBetaBuildLocalizationRepository

Sources/ASCCommand/Commands/Builds/
  BuildsUpload.swift                    — asc builds upload
  BuildsUploadsCommand.swift            — asc builds uploads (group)
  BuildsUploadsList.swift               — asc builds uploads list
  BuildsUploadsGet.swift                — asc builds uploads get
  BuildsUploadsDelete.swift             — asc builds uploads delete
  BuildsAddBetaGroup.swift              — asc builds add-beta-group
  BuildsRemoveBetaGroup.swift           — asc builds remove-beta-group
  BuildsUpdateBetaNotes.swift           — asc builds update-beta-notes
  BuildsCommand.swift                   — (updated) registers all new subcommands
Sources/ASCCommand/Commands/Versions/
  VersionsSetBuild.swift                — asc versions set-build
  VersionsCommand.swift                 — (updated) registers VersionsSetBuild
Sources/ASCCommand/
  ClientProvider.swift                  — makeBuildUploadRepository, makeBetaBuildLocalizationRepository
```

### Tests

```
Tests/DomainTests/Apps/Builds/
  BuildUploadTests.swift                — state semantics, platform CLI args, affordances, nil date omission
  BetaBuildLocalizationTests.swift      — buildId parent, affordances, whatsNew nil omission
Tests/DomainTests/Apps/
  AffordancesTests.swift                — BuildUpload and BetaBuildLocalization affordance tests
Tests/DomainTests/TestHelpers/
  MockRepositoryFactory.swift           — makeBuildUpload, makeBetaBuildLocalization factories
Tests/InfrastructureTests/Apps/Builds/
  SDKBuildUploadRepositoryTests.swift   — listBuildUploads appId injection, getBuildUpload empty appId, state mapping
  SDKBetaBuildLocalizationRepositoryTests.swift — buildId injection
Tests/ASCCommandTests/Commands/TestFlight/
  TestFlightCommandTests.swift          — BetaGroupsList, BetaTestersList, BetaTestersAdd, BetaTestersRemove,
                                          BetaTestersImport, BetaTestersExport command tests
```

---

## API Reference

| ASC API Endpoint | SDK Call | Repository Method |
|-----------------|----------|-------------------|
| `POST /v1/buildUploads` | `APIEndpoint.v1.buildUploads.post(body)` | `uploadBuild` step 1 |
| `POST /v1/buildUploadFiles` | `APIEndpoint.v1.buildUploadFiles.post(body)` | `uploadBuild` step 2 |
| `PUT <presigned-url>` | `URLSession.shared.data(for:)` | `uploadBuild` step 3 |
| `PATCH /v1/buildUploadFiles/{id}` | `APIEndpoint.v1.buildUploadFiles.id(id).patch(body)` | `uploadBuild` step 4 |
| `GET /v1/buildUploads/{id}` | `APIEndpoint.v1.buildUploads.id(id).get()` | `uploadBuild` step 5, `getBuildUpload` |
| `GET /v1/apps/{id}/buildUploads` | `APIEndpoint.v1.apps.id(appId).buildUploads.get()` | `listBuildUploads` |
| `DELETE /v1/buildUploads/{id}` | `APIEndpoint.v1.buildUploads.id(id).delete` | `deleteBuildUpload` |
| `POST /v1/builds/{id}/relationships/betaGroups` | `APIEndpoint.v1.builds.id(buildId).relationships.betaGroups.post(body)` | `addBetaGroups` |
| `DELETE /v1/builds/{id}/relationships/betaGroups` | `APIEndpoint.v1.builds.id(buildId).relationships.betaGroups.delete(body)` | `removeBetaGroups` |
| `GET /v1/builds/{id}/betaBuildLocalizations` | `APIEndpoint.v1.builds.id(buildId).betaBuildLocalizations.get()` | `listBetaBuildLocalizations` |
| `POST /v1/betaBuildLocalizations` | `APIEndpoint.v1.betaBuildLocalizations.post(body)` | `upsertBetaBuildLocalization` (create) |
| `PATCH /v1/betaBuildLocalizations/{id}` | `APIEndpoint.v1.betaBuildLocalizations.id(id).patch(body)` | `upsertBetaBuildLocalization` (update) |
| `PATCH /v1/appStoreVersions/{id}` | `APIEndpoint.v1.appStoreVersions.id(id).patch(body)` | `setBuild` |

---

## Testing

```swift
@Test func `upload returns buildUpload with state and affordances`() async throws {
    let mockRepo = MockBuildUploadRepository()
    given(mockRepo).uploadBuild(
        appId: .any, version: .any, buildNumber: .any, platform: .any, fileURL: .any
    ).willReturn(MockRepositoryFactory.makeBuildUpload(
        id: "up-1", appId: "app-42", state: .complete
    ))

    let cmd = try BuildsUpload.parse([
        "--app-id", "app-42", "--file", "MyApp.ipa",
        "--version", "1.0.0", "--build-number", "1", "--pretty"
    ])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output.contains("\"checkStatus\" : \"asc builds uploads get --upload-id up-1\""))
    #expect(output.contains("\"listBuilds\" : \"asc builds list --app-id app-42\""))
}
```

Run all tests:

```bash
swift test
```

---

## Extending

### Add tvOS / visionOS platform detection

`BuildsUpload.execute` already detects `.pkg` → macOS. Add extension-based detection for tvOS/visionOS:

```swift
// In BuildsUpload.execute (BuildsUpload.swift)
let ext = fileURL.pathExtension.lowercased()
resolvedPlatform = ext == "pkg" ? .macOS : ext == "visionos" ? .visionOS : .iOS
```

### Paginate build upload list

`listBuildUploads` returns all records. To add `--limit`:

```swift
// In BuildUploadRepository.swift
func listBuildUploads(appId: String, limit: Int?) async throws -> [BuildUpload]

// In SDKBuildUploadRepository.swift
let request = APIEndpoint.v1.apps.id(appId).buildUploads.get(
    parameters: .init(limit: limit)
)
```
