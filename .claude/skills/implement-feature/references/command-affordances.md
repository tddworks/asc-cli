# Command Affordances Pattern

The CLI equivalent of REST HATEOAS. Every JSON response embeds ready-to-run CLI commands so agents navigate without memorising the command tree.

## Protocol

```swift
// Sources/Domain/Shared/AffordanceProviding.swift
public protocol AffordanceProviding {
    var affordances: [String: String] { get }
}
```

Every new domain model **must** conform to `AffordanceProviding`.

## Implementation Pattern

```swift
// Always-present commands + state-aware commands
extension AppStoreVersion: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listLocalizations": "asc localizations list --version-id \(id)",
            "listVersions":      "asc versions list --app-id \(appId)",
        ]
        if isEditable {
            cmds["submitForReview"] = "asc versions submit --version-id \(id)"
        }
        return cmds
    }
}
```

Rules:
- Navigation commands (list parent, list children) are **always present**
- Action commands (submit, delete) only appear **when the state allows** them

## Affordance Naming Convention

| Key | Command |
|-----|---------|
| `listVersions` | `asc versions list --app-id <id>` |
| `listLocalizations` | `asc localizations list --version-id <id>` |
| `listScreenshotSets` | `asc screenshot-sets list --localization-id <id>` |
| `listScreenshots` | `asc screenshots list --set-id <id>` |
| `submitForReview` | `asc versions submit --version-id <id>` |

## OutputFormatter Integration

Use `formatAgentItems` (not `formatItems`) for agent-first commands. It:
1. Wraps the response in `{"data": [...]}`
2. Merges `affordances` into each item's JSON

```swift
// ✅ Agent-first (new commands)
let output = try formatter.formatAgentItems(
    versions,
    headers: ["Platform", "Version", "State"],
    rowMapper: { v in [v.platform.displayName, v.versionString, v.state.displayName] }
)

// ❌ Legacy (do not use for new commands)
let output = try formatter.formatItems(versions, ...)
```

## JSON Output Shape

```json
{
  "data": [
    {
      "id": "v1",
      "appId": "app-abc",
      "versionString": "2.1.0",
      "platform": "IOS",
      "state": "READY_FOR_SALE",
      "isLive": true,
      "isEditable": false,
      "isPending": false,
      "affordances": {
        "listLocalizations": "asc localizations list --version-id v1",
        "listVersions": "asc versions list --app-id app-abc"
      }
    }
  ]
}
```

## Tests

Add affordance tests in `Tests/DomainTests/Apps/AffordancesTests.swift`:

```swift
@Test func `app affordances include listVersions command`() {
    let app = App(id: "app-1", name: "My App", bundleId: "com.example")
    #expect(app.affordances["listVersions"] == "asc versions list --app-id app-1")
}

@Test func `version affordances include submitForReview only when editable`() {
    let editable = MockRepositoryFactory.makeVersion(id: "v1", state: .prepareForSubmission)
    let live     = MockRepositoryFactory.makeVersion(id: "v2", state: .readyForSale)
    #expect(editable.affordances["submitForReview"] != nil)
    #expect(live.affordances["submitForReview"] == nil)
}
```