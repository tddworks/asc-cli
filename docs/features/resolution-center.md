# Resolution Center

Read App Review's rejection messages and structured rejection reasons from the
Resolution Center — the one piece of review data the official App Store Connect
API does not expose.

> **Status:** design recorded before implementation (approved architecture).
> Sections marked *(finalize after implementation)* are re-verified against the
> actual code once the feature is green.

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
 │  affordances ──► "getSubmission", "listRejectedItems", "getVersion"
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
 │          ├─ ASC_IRIS_COOKIES env var          ── CI path
 │          └─ BrowserIrisCookieProvider          ── Chrome/Safari/Firefox
 │               ├─ cookies found → IrisSession
 │               └─ none → error: "Log in to appstoreconnect.apple.com
 │                          or set ASC_IRIS_COOKIES"
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
             │
             │  map → ResolutionCenterDetail
             │        • submissionId injected into every object (parent-ID rule)
             │        • HTML message body → plain text with --plain-text
             ▼
       OutputFormatter.formatAgentItems([detail])
             → {"data":[{ …, "affordances": { back-links } }]}
```

The three iris endpoint shapes are proven in the wild (the App Store Connect
web UI itself, and rorkai/App-Store-Connect-CLI's `web review show`). They are
undocumented, so the Infrastructure mapper is the absorption layer if Apple
shifts a field — Domain models stay stable.

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

## CLI Usage *(finalize after implementation)*

```bash
asc iris resolution-center get --submission-id <id> [--plain-text] [--pretty]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--submission-id` | yes | Review submission ID (from `asc review-submissions list`) |
| `--plain-text` | no | Convert HTML message bodies to plain text |

## REST Endpoints *(finalize after implementation)*

| Method | Path | CLI equivalent |
|--------|------|----------------|
| GET | `/api/v1/iris/review-submissions/:id/resolution-center` | `asc iris resolution-center get --submission-id <id>` |

## Domain Models *(finalize after implementation)*

- `ResolutionCenterDetail` — `id` (thread id), `submissionId` (parent),
  `threadState`, `messages`, `rejectionReasons`; semantic
  `hasRejections`; affordances back-link to `getSubmission`,
  `listRejectedItems`.
- `ResolutionCenterMessage` — `id`, `threadId` (parent), `createdDate`,
  `fromActor`, `body`.
- `ReviewRejectionReason` — `id`, `section`, `descriptionText`, `code`.

## File Map *(finalize after implementation)*

```
Sources/Domain/Iris/ResolutionCenter/
├── ResolutionCenterDetail.swift
├── ResolutionCenterMessage.swift
├── ReviewRejectionReason.swift
└── IrisResolutionCenterRepository.swift
Sources/Infrastructure/Iris/ResolutionCenter/
└── IrisSDKResolutionCenterRepository.swift
Sources/ASCCommand/Commands/Iris/ResolutionCenter/
├── IrisResolutionCenterCommand.swift
└── IrisResolutionCenterGet.swift
Sources/ASCCommand/Commands/Web/Controllers/
└── IrisResolutionCenterController.swift
```

## Testing *(finalize after implementation)*

```bash
swift test --filter ResolutionCenter
```

Infrastructure tests stub the three iris responses with a private
`URLProtocol` subclass (per-suite handler, following the
`IrisSubmissionsURLProtocolStub` precedent) and assert composition +
parent-ID injection.
