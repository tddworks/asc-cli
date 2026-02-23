# Screenshot Editor Feature

A browser-based screenshot compositor. Users design App Store screenshots (background + device bezel + text layers) in a visual editor, export a ZIP, then upload it to App Store Connect in one command.

```
asc screenshots import        → reads export.zip, uploads to App Store Connect
  --version-id <id>
  --from export.zip
```

---

## Editor UI

The editor is a 3-panel dark-themed web app running entirely in the browser. Open `homepage/editor/index.html` directly (no server required).

```
┌─────────────────┬──────────────────────────┬──────────────────────┐
│  Localizations  │                          │  Inspector           │
│                 │       Canvas             │                      │
│  [en-US] ●      │   (1290 × 2796)          │  Canvas Size         │
│  [ja]           │                          │  [APP_IPHONE_67 ▼]  │
│  [zh-Hans]      │   ┌──────────────────┐   │                      │
│  [+ Add]        │   │  Device bezel    │   │  Device Frame        │
│                 │   │  with screenshot │   │  [iPhone 16 Pro ▼]  │
│  Screenshots    │   │  inside          │   │                      │
│                 │   │                  │   │  Screenshot Image    │
│  [#1] ●         │   │  Drag text here  │   │  [Upload Image]     │
│  [#2]           │   └──────────────────┘   │                      │
│  [+ Add]        │                          │  Background          │
│                 │   Zoom: ──●── 40%        │  Solid | Gradient    │
│                 │                          │  ████ ████ ████      │
│                 │   Drag canvas to move    │                      │
│                 │   bezel position         │  Text Layers [+]     │
│                 │                          │  "Track Everything"  │
│                 │                          │                      │
│                 │                          │  [Export ZIP]        │
└─────────────────┴──────────────────────────┴──────────────────────┘
```

**Interactions:**
- **Locale tabs** — switch between localizations; each has independent screenshots and device settings
- **Screenshot slots** — up to 10 per locale; click to select
- **Canvas drag** — click and drag the canvas to reposition the bezel + screenshot together
- **Text layers** — drag to reposition; edit content, size, color, weight, alignment in the inspector
- **Zoom slider** — visual zoom only; export always uses full output resolution
- **Export ZIP** — generates `export.zip` with `manifest.json` + locale PNG folders

---

## Export ZIP Format

```
export.zip
├── manifest.json
├── en-US/
│   ├── 1.png
│   └── 2.png
├── ja/
│   └── 1.png
└── zh-Hans/
    └── 1.png
```

### `manifest.json`

```json
{
  "version": "1.0",
  "exportedAt": "2026-02-23T10:00:00Z",
  "localizations": {
    "en-US": {
      "displayType": "APP_IPHONE_67",
      "screenshots": [
        {
          "order": 1,
          "file": "en-US/1.png",
          "device": "iPhone 16 Pro - Natural Titanium - Portrait",
          "background": { "type": "gradient", "colors": ["#1a1a2e", "#0f3460"], "angle": 135 },
          "texts": [
            {
              "content": "Track Everything",
              "x": 50, "y": 15,
              "fontSize": 52, "fontWeight": "bold",
              "color": "#ffffff", "align": "center"
            }
          ]
        }
      ]
    }
  }
}
```

The `file` path is relative to the ZIP root. `device`, `background`, and `texts` are editor metadata retained for re-editing — `asc screenshots import` only reads `displayType` and `file`.

---

## Import

```bash
asc screenshots import --version-id <VERSION_ID> --from <PATH_TO_ZIP>
```

Reads `export.zip` and uploads all screenshots to App Store Connect. For each locale in the manifest, it finds or creates the localization and screenshot set, then uploads each PNG in `order` sequence.

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--version-id` | *(required)* | App Store version ID to import into |
| `--from` | *(required)* | Path to `export.zip` |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc screenshots import \
  --version-id abc123 \
  --from ./export.zip \
  --output table
```

**Table output:**

```
ID        File Name   Size     State
--------  ----------  -------  --------
img-001   1.png       2.8 MB   Complete
img-002   2.png       2.4 MB   Complete
img-003   1.png       3.1 MB   Complete
```

---

## Typical Workflow

