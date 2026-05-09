# Beta App Localizations

Manage TestFlight **Beta App Description** and per-locale beta metadata (feedback email, marketing URL, privacy policy URL, tvOS-specific privacy policy text) using the `asc beta-app-localizations` command group.

This is the resource Apple reads when deciding whether your build can be opened to external TestFlight testers — a missing or empty Beta App Description is the most common reason an external-testing submission fails review.

> **Three different things easy to confuse:**
>
> | Resource | Command | Purpose |
> |---|---|---|
> | `BetaAppLocalization` | `asc beta-app-localizations` | Per-locale **beta app description**, feedback email, marketing/privacy URLs (this doc) |
> | `BetaBuildLocalization` | `asc builds update-beta-notes` | Per-build, per-locale **"What to Test"** notes |
> | `BetaAppReviewDetail` | `asc beta-review detail` | App-level beta review **contact info** + demo account |

## CLI Usage

### `asc beta-app-localizations list`

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | yes | App ID to list beta localizations for |

```bash
asc beta-app-localizations list --app-id 1234567890 --pretty
```

```json
{
  "data" : [
    {
      "affordances" : {
        "delete" : "asc beta-app-localizations delete --localization-id bal-1",
        "get" : "asc beta-app-localizations get --localization-id bal-1",
        "listSiblings" : "asc beta-app-localizations list --app-id 1234567890",
        "update" : "asc beta-app-localizations update --localization-id bal-1"
      },
      "appId" : "1234567890",
      "description" : "Welcome to the beta — please test the new dashboard.",
      "feedbackEmail" : "beta@example.com",
      "id" : "bal-1",
      "locale" : "en-US"
    }
  ]
}
```

Table output (`--output table`):

```
┌────────┬────────┬──────────────────────────────────────────────────┬───────────────────┐
│ ID     │ Locale │ Description                                      │ Feedback Email    │
├────────┼────────┼──────────────────────────────────────────────────┼───────────────────┤
│ bal-1  │ en-US  │ Welcome to the beta — please test the new dash…  │ beta@example.com  │
└────────┴────────┴──────────────────────────────────────────────────┴───────────────────┘
```

### `asc beta-app-localizations get`

| Flag | Required | Description |
|------|----------|-------------|
| `--localization-id` | yes | Beta app localization ID |

```bash
asc beta-app-localizations get --localization-id bal-1 --pretty
```

### `asc beta-app-localizations create`

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | yes | Parent app ID |
| `--locale` | yes | Locale code (e.g. `en-US`, `zh-Hans`) |
| `--description` | no | Beta app description shown to TestFlight testers |
| `--feedback-email` | no | Tester feedback email |
| `--marketing-url` | no | Marketing URL |
| `--privacy-policy-url` | no | Privacy policy URL |
| `--tv-os-privacy-policy` | no | tvOS-specific privacy policy text |

```bash
asc beta-app-localizations create \
    --app-id 1234567890 \
    --locale en-US \
    --description "Welcome to the beta — please test the new dashboard." \
    --feedback-email beta@example.com \
    --pretty
```

### `asc beta-app-localizations update`

| Flag | Required | Description |
|------|----------|-------------|
| `--localization-id` | yes | Beta app localization ID |
| `--description` | no | New description |
| `--feedback-email` | no | New feedback email |
| `--marketing-url` | no | New marketing URL |
| `--privacy-policy-url` | no | New privacy policy URL |
| `--tv-os-privacy-policy` | no | New tvOS privacy policy text |

Only the fields you pass are sent; omitted fields are left unchanged on App Store Connect.

```bash
asc beta-app-localizations update \
    --localization-id bal-1 \
    --description "Updated beta description" \
    --pretty
```

### `asc beta-app-localizations delete`

| Flag | Required | Description |
|------|----------|-------------|
| `--localization-id` | yes | Beta app localization ID |

```bash
asc beta-app-localizations delete --localization-id bal-1
```

## REST Endpoints

| Method | Path | CLI equivalent |
|--------|------|----------------|
| `GET` | `/api/v1/apps/:appId/beta-app-localizations` | `asc beta-app-localizations list --app-id <id>` |
| `GET` | `/api/v1/beta-app-localizations/:localizationId` | `asc beta-app-localizations get --localization-id <id>` |

CLI flag → REST query/path mapping:

| CLI flag | REST equivalent |
|----------|-----------------|
| `--app-id <id>` | path segment `:appId` |
| `--localization-id <id>` | path segment `:localizationId` |

```bash
curl http://localhost:8080/api/v1/apps/1234567890/beta-app-localizations
```

Each item in the response carries an `_links` block with the same actions the CLI advertises as affordances:

