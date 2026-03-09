# App Clips

Manage App Clips and their default experiences, including locale-specific content shown in App Clip cards.

---

## CLI Usage

### `asc app-clips list`

List all App Clips for an app.

| Flag | Required | Description |
|---|---|---|
| `--app-id` | ✅ | App ID |
| `--output` | ❌ | Output format: `json` (default) or `table` |
| `--pretty` | ❌ | Pretty-print JSON |

```bash
asc app-clips list --app-id 1234567890
asc app-clips list --app-id 1234567890 --output table
asc app-clips list --app-id 1234567890 --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "listAppClips": "asc app-clips list --app-id 1234567890",
        "listExperiences": "asc app-clip-experiences list --app-clip-id clip-abc"
      },
      "appId": "1234567890",
      "bundleId": "com.example.MyApp.Clip",
      "id": "clip-abc"
    }
  ]
}
```

**Table output:**
```
ID        App ID      Bundle ID
clip-abc  1234567890  com.example.MyApp.Clip
```

---

### `asc app-clip-experiences list`

List default experiences for an App Clip.

| Flag | Required | Description |
|---|---|---|
| `--app-clip-id` | ✅ | App Clip ID |
| `--output` | ❌ | Output format: `json` (default) or `table` |
| `--pretty` | ❌ | Pretty-print JSON |

```bash
asc app-clip-experiences list --app-clip-id clip-abc
asc app-clip-experiences list --app-clip-id clip-abc --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "action": "OPEN",
      "affordances": {
        "delete": "asc app-clip-experiences delete --experience-id exp-xyz",
        "listExperiences": "asc app-clip-experiences list --app-clip-id clip-abc",
        "listLocalizations": "asc app-clip-experience-localizations list --experience-id exp-xyz"
      },
      "appClipId": "clip-abc",
      "id": "exp-xyz"
    }
  ]
}
```

---

### `asc app-clip-experiences create`

Create a default experience for an App Clip.

| Flag | Required | Description |
|---|---|---|
| `--app-clip-id` | ✅ | App Clip ID |
| `--action` | ❌ | Action: `OPEN`, `VIEW`, or `PLAY` |
| `--output` | ❌ | Output format |
| `--pretty` | ❌ | Pretty-print JSON |

```bash
asc app-clip-experiences create --app-clip-id clip-abc
asc app-clip-experiences create --app-clip-id clip-abc --action OPEN --pretty
```

---

### `asc app-clip-experiences delete`

Delete a default experience.

| Flag | Required | Description |
|---|---|---|
| `--experience-id` | ✅ | Experience ID |

```bash
asc app-clip-experiences delete --experience-id exp-xyz
```

---

### `asc app-clip-experience-localizations list`

List localizations for a default experience.

| Flag | Required | Description |
|---|---|---|
| `--experience-id` | ✅ | Experience ID |
| `--output` | ❌ | Output format |
| `--pretty` | ❌ | Pretty-print JSON |

```bash
asc app-clip-experience-localizations list --experience-id exp-xyz --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "delete": "asc app-clip-experience-localizations delete --localization-id loc-1",
        "listLocalizations": "asc app-clip-experience-localizations list --experience-id exp-xyz"
      },
      "experienceId": "exp-xyz",
      "id": "loc-1",
      "locale": "en-US",
      "subtitle": "Order faster with your loyalty card"
    }
  ]
}
```

---

### `asc app-clip-experience-localizations create`

Create a localization for a default experience.

| Flag | Required | Description |
|---|---|---|
| `--experience-id` | ✅ | Experience ID |
| `--locale` | ✅ | Locale code (e.g. `en-US`, `fr-FR`) |
| `--subtitle` | ❌ | Subtitle shown in the App Clip card |
| `--output` | ❌ | Output format |
| `--pretty` | ❌ | Pretty-print JSON |

```bash
asc app-clip-experience-localizations create \
  --experience-id exp-xyz \
  --locale en-US \
  --subtitle "Order faster with your loyalty card"
```

---

### `asc app-clip-experience-localizations delete`

Delete a localization.

| Flag | Required | Description |
|---|---|---|
| `--localization-id` | ✅ | Localization ID |

```bash
asc app-clip-experience-localizations delete --localization-id loc-1
```

---

## Typical Workflow

```bash
# 1. List App Clips for your app
asc app-clips list --app-id 1234567890 --pretty

# 2. Create a default experience for an App Clip
asc app-clip-experiences create \
  --app-clip-id clip-abc \
  --action OPEN \
  --pretty

# 3. Add English localization
asc app-clip-experience-localizations create \
  --experience-id exp-xyz \
  --locale en-US \
  --subtitle "Order faster with your loyalty card" \
  --pretty

# 4. Add French localization
asc app-clip-experience-localizations create \
  --experience-id exp-xyz \
  --locale fr-FR \
  --subtitle "Commandez plus vite avec votre carte" \
  --pretty

# 5. List all localizations
asc app-clip-experience-localizations list --experience-id exp-xyz --pretty

# 6. Delete an experience if needed
asc app-clip-experiences delete --experience-id exp-xyz
```

