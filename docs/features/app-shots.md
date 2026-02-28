# App Shots

AI-powered App Store screenshot planning and generation using the `asc app-shots` command. Uses Gemini AI (via the OpenAI-compatible API) to enhance screenshot plans with compelling copy and image prompts.

---

## CLI Usage

### `asc app-shots generate`

Enhance a screenshot plan JSON file with Gemini AI. Reads a plan file, optionally includes screenshot images for visual context, and returns an enhanced plan with improved headings, subheadings, and image prompts.

| Flag | Required | Description |
|------|----------|-------------|
| `--plan` | Yes | Path to the plan JSON file |
| `--gemini-api-key` | No | Gemini API key (falls back to `GEMINI_API_KEY` env var) |
| `--model` | No | Gemini model to use (default: `gemini-2.0-flash-exp`) |
| `--output-file` | No | Write enhanced plan JSON to this file in addition to stdout |
| `--output` | No | Output format: `json` (default), `table`, `markdown` |
| `--pretty` | No | Pretty-print JSON output |
| `<screenshots>` | No | Screenshot files as positional arguments (must match plan order) |

```bash
# Basic usage with env var
export GEMINI_API_KEY="your-key"
asc app-shots generate --plan app-shots-plan.json --pretty

# With explicit API key and screenshots
asc app-shots generate \
  --plan app-shots-plan.json \
  --gemini-api-key YOUR_KEY \
  screen1.png screen2.png screen3.png

# Write enhanced plan to file
asc app-shots generate \
  --plan app-shots-plan.json \
  --output-file enhanced-plan.json
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "generate": "asc app-shots generate --plan app-shots-plan.json --gemini-api-key $GEMINI_API_KEY"
      },
      "appId": "6736834466",
      "appName": "MyApp",
      "tagline": "Your productivity companion",
      "tone": "professional",
      "colors": {
        "primary": "#1A1A2E",
        "accent": "#E94560",
        "text": "#FFFFFF",
        "subtext": "#CCCCCC"
      },
      "screens": [
        {
          "id": "0",
          "index": 0,
          "screenshotFile": "screen1.png",
          "heading": "Work Smarter, Not Harder",
          "subheading": "Organize tasks in seconds",
          "layoutMode": "center",
          "visualDirection": "Main dashboard with task overview",
          "imagePrompt": "Clean dark UI with colorful task cards and progress indicators"
        }
      ]
    }
  ]
}
```

**Table output:**

| App | Screens | Tone |
|-----|---------|------|
| MyApp | 3 | professional |

---

## Plan JSON Schema

The `ScreenPlan` JSON file has this structure:

```json
{
  "appId": "6736834466",
  "appName": "MyApp",
  "tagline": "Your productivity companion",
  "tone": "professional",
  "colors": {
    "primary": "#1A1A2E",
    "accent": "#E94560",
    "text": "#FFFFFF",
    "subtext": "#CCCCCC"
  },
  "screens": [
    {
      "id": "0",
      "index": 0,
      "screenshotFile": "screen1.png",
      "heading": "Work Smarter",
      "subheading": "Organize tasks in seconds",
      "layoutMode": "center",
      "visualDirection": "Main dashboard",
      "imagePrompt": "Beautiful UI"
    }
  ]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `appId` | String | App Store Connect app ID |
| `appName` | String | Display name of the app |
| `tagline` | String | Marketing tagline |
| `tone` | String | Visual tone: `minimal`, `playful`, `professional`, `bold`, `elegant` |
| `colors.primary` | String | Primary background color (hex) |
| `colors.accent` | String | Accent/highlight color (hex) |
| `colors.text` | String | Main text color (hex) |
| `colors.subtext` | String | Secondary text color (hex) |

### Screen Config Fields

| Field | Type | Description |
|-------|------|-------------|
| `index` | Int | Screen order (0-based) |
| `screenshotFile` | String | Filename of the source screenshot |
| `heading` | String | Main headline text |
| `subheading` | String | Supporting text below heading |
| `layoutMode` | String | Layout: `center`, `left`, `tilted` |
| `visualDirection` | String | Description of what the screen shows |
| `imagePrompt` | String | AI prompt for background/decoration generation |

---

## Typical Workflow

```bash
# 1. Create a plan JSON file (manually or via asc-app-shots skill)
cat > app-shots-plan.json << 'EOF'
{
  "appId": "6736834466",
  "appName": "MyApp",
  "tagline": "Your productivity companion",
  "tone": "professional",
  "colors": {
    "primary": "#1A1A2E",
    "accent": "#E94560",
    "text": "#FFFFFF",
    "subtext": "#CCCCCC"
  },
  "screens": [
    {
      "id": "0",
      "index": 0,
      "screenshotFile": "screen1.png",
      "heading": "Work Smarter",
      "subheading": "Organize tasks",
      "layoutMode": "center",
      "visualDirection": "Main dashboard",
      "imagePrompt": "Clean UI"
    }
  ]
}
EOF

# 2. Enhance the plan with Gemini AI
asc app-shots generate \
  --plan app-shots-plan.json \
  --output-file enhanced-plan.json \
  --pretty \
  screen1.png

