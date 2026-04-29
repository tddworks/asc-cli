# Iris (Private API)

Access App Store Connect private API endpoints using cookie-based authentication. The iris API powers the ASC web UI and exposes capabilities not available through the public REST API, such as app creation.

---

## CLI Usage

### `asc iris status`

Check if iris cookie session is available.

| Flag | Required | Description |
|---|---|---|
| `--output` | ❌ | Output format: `json` (default) or `table` |
| `--pretty` | ❌ | Pretty-print JSON |

```bash
asc iris status --pretty
```

**JSON output:**
```json
{
  "data" : [
    {
      "affordances" : {
        "createApp" : "asc iris apps create --name <name> --bundle-id <id> --sku <sku>",
        "listApps" : "asc iris apps list"
      },
      "cookieCount" : 5,
      "source" : "browser"
    }
  ]
}
```

**Table output:**
```
Source   Cookies
------  -------
browser  5
```

---

### `asc iris apps list`

List all apps via iris private API.

| Flag | Required | Description |
|---|---|---|
| `--output` | ❌ | Output format: `json` (default) or `table` |
| `--pretty` | ❌ | Pretty-print JSON |

```bash
asc iris apps list --pretty
```

**JSON output:**
```json
{
  "data" : [
    {
      "affordances" : {
        "listAppInfos" : "asc app-infos list --app-id 1234567890",
        "listVersions" : "asc versions list --app-id 1234567890"
      },
      "bundleId" : "com.example.app",
      "id" : "1234567890",
      "name" : "My App",
      "platforms" : ["IOS"],
      "primaryLocale" : "en-US",
      "sku" : "MYSKU"
    }
  ]
}
```

---

### `asc iris apps create`

Create a new app on App Store Connect.

| Flag | Required | Default | Description |
|---|---|---|---|
| `--name` | ✅ | — | App name |
| `--bundle-id` | ✅ | — | Bundle identifier (e.g. `com.example.app`) |
| `--sku` | ✅ | — | SKU identifier |
| `--primary-locale` | ❌ | `en-US` | Primary locale |
| `--platforms` | ❌ | `IOS` | Platforms (`IOS`, `MAC_OS`) |
| `--version` | ❌ | `1.0` | Initial version string |
| `--output` | ❌ | `json` | Output format |
| `--pretty` | ❌ | — | Pretty-print JSON |

```bash
# Create iOS app
asc iris apps create --name "My App" --bundle-id com.example.app --sku MYSKU --pretty

# Multi-platform
asc iris apps create --name "My App" --bundle-id com.example.app --sku MYSKU \
    --platforms IOS MAC_OS --version 2.0

# Custom locale
asc iris apps create --name "我的应用" --bundle-id com.example.app --sku MYSKU \
    --primary-locale zh-Hans
```

---

## Authentication

Iris uses **cookie-based authentication** (not JWT API keys). Cookies are resolved in order:

1. **`ASC_IRIS_COOKIES` environment variable** — for CI/CD, set the raw cookie string
2. **Browser cookies** — auto-extracted from Chrome, Safari, or Firefox via [SweetCookieKit](https://github.com/steipete/SweetCookieKit)

The essential cookie is `myacinfo` (set on `.apple.com`). Additional cookies (`itctx`, `dqsid`, `wosid`, etc.) are collected from `appstoreconnect.apple.com`.

### Setup

Just log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) in your browser. That's it — `asc` will extract the cookies automatically.

### CI/CD

```bash
export ASC_IRIS_COOKIES="myacinfo=DAWT...; itctx=eyJ..."
asc iris apps create --name "My App" --bundle-id com.example.app --sku MYSKU
```

---

## Typical Workflow

```bash
# 1. Check if you're logged in
asc iris status --pretty

# 2. Create a new app
asc iris apps create \
    --name "My New App" \
    --bundle-id com.example.newapp \
    --sku com.example.newapp \
    --pretty

# 3. Continue with public API commands
asc versions list --app-id <id-from-step-2>
asc app-infos list --app-id <id-from-step-2>
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  ASCCommand                                                 │
│  ┌──────────┐  ┌────────────┐  ┌────────────────┐          │
│  │IrisStatus │  │IrisAppsList│  │IrisAppsCreate  │          │
│  └─────┬────┘  └─────┬──────┘  └───────┬────────┘          │
│        │             │                  │                    │
│        └─────────────┴──────────────────┘                    │
│                      │ ClientProvider                        │
├──────────────────────┼──────────────────────────────────────┤
│  Infrastructure      │                                       │
│  ┌───────────────────┴──────────┐  ┌──────────────────────┐ │
│  │ BrowserIrisCookieProvider    │  │ IrisSDKAppBundleRepo  │ │
│  │ (SweetCookieKit)             │  │ (IrisClient → HTTP)   │ │
│  └──────────────────────────────┘  └──────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│  Domain                                                      │
│  IrisSession · IrisStatus · IrisCookieProvider(@Mockable)    │
│  AppBundle · IrisAppBundleRepository(@Mockable)              │
└─────────────────────────────────────────────────────────────┘
```

Dependency: `ASCCommand → Infrastructure → Domain` (unidirectional, same as public API commands).

---

## Domain Models

### `IrisSession`

```swift
public struct IrisSession: Sendable, Equatable {
    public let cookies: String
}
```

### `IrisStatus`

```swift
public struct IrisStatus: Sendable, Equatable, Codable {
    public let source: IrisCookieSource   // .browser | .environment
    public let cookieCount: Int
}
```