---

## Architecture

```
ASCCommand Layer
  AppClipsCommand (app-clips)
    └── AppClipsList
  AppClipExperiencesCommand (app-clip-experiences)
    ├── AppClipExperiencesList
    ├── AppClipExperiencesCreate
    └── AppClipExperiencesDelete
  AppClipExperienceLocalizationsCommand (app-clip-experience-localizations)
    ├── AppClipExperienceLocalizationsList
    ├── AppClipExperienceLocalizationsCreate
    └── AppClipExperienceLocalizationsDelete
        │
        │  AppClipRepository (protocol)
        ▼
Infrastructure Layer
  SDKAppClipRepository
    • GET  /v1/apps/{id}/appClips
    • GET  /v1/appClips/{id}/appClipDefaultExperiences
    • POST /v1/appClipDefaultExperiences
    • DELETE /v1/appClipDefaultExperiences/{id}
    • GET  /v1/appClipDefaultExperiences/{id}/appClipDefaultExperienceLocalizations
    • POST /v1/appClipDefaultExperienceLocalizations
    • DELETE /v1/appClipDefaultExperienceLocalizations/{id}
        │
        ▼
Domain Layer
  AppClip
  AppClipDefaultExperience + AppClipAction
  AppClipDefaultExperienceLocalization
  AppClipRepository (@Mockable)
```

**Dependency rule:** `ASCCommand → Infrastructure → Domain` (never reversed)

---

## Domain Models

### `AppClip`

```swift
public struct AppClip: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String       // injected from request parameter
    public let bundleId: String?   // nil if not set; omitted from JSON
}
```

**Affordances:**
| Key | Command |
|---|---|
| `listAppClips` | `asc app-clips list --app-id {appId}` |
| `listExperiences` | `asc app-clip-experiences list --app-clip-id {id}` |

---

### `AppClipDefaultExperience`

```swift
public struct AppClipDefaultExperience: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appClipId: String    // injected from request parameter
    public let action: AppClipAction?  // nil if not set; omitted from JSON
}
```

**Affordances:**
| Key | Command |
|---|---|
| `delete` | `asc app-clip-experiences delete --experience-id {id}` |
| `listExperiences` | `asc app-clip-experiences list --app-clip-id {appClipId}` |
| `listLocalizations` | `asc app-clip-experience-localizations list --experience-id {id}` |

---

### `AppClipAction`

```swift
public enum AppClipAction: String, Sendable, Equatable, Codable, CaseIterable {
    case open = "OPEN"
    case view = "VIEW"
    case play = "PLAY"
}
```

---

### `AppClipDefaultExperienceLocalization`

```swift
public struct AppClipDefaultExperienceLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let experienceId: String  // injected from request parameter
    public let locale: String
    public let subtitle: String?     // nil if not set; omitted from JSON
}
```

**Affordances:**
| Key | Command |
|---|---|
| `delete` | `asc app-clip-experience-localizations delete --localization-id {id}` |
| `listLocalizations` | `asc app-clip-experience-localizations list --experience-id {experienceId}` |

---

### `AppClipRepository`

```swift
@Mockable
public protocol AppClipRepository: Sendable {
    func listAppClips(appId: String) async throws -> [AppClip]
    func listExperiences(appClipId: String) async throws -> [AppClipDefaultExperience]
    func createExperience(appClipId: String, action: AppClipAction?) async throws -> AppClipDefaultExperience
    func deleteExperience(id: String) async throws
    func listLocalizations(experienceId: String) async throws -> [AppClipDefaultExperienceLocalization]
    func createLocalization(experienceId: String, locale: String, subtitle: String?) async throws -> AppClipDefaultExperienceLocalization
    func deleteLocalization(id: String) async throws
}
```

---

## File Map