# 3. Review the enhanced plan
cat enhanced-plan.json
```

---

## Architecture

```
ASCCommand                    Infrastructure                  Domain
+-----------------------+     +-----------------------------+  +------------------------+
| AppShotsCommand       |     | GeminiScreenshotGeneration  |  | ScreenPlan             |
|   AppShotsGenerate    |---->|   Repository                |  | ScreenConfig           |
|     --plan            |     |   (URLSession, Gemini API)  |  | ScreenTone             |
|     --gemini-api-key  |     +-----------------------------+  | LayoutMode             |
|     --model           |                                      | ScreenColors           |
+-----------------------+                                      | ScreenshotGeneration   |
                                                               |   Repository (protocol)|
                                                               +------------------------+
```

- **Domain**: Pure value types (`ScreenPlan`, `ScreenConfig`, `ScreenTone`, `LayoutMode`, `ScreenColors`) and `@Mockable` repository protocol
- **Infrastructure**: `GeminiScreenshotGenerationRepository` uses `URLSession` (not the ASC SDK) to call the Gemini OpenAI-compatible API
- **ASCCommand**: `AppShotsGenerate` command loads the plan file, validates screenshot paths, calls the repository, and formats output

---

## Domain Models

### `ScreenPlan`

Main plan model. Implements `AffordanceProviding`.

| Field | Type | Description |
|-------|------|-------------|
| `appId` | `String` | App ID (also serves as the model's `id`) |
| `appName` | `String` | App display name |
| `tagline` | `String` | Marketing tagline |
| `tone` | `ScreenTone` | Visual tone enum |
| `colors` | `ScreenColors` | Color palette |
| `screens` | `[ScreenConfig]` | Ordered list of screen configurations |

**Affordances:**
| Key | Command |
|-----|---------|
| `generate` | `asc app-shots generate --plan app-shots-plan.json --gemini-api-key $GEMINI_API_KEY` |

### `ScreenTone`

| Case | Raw Value |
|------|-----------|
| `.minimal` | `"minimal"` |
| `.playful` | `"playful"` |
| `.professional` | `"professional"` |
| `.bold` | `"bold"` |
| `.elegant` | `"elegant"` |

### `LayoutMode`

| Case | Raw Value |
|------|-----------|
| `.center` | `"center"` |
| `.left` | `"left"` |
| `.tilted` | `"tilted"` |

### `ScreenColors`

| Field | Type |
|-------|------|
| `primary` | `String` |
| `accent` | `String` |
| `text` | `String` |
| `subtext` | `String` |

### `ScreenConfig`

| Field | Type |
|-------|------|
| `id` | `String` (computed: `"\(index)"`) |
| `index` | `Int` |
| `screenshotFile` | `String` |
| `heading` | `String` |
| `subheading` | `String` |
| `layoutMode` | `LayoutMode` |
| `visualDirection` | `String` |
| `imagePrompt` | `String` |

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
│   └── ScreenshotGenerationRepository.swift
├── Infrastructure/ScreenshotPlans/
│   └── GeminiScreenshotGenerationRepository.swift
└── ASCCommand/Commands/AppShots/
    ├── AppShotsCommand.swift
    └── AppShotsGenerate.swift
```

### Tests

```
Tests/
├── DomainTests/ScreenshotPlans/
│   └── ScreenPlanTests.swift
├── InfrastructureTests/ScreenshotPlans/
│   └── GeminiScreenshotGenerationRepositoryTests.swift
└── ASCCommandTests/Commands/AppShots/
    └── AppShotsGenerateTests.swift
```

### Wiring

| File | Role |
|------|------|
| `ASC.swift` | Registers `AppShotsCommand` as subcommand |
| `ClientProvider.swift` | `makeScreenshotGenerationRepository(apiKey:model:)` factory |

---

## API Reference

| Operation | API Call | Repository Method |
|-----------|----------|-------------------|
| Enhance plan | `POST /chat/completions` (Gemini OpenAI-compatible) | `generatePlan(plan:screenshotURLs:)` |

The `GeminiScreenshotGenerationRepository`:
1. Encodes the `ScreenPlan` as JSON in the user message
2. Optionally includes base64-encoded screenshot images
3. Sends to `{baseURL}/chat/completions` with `response_format: json_object`
4. Parses the response content as a `ScreenPlan`
5. Re-injects the original `appId` if Gemini omits it

---

## Testing

```swift
@Test func `generate outputs plan JSON with affordances`() async throws {
    let plan = makePlan(appId: "6736834466", appName: "MyApp")
    let planPath = try writePlanFile(plan)

    let mockRepo = MockScreenshotGenerationRepository()
    given(mockRepo).generatePlan(plan: .any, screenshotURLs: .any)
        .willReturn(plan)

    let cmd = try AppShotsGenerate.parse(["--plan", planPath, "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output.contains("6736834466"))
    #expect(output.contains("affordances"))
}
```

Run tests:

```bash
swift test --filter 'ScreenPlanTests'                              # Domain tests (6)
swift test --filter 'GeminiScreenshotGenerationRepositoryTests'    # Infrastructure tests (8)
swift test --filter 'AppShotsGenerateTests'                        # Command tests (6)
```