**Affordances:** `listApps`, `createApp`

### `AppBundle`

```swift
public struct AppBundle: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let sku: String
    public let primaryLocale: String
    public let platforms: [String]
}
```

**Affordances:** `listVersions`, `listAppInfos`

### `IrisCookieProvider` (protocol)

```swift
@Mockable
public protocol IrisCookieProvider: Sendable {
    func resolveSession() throws -> IrisSession
    func resolveStatus() throws -> IrisStatus
}
```

### `IrisAppBundleRepository` (protocol)

```swift
@Mockable
public protocol IrisAppBundleRepository: Sendable {
    func listAppBundles(session: IrisSession) async throws -> [AppBundle]
    func createApp(session:name:bundleId:sku:primaryLocale:platforms:versionString:) async throws -> AppBundle
}
```

---

## File Map

### Sources

```
Sources/
├── Domain/Iris/
│   ├── IrisSession.swift
│   ├── IrisCookieProvider.swift
│   ├── IrisStatus.swift
│   └── AppBundles/
│       ├── AppBundle.swift
│       └── IrisAppBundleRepository.swift
├── Infrastructure/Iris/
│   ├── BrowserIrisCookieProvider.swift
│   ├── IrisClient.swift
│   └── AppBundles/
│       ├── IrisSDKAppBundleRepository.swift
│       └── IrisCreateAppDocument.swift
└── ASCCommand/Commands/Iris/
    ├── IrisCommand.swift
    ├── IrisAppsCommand.swift
    ├── IrisAppsList.swift
    ├── IrisAppsCreate.swift
    └── IrisStatus.swift
```

### Tests

```
Tests/
├── DomainTests/Iris/
│   ├── IrisSessionTests.swift
│   ├── IrisStatusTests.swift
│   └── AppBundles/
│       └── AppBundleTests.swift
├── InfrastructureTests/Iris/
│   └── IrisCreateAppDocumentTests.swift
└── ASCCommandTests/Commands/Iris/
    ├── IrisStatusTests.swift
    ├── IrisAppsListTests.swift
    └── IrisAppsCreateTests.swift
```

### Wiring

| File | Purpose |
|------|---------|
| `ClientProvider.swift` | `makeIrisCookieProvider()`, `makeIrisAppBundleRepository()` |
| `ClientFactory.swift` | Creates `BrowserIrisCookieProvider`, `IrisSDKAppBundleRepository` |
| `ASC.swift` | Registers `IrisCommand` |
| `Package.swift` | `SweetCookieKit` dependency on `Infrastructure` target |

---

## API Reference

| Endpoint | Method | SDK Call | Repository Method |
|----------|--------|----------|-------------------|
| `/iris/v1/appBundles?include=appBundleVersions&limit=300` | GET | `IrisClient.get()` | `listAppBundles(session:)` |
| `/iris/v1/apps` | POST | `IrisClient.post()` | `createApp(session:...)` |

### Create App Request Body

The POST `/iris/v1/apps` uses a JSON:API compound document with `included` resources. Placeholder IDs must use the `${local-id}` format:

```json
{
  "data": {
    "type": "apps",
    "attributes": { "sku": "...", "primaryLocale": "en-US", "bundleId": "..." },
    "relationships": {
      "appStoreVersions": { "data": [{"type": "appStoreVersions", "id": "${store-version-ios}"}] },
      "appInfos": { "data": [{"type": "appInfos", "id": "${new-appInfo-id}"}] }
    }
  },
  "included": [
    { "type": "appStoreVersions", "id": "${store-version-ios}", "attributes": {"platform": "IOS", "versionString": "1.0"}, ... },
    { "type": "appStoreVersionLocalizations", "id": "${new-iosVersionLocalization-id}", "attributes": {"locale": "en-US"} },
    { "type": "appInfos", "id": "${new-appInfo-id}", ... },
    { "type": "appInfoLocalizations", "id": "${new-appInfoLocalization-id}", "attributes": {"locale": "en-US", "name": "My App"} }
  ]
}
```

Built by `AppCreateRequest.make(...)` in `IrisCreateAppDocument.swift`.

---

## Testing

```swift
@Test func `created app shows id name bundleId and affordances`() async throws {
    let mockCookieProvider = MockIrisCookieProvider()
    given(mockCookieProvider).resolveSession().willReturn(
        IrisSession(cookies: "myacinfo=test")
    )
    let mockRepo = MockIrisAppBundleRepository()
    given(mockRepo).createApp(session: .any, name: .any, ...).willReturn(
        AppBundle(id: "app-1", name: "My New App", ...)
    )
    let cmd = try IrisAppsCreate.parse(["--name", "My New App", "--bundle-id", "com.example", "--sku", "SKU", "--pretty"])
    let output = try await cmd.execute(cookieProvider: mockCookieProvider, repo: mockRepo)
    #expect(output == """
    { "data": [{ "id": "app-1", "name": "My New App", "affordances": { ... } }] }
    """)
}
```

```bash
swift test --filter 'IrisStatusTests|IrisAppsListTests|IrisAppsCreateTests|AppBundleTests|AppCreateRequestTests'
```

---

## Extending

Natural next steps for the iris namespace:

- **`asc iris bundle-ids list`** — list registered bundle IDs via `/iris/v1/ascBundleIds`
- **`asc iris apps delete`** — delete an app
- **`asc iris users list`** — list team members with more detail than public API
