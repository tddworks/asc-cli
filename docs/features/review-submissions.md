# Review Submissions

Inspect App Store review submissions: state, rejected items, and per-item drill-in affordances. A *review submission* is the top-level record Apple's review queue operates on; it packages one or more `ReviewSubmissionItem`s, each pointing at a reviewable resource (typically an `AppStoreVersion`).

When a submission's state is `UNRESOLVED_ISSUES`, the per-item state pinpoints *which* attached resource Apple rejected. The reviewer's free-text reasoning is **not exposed via the public ASC API** — it lives only in the App Store Connect Resolution Center web UI. The CLI surfaces the state machine, not the narrative.

---

## CLI Usage

### `asc review-submissions list`

```
asc review-submissions list --app-id <id> [--state <csv>] [--limit <n>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | Yes | App ID whose submissions to list |
| `--state` | No | Comma-separated states: `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `UNRESOLVED_ISSUES`, `CANCELING`, `COMPLETING`, `COMPLETE`. If omitted, all states are returned |
| `--limit` | No | Maximum number of submissions to return |

#### Example: find submissions with unresolved issues

```bash
asc review-submissions list --app-id 1234567890 --state UNRESOLVED_ISSUES --pretty
```

```json
{
  "data" : [
    {
      "affordances" : {
        "getSubmission" : "asc review-submissions get --submission-id sub-1",
        "listItems" : "asc review-submissions items list --submission-id sub-1",
        "listRejectedItems" : "asc review-submissions items list --state REJECTED --submission-id sub-1",
        "listVersions" : "asc versions list --app-id 1234567890"
      },
      "appId" : "1234567890",
      "id" : "sub-1",
      "platform" : "IOS",
      "state" : "UNRESOLVED_ISSUES"
    }
  ]
}
```

The `listRejectedItems` affordance only appears when `state == UNRESOLVED_ISSUES`, so an agent can branch on its presence.

### `asc review-submissions get`

```
asc review-submissions get --submission-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--submission-id` | Yes | Submission ID to fetch |

Returns a single submission with its affordances — useful when you already have the id (e.g. from `submit`) and want the current state.

### `asc review-submissions items list`

```
asc review-submissions items list --submission-id <id> [--state <ITEM_STATE>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--submission-id` | Yes | Submission whose items to list |
| `--state` | No | Filter by item state: `READY_FOR_REVIEW`, `ACCEPTED`, `APPROVED`, `REJECTED`, `REMOVED` |

Returns the per-item review verdict. When the parent submission is `UNRESOLVED_ISSUES`, filter by `--state REJECTED` to see exactly which attached resource Apple flagged.

```bash
asc review-submissions items list --submission-id sub-1 --state REJECTED --pretty
```

```json
{
  "data" : [
    {
      "affordances" : {
        "getSubmission" : "asc review-submissions get --submission-id sub-1",
        "getVersion" : "asc versions get --version-id v-9",
        "listSiblings" : "asc review-submissions items list --submission-id sub-1"
      },
      "id" : "item-1",
      "linkedResourceId" : "v-9",
      "linkedResourceType" : "APP_STORE_VERSION",
      "state" : "REJECTED",
      "submissionId" : "sub-1"
    }
  ]
}
```

`getVersion` lets the agent jump straight to the rejected `AppStoreVersion`.

---

## REST Endpoints

| Method | Path | CLI flag → query param | Purpose |
|--------|------|------------------------|---------|
| `GET` | `/api/v1/apps/{appId}/review-submissions` | `--state` → `?state=`, `--limit` → `?limit=` | List submissions for an app |
| `GET` | `/api/v1/review-submissions/{id}` | — | Get a single submission |
| `GET` | `/api/v1/review-submissions/{id}/items` | `--state` → `?state=` | List items in a submission (optionally filtered) |

```bash
curl http://localhost:8080/api/v1/review-submissions/sub-1
curl 'http://localhost:8080/api/v1/review-submissions/sub-1/items?state=REJECTED'
```

REST responses include `_links` derived from the same `structuredAffordances` the CLI uses — both surfaces stay in sync.

---

## Typical Workflow

```bash
APP_ID=1234567890

# 1. Did anything get rejected?
asc review-submissions list --app-id "$APP_ID" --state UNRESOLVED_ISSUES

# 2. For each submission with issues, which item failed?
SUB_ID=$(asc review-submissions list --app-id "$APP_ID" --state UNRESOLVED_ISSUES \
         | jq -r '.data[0].id')
asc review-submissions items list --submission-id "$SUB_ID" --state REJECTED

# 3. Fix the rejected version (read Apple's notes in Resolution Center on the web)
VERSION_ID=$(asc review-submissions items list --submission-id "$SUB_ID" --state REJECTED \
             | jq -r '.data[0].linkedResourceId')
asc versions get --version-id "$VERSION_ID"

# 4. After fixing, resubmit
asc versions submit --version-id "$VERSION_ID"
```

---

## Architecture