```json
{
  "_links" : {
    "delete" : { "href" : "/api/v1/beta-app-localizations/bal-1", "method" : "DELETE" },
    "get" : { "href" : "/api/v1/beta-app-localizations/bal-1", "method" : "GET" },
    "listSiblings" : { "href" : "/api/v1/apps/1234567890/beta-app-localizations", "method" : "GET" },
    "update" : { "href" : "/api/v1/beta-app-localizations/bal-1", "method" : "PATCH" }
  },
  "appId" : "1234567890",
  "description" : "Welcome…",
  "id" : "bal-1",
  "locale" : "en-US"
}
```

## Typical Workflow

```bash
# 1. Find the app
APP_ID=$(asc apps list --output json | jq -r '.data[0].id')

# 2. List existing beta localizations (Apple auto-creates one for the primary locale)
asc beta-app-localizations list --app-id "$APP_ID" --pretty

# 3. Set / update the English beta description
EXISTING=$(asc beta-app-localizations list --app-id "$APP_ID" --output json \
  | jq -r '.data[] | select(.locale == "en-US") | .id')

if [ -z "$EXISTING" ]; then
  asc beta-app-localizations create \
    --app-id "$APP_ID" \
    --locale en-US \
    --description "Welcome to the beta — please test the new dashboard." \
    --feedback-email beta@example.com
else
  asc beta-app-localizations update \
    --localization-id "$EXISTING" \
    --description "Welcome to the beta — please test the new dashboard." \
    --feedback-email beta@example.com
fi

# 4. Add a second locale
asc beta-app-localizations create \
    --app-id "$APP_ID" \
    --locale zh-Hans \
    --description "欢迎参与测试 — 请试用新版仪表盘。" \
    --feedback-email beta@example.com
```

## Architecture

```
ASCCommand (CLI)
└── BetaAppLocalizationsCommand
    ├── BetaAppLocalizationsList          formatAgentItems
    ├── BetaAppLocalizationsGet           formatAgentItems
    ├── BetaAppLocalizationsCreate        formatAgentItems
    ├── BetaAppLocalizationsUpdate        formatAgentItems
    └── BetaAppLocalizationsDelete        no payload

Web (Hummingbird)
└── BetaAppLocalizationsController       restFormat (.rest mode)
        GET /apps/:appId/beta-app-localizations
        GET /beta-app-localizations/:localizationId

Infrastructure
└── SDKBetaAppLocalizationRepository     adapts appstoreconnect-swift-sdk

Domain (pure)
├── BetaAppLocalization                  Sendable / Equatable / Codable / Presentable / AffordanceProviding
├── BetaAppLocalizationUpdate            patch payload
└── BetaAppLocalizationRepository        @Mockable protocol
```

`ASCCommand → Infrastructure → Domain` (one-way). The Domain layer never imports the SDK; the Infrastructure layer never imports `ArgumentParser` or Hummingbird.

## Domain Models

### `BetaAppLocalization`

```swift
public struct BetaAppLocalization: Sendable, Equatable, Identifiable, Codable, Presentable, AffordanceProviding {
    public let id: String
    public let appId: String         // injected by Infrastructure (ASC API omits parent IDs)
    public let locale: String
    public let description: String?       // beta app description shown in TestFlight
    public let feedbackEmail: String?
    public let marketingUrl: String?
    public let privacyPolicyUrl: String?
    public let tvOsPrivacyPolicy: String?
}
```

Optional fields use `encodeIfPresent` so unset fields drop out of the JSON output.

#### Affordances

| Key | Renders to |
|-----|------------|
| `delete` | `asc beta-app-localizations delete --localization-id <id>` |
| `get` | `asc beta-app-localizations get --localization-id <id>` |
| `listSiblings` | `asc beta-app-localizations list --app-id <appId>` |
| `update` | `asc beta-app-localizations update --localization-id <id>` |

In REST mode, the same affordances render as `_links` (`/api/v1/...`).

### `BetaAppLocalizationUpdate`

Patch payload — every field optional. The SDK adapter forwards present fields and lets ASC retain the rest.

### `BetaAppLocalizationRepository`

```swift
@Mockable
public protocol BetaAppLocalizationRepository: Sendable {
    func listBetaAppLocalizations(appId: String) async throws -> [BetaAppLocalization]
    func getBetaAppLocalization(localizationId: String) async throws -> BetaAppLocalization
    func createBetaAppLocalization(
        appId: String,
        locale: String,
        update: BetaAppLocalizationUpdate
    ) async throws -> BetaAppLocalization
    func updateBetaAppLocalization(
        localizationId: String,
        update: BetaAppLocalizationUpdate
    ) async throws -> BetaAppLocalization
    func deleteBetaAppLocalization(localizationId: String) async throws
}
```

## File Map