```bash
# 1. Find your app and version
asc apps list --output table
asc versions list --app-id <APP_ID> --output table

# 2. Design screenshots in the visual editor
open homepage/editor/index.html
#    → compose screenshots for en-US, ja, zh-Hans
#    → click Export ZIP → saves export.zip

# 3. Upload to App Store Connect
asc screenshots import --version-id <VERSION_ID> --from ./export.zip

# 4. Verify
asc screenshot-sets list --localization-id <LOC_ID> --output table
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                   Screenshot Editor Feature                           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Browser (homepage/editor/)         CLI (ASCCommand)                  │
│  ┌──────────────────────────────┐   ┌──────────────────────────────┐  │
│  │  index.html                 │   │  ScreenshotsImport            │  │
│  │  js/app.js       state      │   │  (AsyncParsableCommand)      │  │
│  │  js/compositor.js  Canvas2D │   │  → /usr/bin/unzip            │  │
│  │  js/texts.js    drag layers │   │  → JSONDecoder → Manifest    │  │
│  │  js/export.js   JSZip ZIP   │   │  → ScreenshotRepository      │  │
│  │  js/devices.js  async load  │   └──────────────────────────────┘  │
│  │  frames/devices.json        │                                      │
│  └──────────────────────────────┘   Domain                            │
│           ↓ export.zip              ┌──────────────────────────────┐  │
│                                     │  ScreenshotManifest          │  │
│  ASC API                            │  ├ LocalizationManifest      │  │
│  ┌──────────────────────────────┐   │  └ ScreenshotEntry            │  │
│  │  listLocalizations           │   │                              │  │
│  │  createLocalization          │   │  ScreenshotRepository        │  │
│  │  listScreenshotSets          │◀──│  + importScreenshots(...)    │  │
│  │  createScreenshotSet         │   └──────────────────────────────┘  │
│  │  uploadScreenshot (3-step)   │                                      │
│  └──────────────────────────────┘                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`

---

## Domain Models

### `ScreenshotManifest`

The parsed representation of `manifest.json`. Used by `ScreenshotsImport` to drive the upload loop.

```swift
public struct ScreenshotManifest: Codable, Sendable {
    public let version: String
    public let exportedAt: String?
    public let localizations: [String: LocalizationManifest]   // keyed by locale (e.g. "en-US")

    public struct LocalizationManifest: Codable, Sendable {
        public let displayType: ScreenshotDisplayType
        public let screenshots: [ScreenshotEntry]
    }

    public struct ScreenshotEntry: Codable, Sendable {
        public let order: Int
        public let file: String   // relative path inside ZIP, e.g. "en-US/1.png"
    }
}
```

### Updated `ScreenshotRepository`

`importScreenshots` was added to the existing `@Mockable` protocol:

```swift
@Mockable
public protocol ScreenshotRepository: Sendable {
    // ... existing methods ...
    func importScreenshots(
        versionId: String,
        manifest: ScreenshotManifest,
        zipDirectory: URL
    ) async throws -> [AppScreenshot]
}
```

The implementation in `OpenAPIScreenshotRepository` orchestrates the full import loop:
1. For each locale: `listLocalizations` → find existing or `createLocalization`
2. For each display type: `listScreenshotSets` → find existing or `createScreenshotSet`
3. For each entry (sorted by `order`): `uploadScreenshot(setId:fileURL:)`

---

## Web Editor — `frames/devices.json`

Single source of truth replacing the old `Frames.json` + `Sizes.json` pair. Flat structure keyed by PNG filename (without `.png`).

```json
{
  "iPhone 16 Pro - Natural Titanium - Portrait": {
    "category":     "iPhone",
    "displayType":  "APP_IPHONE_67",
    "outputWidth":  1320,
    "outputHeight": 2868,
    "screenInsetX": 80,
    "screenInsetY": 80
  }
}
```

| Field | Purpose |
|-------|---------|
| `category` | Dropdown group: `iPhone`, `iPad`, `Mac`, `Watch` |
| `displayType` | App Store Connect slot for upload (matches `ScreenshotDisplayType` enum) |
| `outputWidth/Height` | Native screenshot resolution of this device |
| `screenInsetX/Y` | Pixels from the frame PNG edge to the screen content area (horizontal / vertical) — used by the flood-fill compositor |

`devices.js` fetches this at startup and populates `DEVICES_MAP` and `DEVICES_LIST`. `DISPLAY_TYPE_SIZES` is a separate hardcoded table of canonical App Store slot dimensions, independent of individual device resolutions.

---

## Web Editor — JS Modules

