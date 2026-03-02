# asc init — Project Context Initialisation

Saves the current project's app ID, name, and bundle ID to `.asc/project.json` in the working directory. Agents and automation scripts can read this file to discover the app context without calling `asc apps list` on every session.

---

## CLI Usage

### `asc init`

Initialise project context. Priority: `--app-id` > `--name` > auto-detect from `.xcodeproj`.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | One of three | App Store Connect app ID (direct, no API list call) |
| `--name` | One of three | App name to search for (case-insensitive) |
| _(none)_ | One of three | Auto-detect from `PRODUCT_BUNDLE_IDENTIFIER` in `.xcodeproj/project.pbxproj` |
| `--output` | No | Output format: `json` (default), `table`, `markdown` |
| `--pretty` | No | Pretty-print JSON output |

**Examples:**

```bash
# Direct — no API list call needed
asc init --app-id 1234567890 --pretty

# By name — fetches all apps and matches case-insensitively
asc init --name "My App" --pretty

# Auto-detect — scans *.xcodeproj in the current directory
asc init --pretty
```

**Output (JSON):**

```json
{
  "data": [
    {
      "affordances": {
        "checkReadiness": "asc versions check-readiness --version-id <id>",
        "listAppInfos":   "asc app-infos list --app-id 1234567890",
        "listBuilds":     "asc builds list --app-id 1234567890",
        "listVersions":   "asc versions list --app-id 1234567890"
      },
      "appId":    "1234567890",
      "appName":  "My App",
      "bundleId": "com.example.myapp"
    }
  ]
}
```

**Table output:**

```
App ID      Name    Bundle ID
----------  ------  -----------------
1234567890  My App  com.example.myapp
```

---

## Saved File

`./.asc/project.json` (relative to cwd):

```json
{
  "appId":    "1234567890",
  "appName":  "My App",
  "bundleId": "com.example.myapp"
}
```

---

## Typical Workflow

```bash
# First-time setup (run once per project)
cd /path/to/MyApp
asc init --pretty
# → saves .asc/project.json

# In subsequent sessions — read context without listing all apps
APP_ID=$(jq -r '.appId' .asc/project.json)
asc versions list --app-id "$APP_ID"
asc builds list   --app-id "$APP_ID"
asc app-infos list --app-id "$APP_ID"
```

An agent can read `.asc/project.json` at the start of every session and skip the `asc apps list` discovery step entirely.

---

## Architecture

```
ASCCommand/Commands/Init/
└── InitCommand.swift          [asc init — 3 detection modes + XcodeProjectScanner]
         ↓
Infrastructure/Projects/
└── FileProjectConfigStorage.swift  [saves/loads .asc/project.json via JSONEncoder]
         ↓
Domain/Projects/
├── ProjectConfig.swift        [struct: appId, appName, bundleId + AffordanceProviding]
└── ProjectConfigStorage.swift [@Mockable protocol: save/load/delete]
```

**Dependency note:** `InitCommand` depends on `AppRepository` (Domain) for app lookup and `ProjectConfigStorage` (Domain) for persistence. No new Infrastructure repository is needed — `FileProjectConfigStorage` is a plain struct with no SDK dependency.

---

## Domain Models

### `ProjectConfig`

```swift
public struct ProjectConfig: Sendable, Equatable, Codable, AffordanceProviding {
    public let appId: String
    public let appName: String
    public let bundleId: String
}
```

**Affordances:**

| Key | Command |
|-----|---------|
| `listVersions` | `asc versions list --app-id <appId>` |
| `listBuilds` | `asc builds list --app-id <appId>` |
| `listAppInfos` | `asc app-infos list --app-id <appId>` |
| `checkReadiness` | `asc versions check-readiness --version-id <id>` |

Uses synthesised `Codable` (all fields non-optional). JSON encoding omits no fields.

### `ProjectConfigStorage` (protocol)

```swift
@Mockable
public protocol ProjectConfigStorage: Sendable {
    func save(_ config: ProjectConfig) throws
    func load() throws -> ProjectConfig?
    func delete() throws
}
```

### `XcodeProjectScanner` (private)

Private enum inside `InitCommand.swift`. Scans `.xcodeproj/project.pbxproj` files in the current directory and extracts literal `PRODUCT_BUNDLE_IDENTIFIER` values (excludes `$`-variable references).

---

## File Map

**Sources:**

```
Sources/
├── Domain/Projects/
│   ├── ProjectConfig.swift         [new — domain model + AffordanceProviding]
│   └── ProjectConfigStorage.swift  [new — @Mockable save/load/delete protocol]
├── Infrastructure/Projects/
│   └── FileProjectConfigStorage.swift  [new — reads/writes .asc/project.json]
└── ASCCommand/
    ├── ASC.swift                   [modified — registered InitCommand.self]
    └── Commands/Init/
        └── InitCommand.swift       [new — asc init with 3 modes + XcodeProjectScanner]
```

**Wiring:**

| File | Role |
|------|------|
| `InitCommand.swift` | Command entry point; calls `ClientProvider.makeAppRepository()` + `FileProjectConfigStorage()` |
| `ClientProvider.swift` | No change needed — `makeAppRepository()` already exists |

**Tests:**

```
Tests/
├── InfrastructureTests/Projects/
│   └── FileProjectConfigStorageTests.swift  [new — 5 round-trip tests]
└── ASCCommandTests/Commands/Init/
    └── InitCommandTests.swift               [new — 6 tests: 3 modes + error cases]
```

---

## API Reference

`--app-id` mode makes one extra API call; `--name` and auto-detect each list all apps first:

| Mode | API calls |
|------|-----------|
| `--app-id` | `GET /v1/apps/{id}` → 1 call |
| `--name` | `GET /v1/apps` → 1 call, then local match |
| auto-detect | `GET /v1/apps` → 1 call, then local bundle ID match |

No writes to App Store Connect. All persistence is local file I/O.

---

## Testing

```swift
@Test func `app-id resolves app by ID and saves config`() async throws {
    let mockRepo = MockAppRepository()
    let mockStorage = MockProjectConfigStorage()
    given(mockRepo).getApp(id: .any).willReturn(
        App(id: "app-123", name: "My App", bundleId: "com.example.app")
    )
    given(mockStorage).save(.any).willReturn()

    var cmd = try InitCommand.parse(["--app-id", "app-123", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

    #expect(output.contains("app-123"))
    #expect(output.contains("com.example.app"))
}
```

Run tests:

```bash
swift test --filter 'FileProjectConfigStorage'
swift test --filter 'InitCommand'
```

---

## Extending

**Read project context in other commands** — any command can optionally load `.asc/project.json` to infer `--app-id` if not provided:

```swift
if appId == nil {
    let storage = FileProjectConfigStorage()
    if let config = try? storage.load() {
        appId = config.appId
    }
}
```

**Store active version ID** — extend `ProjectConfig` with an optional `activeVersionId` that `asc versions create` or `asc versions list` can update automatically:

```swift
public struct ProjectConfig: ... {
    public let appId: String
    public let appName: String
    public let bundleId: String
    public let activeVersionId: String?   // ← future
}
```