```
Sources/
├── Domain/Apps/AppClips/
│   ├── AppClip.swift
│   ├── AppClipRepository.swift
│   └── Experiences/
│       ├── AppClipDefaultExperience.swift
│       └── Localizations/
│           └── AppClipDefaultExperienceLocalization.swift
├── Infrastructure/Apps/AppClips/
│   └── SDKAppClipRepository.swift
└── ASCCommand/Commands/
    ├── AppClips/
    │   ├── AppClipsCommand.swift
    │   └── AppClipsList.swift
    ├── AppClipExperiences/
    │   ├── AppClipExperiencesCommand.swift
    │   ├── AppClipExperiencesList.swift
    │   ├── AppClipExperiencesCreate.swift
    │   └── AppClipExperiencesDelete.swift
    └── AppClipExperienceLocalizations/
        ├── AppClipExperienceLocalizationsCommand.swift
        ├── AppClipExperienceLocalizationsList.swift
        ├── AppClipExperienceLocalizationsCreate.swift
        └── AppClipExperienceLocalizationsDelete.swift

Tests/
├── DomainTests/Apps/AppClips/
│   └── AppClipTests.swift
├── InfrastructureTests/Apps/AppClips/
│   └── SDKAppClipRepositoryTests.swift
└── ASCCommandTests/Commands/
    ├── AppClips/
    │   └── AppClipsListTests.swift
    ├── AppClipExperiences/
    │   └── AppClipExperiencesTests.swift
    └── AppClipExperienceLocalizations/
        └── AppClipExperienceLocalizationsTests.swift
```

**Wiring files:**
| File | Change |
|---|---|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeAppClipRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeAppClipRepository()` |
| `Sources/ASCCommand/ASC.swift` | Registered 3 new commands |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | Added 3 factory methods |

---

## API Reference

| Endpoint | SDK Call | Repository Method |
|---|---|---|
| `GET /v1/apps/{id}/appClips` | `APIEndpoint.v1.apps.id(appId).appClips.get()` | `listAppClips(appId:)` |
| `GET /v1/appClips/{id}/appClipDefaultExperiences` | `APIEndpoint.v1.appClips.id(appClipId).appClipDefaultExperiences.get()` | `listExperiences(appClipId:)` |
| `POST /v1/appClipDefaultExperiences` | `APIEndpoint.v1.appClipDefaultExperiences.post(body)` | `createExperience(appClipId:action:)` |
| `DELETE /v1/appClipDefaultExperiences/{id}` | `APIEndpoint.v1.appClipDefaultExperiences.id(id).delete` | `deleteExperience(id:)` |
| `GET /v1/appClipDefaultExperiences/{id}/appClipDefaultExperienceLocalizations` | `APIEndpoint.v1.appClipDefaultExperiences.id(experienceId).appClipDefaultExperienceLocalizations.get()` | `listLocalizations(experienceId:)` |
| `POST /v1/appClipDefaultExperienceLocalizations` | `APIEndpoint.v1.appClipDefaultExperienceLocalizations.post(body)` | `createLocalization(experienceId:locale:subtitle:)` |
| `DELETE /v1/appClipDefaultExperienceLocalizations/{id}` | `APIEndpoint.v1.appClipDefaultExperienceLocalizations.id(id).delete` | `deleteLocalization(id:)` |

**Parent ID injection:** infrastructure mappers always inject parent IDs from request parameters (not from response bodies, which don't include them).

---

## Testing

```swift
@Test func `listed experiences include appClipId action and affordances`() async throws {
    let mockRepo = MockAppClipRepository()
    given(mockRepo).listExperiences(appClipId: .any).willReturn([
        AppClipDefaultExperience(id: "exp-1", appClipId: "clip-1", action: .open)
    ])

    let cmd = try AppClipExperiencesList.parse(["--app-clip-id", "clip-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "action" : "OPEN",
          "affordances" : {
            "delete" : "asc app-clip-experiences delete --experience-id exp-1",
            "listExperiences" : "asc app-clip-experiences list --app-clip-id clip-1",
            "listLocalizations" : "asc app-clip-experience-localizations list --experience-id exp-1"
          },
          "appClipId" : "clip-1",
          "id" : "exp-1"
        }
      ]
    }
    """)
}
```

```bash
swift test --filter 'AppClip'
```

---

## Extending

**Natural next steps:**

- `asc app-clip-experiences update --experience-id <id> --action VIEW` — update experience action (`PATCH /v1/appClipDefaultExperiences/{id}`)
- `asc app-clip-experience-localizations update --localization-id <id> --subtitle "..."` — update subtitle (`PATCH /v1/appClipDefaultExperienceLocalizations/{id}`)
- `asc app-clip-experiences get --experience-id <id>` — get a single experience
- Advanced App Clip Experiences — `asc app-clip-advanced-experiences` via `/v1/appClipAdvancedExperiences`

```swift
// Stub for update experience
public func updateExperience(id: String, action: AppClipAction?) async throws -> AppClipDefaultExperience {
    let body = AppClipDefaultExperienceUpdateRequest(
        data: .init(
            type: .appClipDefaultExperiences,
            id: id,
            attributes: .init(action: action.map { mapActionToSDK($0) })
        )
    )
    let response = try await client.request(APIEndpoint.v1.appClipDefaultExperiences.id(id).patch(body))
    let appClipId = response.data.relationships?.appClip?.data?.id ?? ""
    return mapExperience(response.data, appClipId: appClipId)
}
```
