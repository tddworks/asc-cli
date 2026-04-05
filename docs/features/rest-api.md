# Unified Affordances & REST API

## Overview

The `asc` CLI supports two interaction modes sharing a single Domain layer:

1. **CLI mode** — `asc apps list` → JSON with `"affordances"` (CLI commands)
2. **REST API mode** — `GET /api/v1/apps` → JSON with `"_links"` (HATEOAS links)

Both modes derive from a **single source of truth**: the `Affordance` struct defined on each domain model.

## CLI Usage

### Starting the server

```bash
asc web-server --port 8420
```

### REST API endpoints

```bash
# HATEOAS entry point — discover all available resources
curl http://localhost:8420/api/v1

# App management
curl http://localhost:8420/api/v1/apps
curl http://localhost:8420/api/v1/apps/123
curl http://localhost:8420/api/v1/apps/123/versions
curl http://localhost:8420/api/v1/apps/123/builds
curl http://localhost:8420/api/v1/apps/123/testflight

# Code signing
curl http://localhost:8420/api/v1/certificates
curl http://localhost:8420/api/v1/bundle-ids
curl http://localhost:8420/api/v1/devices
curl http://localhost:8420/api/v1/profiles

# Local resources
curl http://localhost:8420/api/v1/simulators
curl http://localhost:8420/api/v1/plugins

# Reference data
curl http://localhost:8420/api/v1/territories
```

### API Root (entry point)

`GET /api/v1` returns an index of all top-level resources:

```json
{
  "data": [
    {
      "version": "v1",
      "_links": {
        "apps":          { "href": "/api/v1/apps", "method": "GET" },
        "builds":        { "href": "/api/v1/builds", "method": "GET" },
        "certificates":  { "href": "/api/v1/certificates", "method": "GET" },
        "bundleIds":     { "href": "/api/v1/bundle-ids", "method": "GET" },
        "devices":       { "href": "/api/v1/devices", "method": "GET" },
        "profiles":      { "href": "/api/v1/profiles", "method": "GET" },
        "simulators":    { "href": "/api/v1/simulators", "method": "GET" },
        "plugins":       { "href": "/api/v1/plugins", "method": "GET" },
        "territories":   { "href": "/api/v1/territories", "method": "GET" },
        "appCategories": { "href": "/api/v1/app-categories", "method": "GET" }
      }
    }
  ]
}
```

An agent starts here, follows `_links` to navigate resources, and each resource response includes further `_links` for deeper navigation.

### Resource response format

REST responses use `_links` instead of CLI `affordances`:

```json
{
  "data": [
    {
      "id": "123",
      "name": "My App",
      "bundleId": "com.example.app",
      "_links": {
        "listVersions": { "href": "/api/v1/apps/123/versions", "method": "GET" },
        "listAppInfos": { "href": "/api/v1/apps/123/app-infos", "method": "GET" },
        "listReviews":  { "href": "/api/v1/apps/123/reviews", "method": "GET" }
      }
    }
  ]
}
```

The legacy `POST /api/run` CLI bridge remains available for commands without REST equivalents.

## Architecture

```
Terminal                          Web App / Agent
   │                                    │
   │ CLI args                    HTTP request
   ▼                                    ▼
ASCCommand                       RESTRoutes
(ArgumentParser)                 (Hummingbird)
   │                                    │
   │ execute(repo:)              RESTHandlers.*()
   ▼                                    ▼
OutputFormatter(.cli)            OutputFormatter(.rest)
   │                                    │
   │ WithAffordances(.cli)       WithAffordances(.rest)
   ▼                                    ▼
"affordances": {                 "_links": {
  "key": "asc cmd ..."            "key": {"href":"...", "method":"..."}
}                                }
```

Both call the same Domain repositories. CLI creates repos via `ClientProvider`. REST routes use the same `ClientProvider`.

## Domain Models

### Affordance (single source of truth)

**File**: `Sources/Domain/Shared/Affordance.swift`

```swift
public struct Affordance: Sendable, Equatable {
    public let key: String              // "listVersions"
    public let command: String          // "versions"
    public let action: String           // "list"
    public let params: [String: String] // ["app-id": "123"]

    public var cliCommand: String       // "asc versions list --app-id 123"
    public var restLink: APILink        // {href: "/api/v1/apps/123/versions", method: "GET"}
}
```

### APILink

```swift
public struct APILink: Sendable, Equatable, Codable {
    public let href: String
    public let method: String
}
```

### AffordanceMode

```swift
public enum AffordanceMode: Sendable, Equatable {
    case cli   // Renders "affordances": {key: "asc ..."}
    case rest  // Renders "_links": {key: {href, method}}
}
```

### AffordanceProviding protocol

**File**: `Sources/Domain/Shared/AffordanceProviding.swift`

```swift
public protocol AffordanceProviding {
    var structuredAffordances: [Affordance] { get }  // Single source
    var affordances: [String: String] { get }         // Derived: CLI
    var apiLinks: [String: APILink] { get }           // Derived: REST
    var registryProperties: [String: String] { get }
}
```