| Module | Responsibility |
|--------|---------------|
| `app.js` | State machine: locale/screenshot selection, inspector wiring, bezel drag, init |
| `compositor.js` | Canvas 2D compositing: background → masked screenshot → bezel overlay; flood-fill mask cache; frame image cache |
| `texts.js` | Draggable text layer overlays positioned in the pre-transform coordinate space |
| `export.js` | ZIP generation via JSZip: iterates state, calls `exportScreenshotToPNG` per slot, writes `manifest.json` |
| `devices.js` | Async loader for `devices.json`; exposes `DEVICES_MAP`, `DISPLAY_TYPE_SIZES`, `populateDeviceDropdown` |

**Compositor caching** — the flood-fill mask (expensive pixel scan) and frame PNG are cached per device name after the first composite. Subsequent re-renders during drag use fast canvas draw operations only.

**Text layer positioning** — overlay `div`s are positioned in the wrapper's full canvas coordinate space (`0..outputWidth`, `0..outputHeight`). The CSS `transform: scale(zoom%)` on the wrapper handles visual scaling, so positions are never multiplied by the zoom factor.

---

## File Map

```
homepage/editor/                          Web editor source
├── index.html                            App shell (3-panel layout)
├── styles/editor.css                     Dark theme
├── js/
│   ├── app.js                            State machine + event wiring
│   ├── compositor.js                     Canvas 2D compositing + caches
│   ├── texts.js                          Draggable text layers
│   ├── export.js                         ZIP export
│   ├── devices.js                        Async device registry loader
│   └── vendor/jszip.min.js               JSZip 3.10.1 (self-hosted)
└── frames/
    ├── devices.json                      Merged device metadata (replaces Frames.json + Sizes.json)
    └── *.png                             121 device bezels

Sources/
├── Domain/Screenshots/
│   ├── ScreenshotImport.swift            ScreenshotManifest + nested types
│   └── ScreenshotRepository.swift        Modified: added importScreenshots
│
├── Infrastructure/Screenshots/
│   └── OpenAPIScreenshotRepository.swift Modified: implements importScreenshots
│
└── ASCCommand/Commands/Screenshots/
    ├── ScreenshotsCommand.swift          Modified: added import subcommand
    └── ScreenshotsImport.swift           Unzip → parse manifest → upload loop
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/ASCCommand/Commands/Screenshots/ScreenshotsCommand.swift` | Added `ScreenshotsImport.self` to `subcommands` |

---

## App Store Connect API Reference

Import reuses the existing screenshot repository methods — no new endpoints:

| Method | Endpoint | Notes |
|--------|----------|-------|
| `listLocalizations` | `GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations` | Find existing locale |
| `createLocalization` | `POST /v1/appStoreVersionLocalizations` | Create if not found |
| `listScreenshotSets` | `GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets` | Find existing set for display type |
| `createScreenshotSet` | `POST /v1/appScreenshotSets` | Create if not found |
| `uploadScreenshot` | POST + S3 + PATCH (3-step) | Reserve → binary upload → commit |

---

## Testing

Tests follow the **Chicago school TDD** pattern: assert on state and return values, not on interactions.

```swift
@Test func `manifest decodes localization entries`() throws {
    let json = """
    {
      "version": "1.0",
      "localizations": {
        "en-US": {
          "displayType": "APP_IPHONE_67",
          "screenshots": [{ "order": 1, "file": "en-US/1.png" }]
        }
      }
    }
    """
    let manifest = try JSONDecoder().decode(ScreenshotManifest.self, from: Data(json.utf8))
    #expect(manifest.localizations["en-US"]?.displayType == .iphone67)
    #expect(manifest.localizations["en-US"]?.screenshots.first?.order == 1)
}
```

---

## Extending the Feature

### Adding re-edit support (round-trip)

The manifest already preserves `device`, `background`, and `texts` per screenshot. To support re-opening a ZIP in the editor, add an "Open ZIP" button that fetches `manifest.json`, decodes it, and restores the state object.

### Adding screenshot reorder

Upload order is set by sorting entries on `order` before calling `uploadScreenshot`. To explicitly set display order after upload:

```swift
// PATCH /v1/appScreenshotSets/{id}/relationships/appScreenshots
func reorderScreenshots(setId: String, orderedIds: [String]) async throws
```

### Adding new device frames

1. Add the PNG to `homepage/editor/frames/`
2. Add one entry to `frames/devices.json` with the five fields
3. Run `swift build`

No code changes required — `devices.js` loads the JSON at runtime.
