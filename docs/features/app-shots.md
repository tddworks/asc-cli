# App Shots

AI-powered App Store screenshot generation and localization. The `asc app-shots` command uses Gemini AI to produce polished marketing PNG images from your raw app screenshots and a `ScreenPlan` JSON file, and can translate them into any locale in one step.

Three-step workflow:
1. **`asc-app-shots` skill** — Claude fetches App Store metadata, analyzes screenshots with vision, and writes `.asc/app-shots/app-shots-plan.json`
2. **`asc app-shots generate`** — reads the plan + screenshots, calls Gemini image generation API in parallel, writes `screen-{index}.png` to `.asc/app-shots/output/`
3. **`asc app-shots translate`** *(optional)* — reads the English plan + generated screenshots, recreates them with translated text for each `--to` locale

---

## CLI Usage

### `asc app-shots generate`

Generate marketing PNG images using Gemini AI. Reads a `ScreenPlan` JSON file, discovers or accepts screenshot files, and outputs one PNG per screen.

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Path to the ScreenPlan JSON file |
| `--gemini-api-key` | — | Gemini API key (falls back to `GEMINI_API_KEY` env var, then stored config) |
| `--model` | `gemini-3.1-flash-image-preview` | Gemini image generation model |
| `--output-dir` | `.asc/app-shots/output` | Directory to write generated PNG files |
| `--output-width` | `1320` | Output PNG width in pixels — see [Device Sizes](#device-sizes) |
| `--output-height` | `2868` | Output PNG height in pixels — see [Device Sizes](#device-sizes) |
| `--device-type` | — | Named device type (e.g. `APP_IPHONE_69`) — overrides `--output-width`/`--output-height` |
| `--style-reference` | — | Path to a reference image whose visual style (colors, typography, layout) Gemini should replicate. Content is not copied — only the aesthetic. |
| `<screenshots>` | *(auto-discovered)* | Screenshot files; omit to auto-discover `*.png/*.jpg` from plan directory |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON output |

```bash
# Zero-argument happy path — iPhone 6.9" (APP_IPHONE_69) at 1320×2868 by default
asc app-shots generate

# Match the visual style of a reference screenshot
asc app-shots generate --style-reference ~/Downloads/competitor-shot.png

# Named device type — no need to remember pixel dimensions
asc app-shots generate --device-type APP_IPHONE_67   # 1290×2796
asc app-shots generate --device-type APP_IPHONE_65   # 1242×2688
asc app-shots generate --device-type APP_IPHONE_55   # 1242×2208
asc app-shots generate --device-type APP_IPAD_PRO_129  # 2048×2732

# Style reference + device type combined
asc app-shots generate \
  --style-reference ~/Downloads/competitor-shot.png \
  --device-type APP_IPHONE_69

# Explicit dimensions (alternative to --device-type)
asc app-shots generate --output-width 1290 --output-height 2796

# Explicit plan + screenshots
asc app-shots generate \
  --plan .asc/app-shots/app-shots-plan.json \
  --output-dir .asc/app-shots/output \
  .asc/app-shots/screen1.png .asc/app-shots/screen2.png

# Different model
asc app-shots generate --model gemini-2.0-flash-exp
```

**JSON output:**
```json
{
  "generated": [
    {"screenIndex": 0, "file": ".asc/app-shots/output/screen-0.png"},
    {"screenIndex": 1, "file": ".asc/app-shots/output/screen-1.png"}
  ]
}
```

**Table output:**

| Screen | File |
|--------|------|
| 0 | .asc/app-shots/output/screen-0.png |
| 1 | .asc/app-shots/output/screen-1.png |

---

### `asc app-shots translate`

Translate already-generated screenshots into one or more locales. The command modifies each screen's `imagePrompt` to include translation instructions, then calls the same Gemini generation pipeline. The existing `screen-{n}.png` files are sent as visual reference so Gemini keeps layout, colors, and device mockup identical — only text changes.

| Flag | Default | Description |
|------|---------|-------------|
| `--plan` | `.asc/app-shots/app-shots-plan.json` | Source ScreenPlan JSON |
| `--from` | `en` | Source locale label (informational) |
| `--to` | *(required, repeatable)* | Target locale(s): `--to zh --to ja --to ko` |
| `--source-dir` | `.asc/app-shots/output` | Directory containing existing `screen-*.png` files |
| `--output-dir` | `.asc/app-shots/output` | Base output directory; locale subdirs are created automatically |
| `--output-width` | `1320` | Output PNG width in pixels — see [Device Sizes](#device-sizes) |
| `--output-height` | `2868` | Output PNG height in pixels — see [Device Sizes](#device-sizes) |
| `--device-type` | — | Named device type (e.g. `APP_IPHONE_69`) — overrides `--output-width`/`--output-height` |
| `--style-reference` | — | Path to a reference image whose visual style Gemini should replicate (same aesthetic as in `generate`) |
| `--gemini-api-key` | — | Gemini API key (same 3-level resolution as `generate`) |
| `--model` | `gemini-3.1-flash-image-preview` | Gemini image generation model |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |

```bash
# Translate to Chinese and Japanese in one command
asc app-shots translate --to zh --to ja

# Keep the same visual style as the original reference during translation
asc app-shots translate --to zh --to ja --style-reference ~/Downloads/competitor-shot.png

# Explicit paths
asc app-shots translate \
  --plan .asc/app-shots/app-shots-plan.json \
  --source-dir .asc/app-shots/output \
  --output-dir .asc/app-shots/output \
  --to zh --to ja --to ko
```

**JSON output:**
```json
{"data": [
  {"locale": "ja", "screens": 2, "outputDir": ".asc/app-shots/output/ja", "affordances": {}},
  {"locale": "zh", "screens": 2, "outputDir": ".asc/app-shots/output/zh", "affordances": {}}
]}
```

**Table output:**

| Locale | Screens | Output Dir |
|--------|---------|------------|
| ja | 2 | .asc/app-shots/output/ja |
| zh | 2 | .asc/app-shots/output/zh |

---

### `asc app-shots config`

Manage the Gemini API key. Saves to `~/.asc/app-shots-config.json` so you never need to pass `--gemini-api-key` again.

| Flag | Description |
|------|-------------|
| `--gemini-api-key KEY` | Save key to `~/.asc/app-shots-config.json` |
| `--remove` | Delete stored config |
| *(none)* | Show current key (masked) and source (`file` or `environment`) |

```bash
# Save key once
asc app-shots config --gemini-api-key AIzaSy...

# Check current config
asc app-shots config
# → Gemini API key: AIzaSyBU...IpV4 (source: file)

# Remove stored key
asc app-shots config --remove
```

**Key resolution order in `generate`:**
1. `--gemini-api-key` flag
2. `$GEMINI_API_KEY` environment variable
3. `~/.asc/app-shots-config.json` (set via `asc app-shots config`)
4. Error with instructions

---

## Device Sizes

`--output-width` and `--output-height` control the final PNG dimensions. Gemini returns images at ~704×1520; the CLI upscales to the target size using CoreGraphics before writing.

**Required sizes** must be present for App Store submission. Optional sizes cover older or additional devices.

### iPhone

| Display Type | Device | `--output-width` | `--output-height` | App Store |
|---|---|---|---|---|
| `APP_IPHONE_69` | iPhone 6.9" | `1320` | `2868` | ✅ Required |
| `APP_IPHONE_67` | iPhone 6.7" | `1290` | `2796` | ✅ Required |
| `APP_IPHONE_65` | iPhone 6.5" | `1242` | `2688` | Optional |
| `APP_IPHONE_61` | iPhone 6.1" | `1179` | `2556` | Optional |
| `APP_IPHONE_58` | iPhone 5.8" | `1125` | `2436` | Optional |
| `APP_IPHONE_55` | iPhone 5.5" | `1242` | `2208` | Optional |
| `APP_IPHONE_47` | iPhone 4.7" | `750` | `1334` | Optional |
| `APP_IPHONE_40` | iPhone 4.0" | `640` | `1136` | Optional |
| `APP_IPHONE_35` | iPhone 3.5" | `640` | `960` | Optional |

### iPad

| Display Type | Device | `--output-width` | `--output-height` | App Store |
|---|---|---|---|---|
| `APP_IPAD_PRO_129` | iPad 13" (12.9") | `2048` | `2732` | ✅ Required |
| `APP_IPAD_PRO_3GEN_11` | iPad 11" | `1668` | `2388` | Optional |
| `APP_IPAD_105` | iPad 10.5" | `1668` | `2224` | Optional |
| `APP_IPAD_97` | iPad 9.7" | `1536` | `2048` | Optional |

### Other Platforms

| Display Type | Device | `--output-width` | `--output-height` |
|---|---|---|---|
| `APP_APPLE_TV` | Apple TV | `1920` | `1080` |
| `APP_DESKTOP` | Mac | `2560` | `1600` |
| `APP_APPLE_VISION_PRO` | Apple Vision Pro | `3840` | `2160` |

> **Tip:** Generate each size in sequence — same plan, different `--output-dir`:
> ```bash
> asc app-shots generate --device-type APP_IPHONE_69  --output-dir .asc/app-shots/output/iphone-69
> asc app-shots generate --device-type APP_IPHONE_67  --output-dir .asc/app-shots/output/iphone-67
> asc app-shots generate --device-type APP_IPAD_PRO_129 --output-dir .asc/app-shots/output/ipad-13
> ```

---

## Typical Workflow

```bash
# 1. One-time: save Gemini API key
asc app-shots config --gemini-api-key AIzaSy...

# 2. Put your screenshots in the project's .asc/app-shots/ directory
cp ~/Screenshots/screen1.png .asc/app-shots/
cp ~/Screenshots/screen2.png .asc/app-shots/

# 3. Use the asc-app-shots skill in Claude Code to generate the plan:
#    "Plan my App Store screenshots for app 6736834466"
#    → Claude fetches metadata, analyzes screenshots, writes:
#       .asc/app-shots/app-shots-plan.json

# 4. Generate English marketing images — zero arguments needed
asc app-shots generate

# 4b. (Optional) Generate matching the style of a reference screenshot
asc app-shots generate --style-reference ~/Downloads/inspiration.png

# 5. Translate to Chinese and Japanese in one command
asc app-shots translate --to zh --to ja

# 5b. (Optional) Translate while preserving the same reference style
asc app-shots translate --to zh --to ja --style-reference ~/Downloads/inspiration.png

# 6. Find output images
ls .asc/app-shots/output/
# screen-0.png  screen-1.png  ja/  zh/
ls .asc/app-shots/output/zh/
# screen-0.png  screen-1.png
```

**Project directory layout:**
```
project/
└── .asc/
    └── app-shots/
        ├── screen1.png              ← source screenshots (input)
        ├── screen2.png
        ├── app-shots-plan.json      ← written by asc-app-shots skill
        └── output/
            ├── screen-0.png         ← English marketing images
            ├── screen-1.png
            ├── zh/
            │   ├── screen-0.png     ← Chinese translations
            │   └── screen-1.png
            └── ja/
                ├── screen-0.png     ← Japanese translations
                └── screen-1.png
```

---

## Architecture

```
ASCCommand                     Infrastructure                   Domain
+------------------------+     +-----------------------------+  +---------------------------+
| AppShotsCommand        |     | GeminiScreenshotGeneration  |  | ScreenPlan                |
|   AppShotsGenerate     |---->|   Repository                |  | ScreenConfig              |
|     --plan             |     |   POST generateContent      |  | ScreenTone                |
|     --output-dir       |     |   (native Gemini API)       |  | LayoutMode                |
|     auto-discover      |     +-----------------------------+  | ScreenColors              |
|                        |     | FileAppShotsConfigStorage   |  | AppShotsConfig            |
|   AppShotsTranslate    |---->|   ~/.asc/app-shots-         |  | AppShotsConfigStorage     |
|     --to (repeatable)  |     |   config.json               |  | ScreenshotGenerationRepo  |
|     --source-dir       |     +-----------------------------+  +---------------------------+
|     --output-dir       |
|                        |
|   AppShotsConfig       |
|     --gemini-api-key   |
|     --remove           |
+------------------------+
```

- **Domain**: Pure value types (`ScreenPlan`, `ScreenConfig`, `AppShotsConfig`) and `@Mockable` protocols (`ScreenshotGenerationRepository`, `AppShotsConfigStorage`)
- **Infrastructure**: `GeminiScreenshotGenerationRepository` calls the native Gemini `generateContent` API (`?key=` query param, `responseModalities: ["TEXT","IMAGE"]`, parallel `TaskGroup`). When a `styleReferenceURL` is provided, the reference image is placed as the **first** part in the request (base64 inline-data) followed by a style-guide instruction text — before the app screenshot and `imagePrompt`. `FileAppShotsConfigStorage` reads/writes JSON to `~/.asc/app-shots-config.json`
- **ASCCommand**: `AppShotsGenerate` auto-discovers screenshots from the plan directory when none are provided; validates `--style-reference` file existence before calling Gemini. `AppShotsTranslate` modifies each screen's `imagePrompt` with a translation instruction, forwards the same `styleReferenceURL`, and processes locales in parallel. `AppShotsConfig` mirrors the `asc auth login` pattern

---

## Domain Models

### `ScreenPlan`

Main plan model. Implements `AffordanceProviding`.

| Field | Type | Description |
|-------|------|-------------|
| `appId` | `String` | App ID (also serves as the model's `id`) |
| `appName` | `String` | App display name |
| `tagline` | `String` | Marketing tagline |
| `appDescription` | `String?` | 2-3 sentence summary for Gemini context (optional) |
| `tone` | `ScreenTone` | Visual tone enum |
| `colors` | `ScreenColors` | Color palette |
| `screens` | `[ScreenConfig]` | Ordered list of screen configurations |

**Affordances:**
| Key | Command |
|-----|---------|
| `generate` | `asc app-shots generate` |

### `ScreenConfig`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Computed: `"\(index)"` |
| `index` | `Int` | Screen order (0-based); index 0 = hero |
| `screenshotFile` | `String` | Source screenshot filename |
| `heading` | `String` | Main headline (3-5 words) |
| `subheading` | `String` | Supporting text (6-12 words) |
| `layoutMode` | `LayoutMode` | `center`, `left`, or `tilted` |
| `visualDirection` | `String` | Description of what the UI shows |
| `imagePrompt` | `String` | Full Gemini generation prompt |

### `ScreenTone`

| Case | Raw Value |
|------|-----------|
| `.minimal` | `"minimal"` |
| `.playful` | `"playful"` |
| `.professional` | `"professional"` |
| `.bold` | `"bold"` |
| `.elegant` | `"elegant"` |

### `LayoutMode`

| Case | Raw Value | Usage |
|------|-----------|-------|
| `.center` | `"center"` | Standard screens (index 1+) |
| `.left` | `"left"` | Text left, device right |
| `.tilted` | `"tilted"` | Hero screen (index 0) |

### `ScreenColors`

| Field | Type | Example |
|-------|------|---------|
| `primary` | `String` | `"#0A0F1E"` |
| `accent` | `String` | `"#4A90E2"` |
| `text` | `String` | `"#FFFFFF"` |
| `subtext` | `String` | `"#94B8D4"` |

### `AppShotsConfig`

| Field | Type | Description |
|-------|------|-------------|
| `geminiApiKey` | `String` | Stored Gemini API key |

### `ScreenshotGenerationRepository` (protocol)

```swift
@Mockable
public protocol ScreenshotGenerationRepository: Sendable {
    func generateImages(
        plan: ScreenPlan,
        screenshotURLs: [URL],
        styleReferenceURL: URL?
    ) async throws -> [Int: Data]
}
```

- `screenshotURLs` — matched by filename then index order against `plan.screens[n].screenshotFile`
- `styleReferenceURL` — optional path to a reference image; when provided, the repository prepends the image + a style-guide instruction to each Gemini request so the generated output replicates the reference's colors, typography, gradients, and layout patterns without copying its content

### `AppShotsConfigStorage` (protocol)

```swift
@Mockable
public protocol AppShotsConfigStorage: Sendable {
    func save(_ config: AppShotsConfig) throws
    func load() throws -> AppShotsConfig?
    func delete() throws
}
```

---

## File Map

### Sources

```
Sources/
├── Domain/ScreenshotPlans/
│   ├── ScreenTone.swift
│   ├── LayoutMode.swift
│   ├── ScreenColors.swift
│   ├── ScreenConfig.swift
│   ├── ScreenPlan.swift
│   ├── ScreenshotGenerationRepository.swift
│   ├── AppShotsConfig.swift
│   └── AppShotsConfigStorage.swift
├── Infrastructure/ScreenshotPlans/
│   ├── GeminiScreenshotGenerationRepository.swift
│   └── FileAppShotsConfigStorage.swift
└── ASCCommand/Commands/AppShots/
    ├── AppShotsCommand.swift
    ├── AppShotsGenerate.swift
    ├── AppShotsTranslate.swift
    └── AppShotsConfig.swift
```

### Tests

```
Tests/
├── DomainTests/ScreenshotPlans/
│   ├── ScreenPlanTests.swift
│   └── AppShotsConfigTests.swift
├── InfrastructureTests/ScreenshotPlans/
│   ├── GeminiScreenshotGenerationRepositoryTests.swift
│   └── FileAppShotsConfigStorageTests.swift
└── ASCCommandTests/Commands/AppShots/
    ├── AppShotsGenerateTests.swift
    ├── AppShotsTranslateTests.swift
    └── AppShotsConfigTests.swift
```

### Wiring

| File | Role |
|------|------|
| `ASC.swift` | Registers `AppShotsCommand` as subcommand |
| `ClientProvider.swift` | `makeScreenshotGenerationRepository(apiKey:model:)` |
| `ClientProvider.swift` | `makeAppShotsConfigStorage()` |

---

## API Reference

| Operation | Endpoint | Repository Method |
|-----------|----------|-------------------|
| Generate images | `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}` | `generateImages(plan:screenshotURLs:)` |
| Save config | `~/.asc/app-shots-config.json` (local file) | `save(_:)` |
| Load config | `~/.asc/app-shots-config.json` (local file) | `load()` |

The `GeminiScreenshotGenerationRepository`:
Per screen, the `GeminiScreenshotGenerationRepository`:
1. Prepends `App context: <appName>. <tagline>. <description>` to the `imagePrompt`
2. Builds `parts` in this order:
   - *(if `styleReferenceURL` is set)* base64 `inlineData` of the reference image + style-guide instruction text
   - *(if a matching screenshot is found)* base64 `inlineData` of the app screenshot
   - `text` containing the full `imagePrompt`
3. POSTs to the native `generateContent` endpoint with `responseModalities: ["TEXT","IMAGE"]`
4. Calls Gemini in parallel via `TaskGroup` — one task per screen
5. Parses `candidates[0].content.parts[].inlineData.data` as base64 PNG data
6. Returns `[Int: Data]` mapping screen index to PNG bytes

---

## Testing

```swift
// Style reference is forwarded as a URL to the repository
@Test func `--style-reference passes reference URL to repository`() async throws {
    let refFile = FileManager.default.temporaryDirectory
        .appendingPathComponent("ref-\(UUID().uuidString).png")
    try fakePNG.write(to: refFile)
    defer { try? FileManager.default.removeItem(at: refFile) }

    var capturedStyleRef: URL?
    let mockRepo = MockScreenshotGenerationRepository()
    given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any)
        .willProduce { _, _, styleRef in
            capturedStyleRef = styleRef
            return [0: fakePNG]
        }

    let cmd = try AppShotsGenerate.parse([
        "--plan", planPath, "--output-dir", outputDir,
        "--style-reference", refFile.path
    ])
    _ = try await cmd.execute(repo: mockRepo)

    #expect(capturedStyleRef == refFile)
}

// Infrastructure: style reference image appears before screenshot in Gemini request
@Test func `generateImages includes style reference image and instruction before screenshot`() async throws {
    let stub = StubHTTPClient()
    stub.response = (makeNativeGeminiImageResponse(), makeHTTPResponse())

    let refFile = /* temp PNG file */ URL(fileURLWithPath: "/tmp/style.png")
    try fakePNGData.write(to: refFile)

    let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
    _ = try await repo.generateImages(
        plan: makeSingleScreenPlan(), screenshotURLs: [], styleReferenceURL: refFile
    )

    let bodyString = String(data: stub.lastRequest!.httpBody!, encoding: .utf8)!
    #expect(bodyString.contains("STYLE GUIDE"))
    #expect(bodyString.contains("Do NOT copy its content"))
}
```

Run tests:

```bash
swift test --filter 'AppShotsConfigTests'     # Domain + command config tests (21)
swift test --filter 'AppShotsGenerateTests'   # Command generate tests (9)
swift test --filter 'AppShotsTranslateTests'  # Command translate tests (9)
swift test --filter 'GeminiScreenshot'        # Infrastructure tests (10)
swift test --filter 'AppShots'               # All app-shots tests (52)
```

---

## Extending

**Add `--locale` to fetch from a localized plan:**

```swift
// In AppShotsGenerate.swift
@Option(name: .long) var locale: String = "en-US"

// Load locale-specific plan
let planURL = URL(fileURLWithPath: ".asc/app-shots/plan-\(locale).json")
```

**Add multiple style references (pick best):**

```swift
// In ScreenshotGenerationRepository.swift
func generateImages(
    plan: ScreenPlan,
    screenshotURLs: [URL],
    styleReferenceURLs: [URL]   // send several references, ask Gemini to blend
) async throws -> [Int: Data]
```

**Add video output via Gemini video generation:**

```swift
// In ScreenshotGenerationRepository.swift
func generateVideo(
    plan: ScreenPlan,
    screenshotURLs: [URL],
    styleReferenceURL: URL?
) async throws -> Data
```
