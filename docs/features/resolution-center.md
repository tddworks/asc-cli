# Resolution Center

Read App Review's rejection messages and structured rejection reasons from the
Resolution Center — the one piece of review data the official App Store Connect
API does not expose.

## Why this exists

When a review submission enters `UNRESOLVED_ISSUES`, the official API tells you
*that* something was rejected and *which* item (`reviewSubmissionItems` with
`state == REJECTED`) — but the reviewer's message text and the guideline
citations live only in the Resolution Center web UI. Apple's official OpenAPI
spec has **no** `resolutionCenter*` or `reviewRejection*` paths.

The web UI reads them from the iris private API (cookie web-session auth).
This feature adds an iris-surface command for exactly that read, and wires
CAEOAS affordances so agents discover it at the moment it becomes useful.

The two auth surfaces stay strictly split (same precedent as `asc iap submit`
vs `asc iris iap-submissions`):

- `asc review-submissions *` — official JWT key auth, zero iris dependency,
  CI-safe. The only coupling is a **string affordance** pointing at the iris
  command.
- `asc iris resolution-center *` — browser-cookie auth, fails fast with a
  helpful message when no cookies are available.

## CLI Usage

```bash
asc iris resolution-center get --submission-id <id> [--plain-text] [--out <dir>] [--pretty]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--submission-id` | yes | Review submission ID (from `asc review-submissions list`) |
| `--plain-text` | no | Convert HTML message bodies to plain text |
| `--out` | no | Download every downloadable attachment into this directory (created if missing), named by `fileName` |

Output (`--plain-text --pretty`, abridged):

```json
{
  "data" : [
    {
      "affordances" : {
        "getSubmission" : "asc review-submissions get --submission-id 4d2a8cbf-…",
        "listRejectedItems" : "asc review-submissions items list --state REJECTED --submission-id 4d2a8cbf-…"
      },
      "id" : "925db205-9466-36fe-9e28-118db7ea1e4d",
      "messages" : [
        {
          "body" : "Hello, \n\nThank you for submitting the new app… Guideline 5.2.5 - Legal - Intellectual Property…",
          "createdDate" : 805814892.99,
          "fromActor" : "APPLE",
          "id" : "b813b928-…",
          "threadId" : "925db205-…"
        }
      ],
      "rejectionReasons" : [
        {
          "code" : "5.2.5",
          "descriptionText" : "Legal: Intellectual Property - Apple Products (macOS)",
          "id" : "2a68bda3-…-0",
          "section" : "5.2.5"
        }
      ],
      "submissionId" : "4d2a8cbf-875e-4d75-b086-9fa47eb67796"
    }
  ]
}
```

Table output (`--output table`): `Thread ID | Submission ID | State | Messages | Rejections`.

Errors:

- No iris cookies → `No App Store Connect cookies found. Log in to
  appstoreconnect.apple.com in your browser, or set ASC_IRIS_COOKIES
  environment variable.`
- No thread yet → `No Resolution Center thread found for submission <id>.
  App Review has not sent any messages for this submission yet.`

## REST Endpoints

| Method | Path | CLI equivalent |
|--------|------|----------------|
| GET | `/api/v1/iris/review-submissions/:id/resolution-center` | `asc iris resolution-center get --submission-id <id>` |

Query-param mapping: CLI `--plain-text` → `?plain-text=true`.

```bash
curl "http://127.0.0.1:8080/api/v1/iris/review-submissions/<id>/resolution-center?plain-text=true"
```

Discovery: `GET /api/v1/review-submissions/:id` includes
`_links.getResolutionDetails` when the submission state is
`UNRESOLVED_ISSUES`.

## Agent flow

```
 Developer / AI agent
 │
 │  ① "How is my review going?"
 ▼
 asc review-submissions list --app-id 6787646042 --state UNRESOLVED_ISSUES
 │            [official JWT API — key auth, works headless/CI]
 │
 │  response: state=UNRESOLVED_ISSUES, hasIssues=true
 │  affordances ──► "getResolutionDetails": asc iris resolution-center get …
 │                  "listRejectedItems":    asc review-submissions items list …
 ▼
 │  ② "Which item did Apple reject?"
 asc review-submissions items list --submission-id <id> --state REJECTED
 │
 │  response: item state=REJECTED, linkedResourceType=APP_STORE_VERSION,
 │            linkedResourceId=<versionId>
 │  affordances ──► "getResolutionDetails" (same affordance)
 ▼
 │  ③ "WHY was it rejected?"  ← the gap this feature closes
 asc iris resolution-center get --submission-id <id> --plain-text
 │            [iris private API — browser cookies, NOT the JWT key]
 │
 │  response: reviewer message text + rejection reasons (section/code)
 │  affordances ──► "getSubmission", "listRejectedItems"
 ▼
 │  ④ fix the flagged resource (metadata, build, screenshots …)
 │  ⑤ resubmit: asc versions submit --version-id <versionId>
 │
 └──► back to ① (state returns to WAITING_FOR_REVIEW)
```