```
ASCCommand/Commands/ReviewSubmissions/
├── ReviewSubmissionsCommand
├── ReviewSubmissionsList
├── ReviewSubmissionsGet
└── ReviewSubmissionItemsCommand
    └── ReviewSubmissionItemsList
          │
          ▼
Domain/Submissions/
├── ReviewSubmission
├── ReviewSubmissionState
├── ReviewSubmissionItem
├── ReviewSubmissionItemState
└── SubmissionRepository (protocol, @Mockable)
          │
          ▼
Infrastructure/Submissions/
└── OpenAPISubmissionRepository
      ├── GET /v1/reviewSubmissions?filter[app]=…
      ├── GET /v1/reviewSubmissions/{id}
      └── GET /v1/reviewSubmissions/{id}/items
```

Dependency flow is unidirectional: `ASCCommand → Infrastructure → Domain`.

---

## Domain Models

### `ReviewSubmission`

```swift
public struct ReviewSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String            // parent, injected by Infrastructure
    public let platform: AppStorePlatform
    public let state: ReviewSubmissionState
    public let submittedDate: Date?

    public var isComplete: Bool  { state.isComplete }
    public var isPending: Bool   { state.isPending }
    public var hasIssues: Bool   { state.hasIssues }
}
```

Affordances (`AffordanceProviding`, always present):
- `getSubmission` → `asc review-submissions get --submission-id <id>`
- `listItems` → `asc review-submissions items list --submission-id <id>`
- `listVersions` → `asc versions list --app-id <appId>`

Conditional:
- `listRejectedItems` → `asc review-submissions items list --state REJECTED --submission-id <id>` (only when `hasIssues == true`)

### `ReviewSubmissionState`

| Case | Raw value | `isPending` | `isComplete` | `hasIssues` |
|------|-----------|:-----------:|:------------:|:-----------:|
| `readyForReview` | `READY_FOR_REVIEW` | — | — | — |
| `waitingForReview` | `WAITING_FOR_REVIEW` | ✓ | — | — |
| `inReview` | `IN_REVIEW` | ✓ | — | — |
| `unresolvedIssues` | `UNRESOLVED_ISSUES` | — | — | ✓ |
| `canceling` | `CANCELING` | ✓ | — | — |
| `completing` | `COMPLETING` | ✓ | — | — |
| `complete` | `COMPLETE` | — | ✓ | — |

### `ReviewSubmissionItem`

```swift
public struct ReviewSubmissionItem: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let submissionId: String     // parent, injected by Infrastructure
    public let state: ReviewSubmissionItemState
    public let linkedResourceId: String?
    public let linkedResourceType: ReviewSubmissionItemLinkedResource?

    public var isRejected: Bool { state.isRejected }
    public var isApproved: Bool { state.isApproved }
    public var isPending: Bool  { state.isPending }
}
```

Affordances:
- `getSubmission` → walks back to the parent
- `listSiblings` → `asc review-submissions items list --submission-id <submissionId>`
- `getVersion` → `asc versions get --version-id <linkedResourceId>` (only when linked type is `APP_STORE_VERSION`)

### `ReviewSubmissionItemState`

| Case | Raw value | `isRejected` | `isApproved` | `isPending` |
|------|-----------|:------------:|:------------:|:-----------:|
| `readyForReview` | `READY_FOR_REVIEW` | — | — | ✓ |
| `accepted` | `ACCEPTED` | — | ✓ | — |
| `approved` | `APPROVED` | — | ✓ | — |
| `rejected` | `REJECTED` | ✓ | — | — |
| `removed` | `REMOVED` | — | — | — |

### `ReviewSubmissionItemLinkedResource`

Enum of resource types Apple can attach to a submission item: `APP_STORE_VERSION`, `APP_CUSTOM_PRODUCT_PAGE_VERSION`, `APP_STORE_VERSION_EXPERIMENT`, `APP_EVENT`, `BACKGROUND_ASSET_VERSION`, `GAME_CENTER_ACHIEVEMENT_VERSION`, `GAME_CENTER_ACTIVITY_VERSION`, `GAME_CENTER_CHALLENGE_VERSION`, `GAME_CENTER_LEADERBOARD_SET_VERSION`, `GAME_CENTER_LEADERBOARD_VERSION`. `APP_STORE_VERSION` is by far the common case.

### `SubmissionRepository`

```swift
@Mockable
public protocol SubmissionRepository: Sendable {
    func submitVersion(versionId: String) async throws -> ReviewSubmission
    func listSubmissions(appId: String, states: [ReviewSubmissionState]?, limit: Int?) async throws -> [ReviewSubmission]
    func getSubmission(id: String) async throws -> ReviewSubmission
    func listSubmissionItems(submissionId: String) async throws -> [ReviewSubmissionItem]
}
```

---

## File Map