Default implementations derive `affordances` and `apiLinks` from `structuredAffordances`. Models that haven't migrated can still override `affordances` directly.

### RESTPathResolver

**File**: `Sources/Domain/Shared/Affordance.swift`

Maps CLI commands to REST paths using a static route table:

| CLI command | Parent param | REST path |
|-------------|-------------|-----------|
| `versions` | `app-id` | `/api/v1/apps/{id}/versions` |
| `builds` | `app-id` | `/api/v1/apps/{id}/builds` |
| `reviews` | `app-id` | `/api/v1/apps/{id}/reviews` |
| `version-localizations` | `version-id` | `/api/v1/versions/{id}/localizations` |
| `screenshot-sets` | `localization-id` | `/api/v1/version-localizations/{id}/screenshot-sets` |

### HTTP Method Mapping

| Action | HTTP Method |
|--------|------------|
| `list`, `get` | `GET` |
| `create` | `POST` |
| `update` | `PATCH` |
| `delete` | `DELETE` |
| custom (e.g. `submit`) | `POST` |

## Migrated Models

Models using `structuredAffordances` (single source):
- `App` — `listVersions`, `listAppInfos`, `listReviews`
- `AppStoreVersion` — `listLocalizations`, `listVersions`, `checkReadiness`, `getReviewDetail`, `submitForReview` (state-aware)

All other models (~78) still use the legacy `affordances` override and can be migrated incrementally.

## File Map

### Sources

```
Sources/
├── Domain/
│   └── Shared/
│       ├── Affordance.swift              # Affordance, APILink, AffordanceMode, RESTPathResolver
│       ├── AffordanceProviding.swift     # Protocol with structuredAffordances + derived properties
│       └── APIRoot.swift                 # HATEOAS entry point model
├── ASCCommand/
│   ├── OutputFormatter.swift             # WithAffordances(mode:), formatAgentItems(affordanceMode:)
│   └── Commands/Web/
│       ├── WebCommand.swift              # Wires RESTRoutes.configure into ASCWebServer
│       ├── RESTHandlers.swift            # Handler logic: repo → OutputFormatter(.rest) → JSON
│       ├── RESTRoutes.swift              # Composes all route files into one configurator
│       └── Routes/
│           ├── RootRoutes.swift          # GET /api/v1 — HATEOAS entry point
│           ├── AppsRoutes.swift          # /apps, /apps/:id, /apps/:id/versions, builds, testflight
│           ├── CodeSigningRoutes.swift   # /certificates, /bundle-ids, /devices, /profiles
│           ├── SimulatorsRoutes.swift    # /simulators
│           ├── PluginsRoutes.swift       # /plugins
│           └── TerritoriesRoutes.swift   # /territories
└── Infrastructure/
    └── Web/
        └── ASCWebServer.swift            # Accepts restRouteConfigurator closure
```

### Tests

```
Tests/
├── DomainTests/
│   └── Shared/
│       └── AffordanceTests.swift         # 42 tests: CLI/REST rendering, route table, APIRoot, model migration
└── ASCCommandTests/
    ├── OutputFormatterTests.swift         # 11 tests: CLI + REST mode formatting
    └── Commands/Web/
        └── RESTRoutesTests.swift         # 8 tests: REST handlers + API root
```

## Testing

```bash
# All tests
swift test

# Affordance tests only
swift test --filter 'AffordanceTests'

# REST route handler tests
swift test --filter 'RESTRoutesTests'

# OutputFormatter tests (includes REST mode)
swift test --filter 'OutputFormatterTests'
```

## Extending

### Adding a new REST endpoint

1. Add handler in `RESTHandlers.swift`:
```swift
static func listBuilds(appId: String, repo: any BuildRepository) async throws -> String {
    let builds = try await repo.listBuilds(appId: appId, ...)
    let formatter = OutputFormatter(format: .json, pretty: true)
    return try formatter.formatAgentItems(builds, headers: [], rowMapper: { _ in [] }, affordanceMode: .rest)
}
```

2. Register route in `RESTRoutes.swift`:
```swift
group.get("/apps/:appId/builds") { request, context -> Response in
    let appId = context.parameters.get("appId")!
    let repo = try ClientProvider.makeBuildRepository()
    let output = try await RESTHandlers.listBuilds(appId: appId, repo: repo)
    return jsonUTF8Response(output)
}
```

### Migrating a model to structured affordances

Replace the `affordances` override with `structuredAffordances`:

```swift
// Before
extension MyModel: AffordanceProviding {
    public var affordances: [String: String] {
        ["listChildren": "asc children list --parent-id \(id)"]
    }
}

// After
extension MyModel: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        [Affordance(key: "listChildren", command: "children", action: "list", params: ["parent-id": id])]
    }
}
```

Both `affordances` (CLI) and `apiLinks` (REST) are derived automatically.

### Adding to the route table

Add entry in `RESTPathResolver.routeTable`:

```swift
"children": (parentParam: "parent-id", parentSegment: "parents", segment: "children"),
```