REST mirrors the same flow: `GET /api/v1/review-submissions/:id` →
`_links.getResolutionDetails` →
`GET /api/v1/iris/review-submissions/:id/resolution-center`.

## Runtime flow of the iris command

```
IrisResolutionCenterGet.run()
 │
 ├─► ClientProvider.makeIrisCookieProvider()
 │     └─ CompositeIrisCookieProvider (existing)
 │          ├─ StoredSRPIrisCookieProvider (from `asc iris auth login`)
 │          └─ BrowserIrisCookieProvider (Chrome/Safari/Firefox;
 │             honors ASC_IRIS_COOKIES)
 │
 └─► execute(cookieProvider:repo:affordanceMode:)
       │
       └─► IrisSDKResolutionCenterRepository.getResolution(session:submissionId:)
             │  call 1: GET /iris/v1/resolutionCenterThreads
             │            ?filter[reviewSubmission]={submissionId}
             │  call 2: GET /iris/v1/resolutionCenterThreads/{tid}/
             │            resolutionCenterMessages?include=fromActor,rejections
             │  call 3: GET /iris/v1/reviewRejections
             │            ?filter[resolutionCenterMessage.resolutionCenterThread]={tid}
             │  (calls 2+3 run concurrently once the thread id is known)
             │
             │  map → ResolutionCenterDetail
             │        • submissionId injected into every object (parent-ID rule)
             │        • fromActor resolved from included actors (actorType)
             ▼
       OutputFormatter.formatAgentItems([detail])
             → {"data":[{ …, "affordances": { back-links } }]}
```

The three iris endpoint shapes are proven in the wild (the App Store Connect
web UI itself). They are undocumented, so the Infrastructure mapper is the
absorption layer if Apple shifts a field — Domain models stay stable.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│ ASCCommand                                                       │
│  Commands/Iris/ResolutionCenter/IrisResolutionCenterGet          │
│  Commands/Web/Controllers/IrisResolutionCenterController         │
│    GET /api/v1/iris/review-submissions/:id/resolution-center     │
└───────────────┬──────────────────────────────────────────────────┘
┌───────────────▼──────────────────────────────────────────────────┐
│ Infrastructure                                                   │
│  Iris/ResolutionCenter/IrisSDKResolutionCenterRepository         │
│    composes the 3 iris calls via IrisClient (existing)           │
└───────────────┬──────────────────────────────────────────────────┘
┌───────────────▼──────────────────────────────────────────────────┐
│ Domain                                                           │
│  Iris/ResolutionCenter/                                          │
│    ResolutionCenterDetail   (thread + messages + reasons)        │
│    ResolutionCenterMessage  (reviewer text, fromActor, date)     │
│    ReviewRejectionReason    (section, description, code)         │
│    IrisResolutionCenterRepository (@Mockable)                    │
│  Submissions/ (glue)                                             │
│    ReviewSubmission     + getResolutionDetails when hasIssues    │
│    ReviewSubmissionItem + getResolutionDetails when isRejected   │
└──────────────────────────────────────────────────────────────────┘

Dependency flow: ASCCommand → Infrastructure → Domain (unidirectional).
```

## Domain Models

- `ResolutionCenterDetail` — `id` (thread id), `submissionId` (parent, injected
  by Infrastructure), `threadState`, `messages`, `rejectionReasons`.
  Semantics: `hasRejections`. Operations: `plainText()` returns a copy with
  every message body converted from HTML. Affordances: `getSubmission`,
  `listRejectedItems` (back-links into the official-API fix loop).
- `ResolutionCenterMessage` — `id`, `threadId` (parent), `createdDate`,
  `fromActor` (e.g. `APPLE` / `USER`), `body` (raw HTML), computed
  `plainTextBody`.
- `ReviewRejectionReason` — `id`, `section`, `descriptionText`, `code`
  (guideline number, e.g. `2.1`). When one iris rejection carries multiple
  reasons, ids are suffixed `-0`, `-1`, ….
- `ResolutionCenterAttachment` — `id`, `messageId` (parent), `fileName`,
  `fileSize`, `downloadUrl` (Apple-signed; absent while processing).
  Semantics: `isDownloadable`. `isValidDownloadURL(_:)` gates downloads to
  https on `.apple.com` / `.mzstatic.com` / `.amazonaws.com` /
  `.cloudfront.net`. The detail's `attachments` field is omitted from JSON
  when empty; when present, the detail gains a `downloadAttachments`
  affordance. REST clients fetch `downloadUrl` directly (no proxy endpoint) —
  `--out` downloads are CLI-side.
- `IrisResolutionCenterRepository` — `@Mockable`;
  `getResolution(session:submissionId:) → ResolutionCenterDetail`.
- `IrisResolutionCenterError.noThread(submissionId:)` (Infrastructure) —
  thrown when the submission has no Resolution Center thread yet.

## File Map

```
Sources/Domain/Iris/ResolutionCenter/
├── ResolutionCenterDetail.swift            # model + affordances + Presentable
├── ResolutionCenterDetail+RESTRoutes.swift # route: iris resolution-center
├── ResolutionCenterMessage.swift           # message + HTML→plain-text
├── ReviewRejectionReason.swift
└── IrisResolutionCenterRepository.swift    # @Mockable protocol
Sources/Infrastructure/Iris/ResolutionCenter/
└── IrisSDKResolutionCenterRepository.swift # 3-call composition + mapping
Sources/ASCCommand/Commands/Iris/ResolutionCenter/
├── IrisResolutionCenterCommand.swift
└── IrisResolutionCenterGet.swift
Sources/ASCCommand/Commands/Web/Controllers/
└── IrisResolutionCenterController.swift