```
Sources/
├── Domain/Submissions/
│   ├── ReviewSubmission.swift
│   ├── ReviewSubmission+RESTRoutes.swift          # registers `review-submissions items` route
│   ├── ReviewSubmissionState.swift
│   ├── ReviewSubmissionItem.swift
│   ├── ReviewSubmissionItemState.swift
│   └── SubmissionRepository.swift
├── Infrastructure/Submissions/
│   └── OpenAPISubmissionRepository.swift          # submitVersion + listSubmissions + getSubmission + listSubmissionItems
└── ASCCommand/Commands/ReviewSubmissions/
    ├── ReviewSubmissionsCommand.swift             # subcommand group
    ├── ReviewSubmissionsList.swift
    ├── ReviewSubmissionsGet.swift
    ├── ReviewSubmissionItemsCommand.swift
    └── ReviewSubmissionItemsList.swift

Tests/
├── DomainTests/Submissions/
│   ├── ReviewSubmissionTests.swift
│   └── ReviewSubmissionItemTests.swift
├── InfrastructureTests/Submissions/
│   └── SDKSubmissionRepositoryTests.swift
└── ASCCommandTests/Commands/ReviewSubmissions/
    ├── ReviewSubmissionsListTests.swift
    ├── ReviewSubmissionsGetTests.swift
    └── ReviewSubmissionItemsListTests.swift
```

Wiring:

| File | Purpose |
|------|---------|
| `Sources/ASCCommand/ASC.swift` | Registers `ReviewSubmissionsCommand.self` |
| `Sources/ASCCommand/ClientProvider.swift` | `makeSubmissionRepository()` (covers all four repo methods) |
| `Sources/Infrastructure/Client/ClientFactory.swift` | `makeSubmissionRepository(authProvider:)` → `OpenAPISubmissionRepository` |
| `Sources/ASCCommand/Commands/Web/Controllers/ReviewSubmissionsController.swift` | REST: `/apps/:appId/review-submissions`, `/review-submissions/:id`, `/review-submissions/:id/items` |
| `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` | Constructs `ReviewSubmissionsController` |
| `Sources/Domain/Shared/RESTPathResolver.swift` | Touches `_submissionRoutes` in `ensureInitialized()` |

---

## API Reference

| Operation | Endpoint | SDK call | Repository method |
|-----------|----------|----------|-------------------|
| List submissions | `GET /v1/reviewSubmissions?filter[app]=…&filter[state]=…&limit=…` | `APIEndpoint.v1.reviewSubmissions.get(parameters:)` | `listSubmissions(appId:states:limit:)` |
| Get submission | `GET /v1/reviewSubmissions/{id}?include=app` | `APIEndpoint.v1.reviewSubmissions.id(id).get(parameters:)` | `getSubmission(id:)` |
| List items | `GET /v1/reviewSubmissions/{id}/items` | `APIEndpoint.v1.reviewSubmissions.id(id).items.get(parameters:)` | `listSubmissionItems(submissionId:)` |
| Submit version | `POST /v1/reviewSubmissions` + `POST /v1/reviewSubmissionItems` + `PATCH /v1/reviewSubmissions/{id}` | — | `submitVersion(versionId:)` |

`filterApp` is required by Apple's API for the top-level list, so `--app-id` is required on `asc review-submissions list`.

The SDK returns the parent app only inside `relationships.app.data.id`. Domain models always carry `appId`/`submissionId`, so the infrastructure mapper injects the value from the request parameter rather than reading the relationship.

---

## Testing

```bash
swift test --filter 'ReviewSubmissionItemTests'
swift test --filter 'ReviewSubmissionsGetTests'
swift test --filter 'ReviewSubmissionItemsListTests'
swift test --filter 'SDKSubmissionRepositoryTests'
```

Representative item test (state-based, Chicago-school):

```swift
@Test func `listed items show id, submissionId, state, linked resource, and affordances`() async throws {
    let mockRepo = MockSubmissionRepository()
    given(mockRepo).listSubmissionItems(submissionId: .value("sub-1")).willReturn([
        ReviewSubmissionItem(
            id: "item-1", submissionId: "sub-1", state: .rejected,
            linkedResourceId: "v-9", linkedResourceType: .appStoreVersion
        ),
    ])

    let cmd = try ReviewSubmissionItemsList.parse(["--submission-id", "sub-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "getSubmission" : "asc review-submissions get --submission-id sub-1",
            "getVersion" : "asc versions get --version-id v-9",
            "listSiblings" : "asc review-submissions items list --submission-id sub-1"
          },
          "id" : "item-1",
          "linkedResourceId" : "v-9",
          "linkedResourceType" : "APP_STORE_VERSION",
          "state" : "REJECTED",
          "submissionId" : "sub-1"
        }
      ]
    }
    """)
}
```

---

## Extending

- **`cancel --submission-id <id>`** — `PATCH /v1/reviewSubmissions/{id}` with `canceled: true`. Add `cancelSubmission(id:)` to `SubmissionRepository`.
- **Resolution Center scraping** — Apple does not expose rejection notes via the public API. An optional iris/web-session path could mirror the web UI's Resolution Center messages; that's a separate, riskier path because it depends on a cookie session and HTML structure.
