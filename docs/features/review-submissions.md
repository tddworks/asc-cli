# Review Submissions

List App Store review submissions for an app. A *review submission* is a top-level submission record that packages one or more `AppStoreVersion` items and is what Apple's review queue operates on.

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
| `--limit` | No | Maximum number of submissions to return (forwarded to the ASC API `limit` param) |

#### Example: check for submissions pending with Apple

```bash
asc review-submissions list --app-id 1234567890 \
  --state WAITING_FOR_REVIEW,IN_REVIEW,READY_FOR_REVIEW \
  --limit 200 --pretty
```

```json
{
  "data" : [
    {
      "affordances" : {
        "listVersions" : "asc versions list --app-id 1234567890"
      },
      "appId" : "1234567890",
      "id" : "sub-1",
      "platform" : "IOS",
      "state" : "WAITING_FOR_REVIEW"
    }
  ]
}
```

#### Example: check for submissions with unresolved issues

```bash
asc review-submissions list --app-id 1234567890 --state UNRESOLVED_ISSUES --limit 200
```

---

## Typical Workflow

```bash
APP_ID=1234567890

# 1. See what's pending in Apple's queue
asc review-submissions list --app-id "$APP_ID" \
  --state WAITING_FOR_REVIEW,IN_REVIEW,READY_FOR_REVIEW

# 2. See what needs developer action
asc review-submissions list --app-id "$APP_ID" --state UNRESOLVED_ISSUES

# 3. Drill into the underlying versions
asc versions list --app-id "$APP_ID"
```

---

## Architecture

```
ASCCommand/Commands/ReviewSubmissions/
└── ReviewSubmissionsCommand + ReviewSubmissionsList
          │
          ▼
Domain/Submissions/
└── SubmissionRepository (protocol, @Mockable)
          │
          ▼
Infrastructure/Submissions/
└── OpenAPISubmissionRepository  ── GET /v1/reviewSubmissions?filter[app]=…&filter[state]=…&limit=…
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

Affordances (`AffordanceProviding`):
- `listVersions` → `asc versions list --app-id <appId>`

### `ReviewSubmissionState`

```swift
public enum ReviewSubmissionState: String {
    case readyForReview      // READY_FOR_REVIEW
    case waitingForReview    // WAITING_FOR_REVIEW
    case inReview            // IN_REVIEW
    case unresolvedIssues    // UNRESOLVED_ISSUES — needs developer action
    case canceling           // CANCELING
    case completing          // COMPLETING
    case complete            // COMPLETE
}
```

Semantic booleans:
- `isComplete`   — `state == .complete`
- `isPending`    — `.waitingForReview | .inReview | .canceling | .completing`
- `hasIssues`    — `.unresolvedIssues`

### `SubmissionRepository`

```swift
@Mockable
public protocol SubmissionRepository: Sendable {
    func submitVersion(versionId: String) async throws -> ReviewSubmission
    func listSubmissions(appId: String, states: [ReviewSubmissionState]?, limit: Int?) async throws -> [ReviewSubmission]
}
```

---

## File Map

```
Sources/
├── Domain/Submissions/
│   ├── ReviewSubmission.swift
│   ├── ReviewSubmissionState.swift
│   └── SubmissionRepository.swift
├── Infrastructure/Submissions/
│   └── OpenAPISubmissionRepository.swift          # submitVersion + listSubmissions
└── ASCCommand/Commands/ReviewSubmissions/
    ├── ReviewSubmissionsCommand.swift             # subcommand group
    └── ReviewSubmissionsList.swift                # `list` subcommand

Tests/
├── DomainTests/Submissions/
│   └── ReviewSubmissionTests.swift
├── InfrastructureTests/Submissions/
│   └── SDKSubmissionRepositoryTests.swift         # includes listSubmissions tests
└── ASCCommandTests/Commands/ReviewSubmissions/
    └── ReviewSubmissionsListTests.swift
```

Wiring:

| File | Purpose |
|------|---------|
| `Sources/ASCCommand/ASC.swift` | Registers `ReviewSubmissionsCommand.self` in the subcommands array |
| `Sources/ASCCommand/ClientProvider.swift` | `makeSubmissionRepository()` |
| `Sources/Infrastructure/Client/ClientFactory.swift` | `makeSubmissionRepository(authProvider:)` → `OpenAPISubmissionRepository` |

---

## API Reference

| Operation | Endpoint | SDK call | Repository method |
|-----------|----------|----------|-------------------|
| List submissions | `GET /v1/reviewSubmissions?filter[app]=…&filter[state]=…&limit=…` | `APIEndpoint.v1.reviewSubmissions.get(parameters:)` | `listSubmissions(appId:states:limit:)` |
| Submit version | `POST /v1/reviewSubmissions` + `POST /v1/reviewSubmissionItems` + `PATCH /v1/reviewSubmissions/{id}` | — | `submitVersion(versionId:)` |

`filterApp` is **required** by the ASC API, so `--app-id` is required on the CLI.

The SDK returns the parent app only inside the response's `relationships.app.data.id`. Domain models always carry `appId`, so the infrastructure mapper injects the value from the request parameter rather than reading the relationship.

---

## Testing

```bash
swift test --filter 'ReviewSubmissionsListTests'
swift test --filter 'SDKSubmissionRepositoryTests'
```

Representative command test (state-based, Chicago-school):

```swift
@Test func `listed submissions show id, appId, state, platform, and affordances`() async throws {
    let mockRepo = MockSubmissionRepository()
    given(mockRepo).listSubmissions(appId: .value("app-42"), states: .any, limit: .any)
        .willReturn([
            ReviewSubmission(id: "sub-1", appId: "app-42", platform: .iOS, state: .waitingForReview),
        ])

    let cmd = try ReviewSubmissionsList.parse(["--app-id", "app-42", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "listVersions" : "asc versions list --app-id app-42"
          },
          "appId" : "app-42",
          "id" : "sub-1",
          "platform" : "IOS",
          "state" : "WAITING_FOR_REVIEW"
        }
      ]
    }
    """)
}
```

---

## Extending

- **`get --submission-id <id>`** — fetch a single submission with its items. Add `getSubmission(id:)` to the repository.
- **`cancel --submission-id <id>`** — `PATCH /v1/reviewSubmissions/{id}` with `canceled: true`. Add `cancelSubmission(id:)`.
- **`items list --submission-id <id>`** — list the `ReviewSubmissionItem`s attached to a submission.

Stub:

```swift
public func getSubmission(id: String) async throws -> ReviewSubmission {
    let req = APIEndpoint.v1.reviewSubmissions.id(id).get(parameters: .init(include: [.app]))
    let resp = try await client.request(req)
    guard let appId = resp.data.relationships?.app?.data?.id else {
        throw APIError.unknown("submission \(id) has no app relationship")
    }
    return mapListedSubmission(resp.data, appId: appId)
}
```