Tests/DomainTests/Iris/ResolutionCenter/ResolutionCenterDetailTests.swift
Tests/InfrastructureTests/Iris/ResolutionCenter/IrisSDKResolutionCenterRepositoryTests.swift
Tests/ASCCommandTests/Commands/Iris/ResolutionCenter/IrisResolutionCenterGetTests.swift
Tests/ASCCommandTests/Commands/Web/RESTRoutesTests.swift (2 resolution-center tests)
```

| Wiring | File |
|--------|------|
| Subcommand registration | `Sources/ASCCommand/Commands/Iris/IrisCommand.swift` |
| Repository factory | `Sources/Infrastructure/Client/ClientFactory.swift` (`makeIrisResolutionCenterRepository`) |
| CLI provider | `Sources/ASCCommand/ClientProvider.swift` |
| REST controller wiring | `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` |
| Route resolver touch | `Sources/Domain/Shared/RESTPathResolver.swift` (`_resolutionCenterRoutes`) |

## API Reference

| Iris endpoint | Repository method | Notes |
|---------------|-------------------|-------|
| `GET /iris/v1/resolutionCenterThreads?filter[reviewSubmission]={id}` | `getResolution` (call 1) | picks the first thread; `noThread` error if empty |
| `GET /iris/v1/resolutionCenterThreads/{tid}/resolutionCenterMessages?include=fromActor,rejections,resolutionCenterMessageAttachments&limit=200&limit[resolutionCenterMessageAttachments]=1000` | `getResolution` (call 2) | actors + attachments resolved from `included` |
| signed `downloadUrl` (absolute) | `downloadAttachment(session:url:)` | host-validated via `ResolutionCenterAttachment.isValidDownloadURL` |
| `GET /iris/v1/reviewRejections?filter[resolutionCenterMessage.resolutionCenterThread]={tid}&limit=200` | `getResolution` (call 3) | `attributes.reasons[]` flattened |

## Testing

```bash
swift test --filter 'ResolutionCenter'
```

Infrastructure tests stub the three iris responses with a private
`URLProtocol` subclass (per-suite handler, following the
`IrisSubmissionsURLProtocolStub` precedent):

```swift
@Test func `getResolution composes thread, messages, and rejections with parent submissionId injected`() async throws {
    IrisResolutionCenterURLProtocolStub.handler = { request in
        let url = request.url!.absoluteString
        let body: Data = url.contains("resolutionCenterMessages") ? messagesJSON
            : url.contains("reviewRejections") ? rejectionsJSON : threadsJSON
        return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, body)
    }
    let detail = try await makeRepo().getResolution(
        session: IrisSession(cookies: "myacinfo=ABC"), submissionId: "sub-42"
    )
    #expect(detail.submissionId == "sub-42")
    #expect(detail.messages[0].fromActor == "APPLE")
}
```

## Extending

- **Reply to App Review** — no proven write endpoint exists in public
  references (only `GET …/resolutionCenterDraftMessage` is documented in the
  wild). Before implementing `resolution-center reply`, capture the ASC web
  UI's network traffic while actually sending a reply, then build from that
  evidence — do not guess a POST shape that messages App Review on a real app.
- **Rejection attachments** — `reviewRejections` can also carry
  `rejectionAttachments`; the current mapping covers message attachments only.
- **Threads across submissions** — `resolutionCenterThreads` also filters by
  app; an app-level listing could surface historical rejections.