```
Sources/
├── Domain/Apps/TestFlight/
│   ├── BetaAppLocalization.swift
│   ├── BetaAppLocalizationRepository.swift
│   └── BetaGroup+RESTRoutes.swift           ← registers the apps→beta-app-localizations route
├── Infrastructure/Apps/TestFlight/
│   └── SDKBetaAppLocalizationRepository.swift
└── ASCCommand/
    ├── ClientProvider.swift                 ← makeBetaAppLocalizationRepository()
    ├── ASC.swift                            ← BetaAppLocalizationsCommand registered
    ├── Commands/BetaAppLocalizations/
    │   ├── BetaAppLocalizationsCommand.swift
    │   ├── BetaAppLocalizationsList.swift
    │   ├── BetaAppLocalizationsGet.swift
    │   ├── BetaAppLocalizationsCreate.swift
    │   ├── BetaAppLocalizationsUpdate.swift
    │   └── BetaAppLocalizationsDelete.swift
    └── Commands/Web/
        ├── Controllers/BetaAppLocalizationsController.swift
        └── RESTRoutes.swift                 ← wires the controller

Tests/
├── DomainTests/Apps/TestFlight/
│   └── BetaAppLocalizationTests.swift
├── InfrastructureTests/Apps/TestFlight/
│   └── SDKBetaAppLocalizationRepositoryTests.swift
└── ASCCommandTests/
    ├── Commands/BetaAppLocalizations/
    │   ├── BetaAppLocalizationsListTests.swift
    │   ├── BetaAppLocalizationsGetTests.swift
    │   ├── BetaAppLocalizationsCreateTests.swift
    │   ├── BetaAppLocalizationsUpdateTests.swift
    │   └── BetaAppLocalizationsDeleteTests.swift
    └── Commands/Web/RESTRoutesTests.swift   ← REST integration tests
```

| Wiring file | What it does |
|-------------|--------------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | `makeBetaAppLocalizationRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | CLI factory |
| `Sources/ASCCommand/ASC.swift` | Subcommand registration |
| `Sources/Domain/Apps/TestFlight/BetaGroup+RESTRoutes.swift` | REST path registration |
| `Sources/Domain/Shared/APIRoot.swift` | Advertises `betaAppLocalizations` from `GET /api/v1` |
| `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` | Mounts `BetaAppLocalizationsController` |

## API Reference

| ASC API endpoint | SDK call | Repository method |
|------------------|----------|-------------------|
| `GET /v1/apps/{id}/betaAppLocalizations` | `APIEndpoint.v1.apps.id(_).betaAppLocalizations.get` | `listBetaAppLocalizations(appId:)` |
| `GET /v1/betaAppLocalizations/{id}` | `APIEndpoint.v1.betaAppLocalizations.id(_).get` | `getBetaAppLocalization(localizationId:)` |
| `POST /v1/betaAppLocalizations` | `APIEndpoint.v1.betaAppLocalizations.post(_)` | `createBetaAppLocalization(appId:locale:update:)` |
| `PATCH /v1/betaAppLocalizations/{id}` | `APIEndpoint.v1.betaAppLocalizations.id(_).patch(_)` | `updateBetaAppLocalization(localizationId:update:)` |
| `DELETE /v1/betaAppLocalizations/{id}` | `APIEndpoint.v1.betaAppLocalizations.id(_).delete` | `deleteBetaAppLocalization(localizationId:)` |

## Testing

```bash
swift test --filter 'BetaAppLocalizations'
```

Representative domain test — verifies that a model correctly advertises the listing of its siblings under the parent app:

```swift
@Test func `beta app localization apiLinks include listSiblings under parent app`() {
    let loc = MockRepositoryFactory.makeBetaAppLocalization(id: "bal-1", appId: "app-7")
    let link = loc.apiLinks["listSiblings"]
    #expect(link?.href == "/api/v1/apps/app-7/beta-app-localizations")
    #expect(link?.method == "GET")
}
```

Representative infrastructure test — verifies parent-ID injection:

```swift
@Test func `listBetaAppLocalizations injects appId into each localization`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(BetaAppLocalizationsWithoutIncludesResponse(...))
    let repo = SDKBetaAppLocalizationRepository(client: stub)
    let locs = try await repo.listBetaAppLocalizations(appId: "app-42")
    #expect(locs.allSatisfy { $0.appId == "app-42" })
}
```

## Extending

Natural next steps:

1. **`asc beta-app-localizations upsert`** — single command that PATCHes when a localization already exists for the locale or POSTs otherwise. Mirrors the `BetaBuildLocalization` `upsert` pattern; would let users replace the create-or-update bash branch above with one call.

   ```swift
   public func upsertBetaAppLocalization(
       appId: String, locale: String, update: BetaAppLocalizationUpdate
   ) async throws -> BetaAppLocalization {
       let existing = try await listBetaAppLocalizations(appId: appId)
       if let match = existing.first(where: { $0.locale == locale }) {
           return try await updateBetaAppLocalization(localizationId: match.id, update: update)
       } else {
           return try await createBetaAppLocalization(appId: appId, locale: locale, update: update)
       }
   }
   ```

2. **Surface in `asc check-readiness`** — flag a missing or empty `description` for the primary locale, since that's the most common reason TestFlight external-testing submissions fail.
