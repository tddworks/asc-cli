# App Wall

Community showcase of apps published on the App Store using asc CLI. Displayed at [asccli.app/#app-wall](https://asccli.app/#app-wall) as an auto-scrolling marquee of app cards.

## CLI Usage

### submit — add your app to the app wall

```bash
asc app-wall submit --developer <handle> [options]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--developer` | ✓ | Display handle shown on the card (`@developer`) |
| `--developer-id` | ✓* | Apple developer/seller ID — auto-fetches **all** your App Store apps |
| `--github` | — | GitHub username; card links to `github.com/<handle>` |
| `--x` | — | X/Twitter handle; card links to `x.com/<handle>` |
| `--app` | ✓* | Specific App Store URL (repeat flag for multiple apps) |
| `--github-token` | — | GitHub personal access token (or `GITHUB_TOKEN` env var) |
| `--output` | — | Output format: `json` (default), `table`, `markdown` |
| `--pretty` | — | Pretty-print JSON output |

_✓* At least one of `--developer-id` or `--app` is required — an entry with neither has no apps to display on the wall._

**Examples:**

```bash
# Mode A — all apps by developer ID
asc app-wall submit \
  --developer "itshan" \
  --developer-id "1725133580" \
  --github "hanrw" \
  --x "itshanrw" \
  --pretty

# Mode B — specific App Store URLs
asc app-wall submit \
  --developer "itshan" \
  --app "https://apps.apple.com/us/app/my-app/id123456789"

# Both modes combined
asc app-wall submit \
  --developer "itshan" \
  --developer-id "1725133580" \
  --app "https://apps.apple.com/us/app/extra-app/id987654321"
```

**JSON output:**

```json
{
  "data": [
    {
      "affordances": {
        "openPR": "open https://github.com/tddworks/asc-cli/pull/42"
      },
      "developer": "itshan",
      "id": "42",
      "prNumber": 42,
      "prUrl": "https://github.com/tddworks/asc-cli/pull/42",
      "title": "feat(app-wall): add itshan"
    }
  ]
}
```

**Table output:**

```
PR #  Title                      URL
42    feat(app-wall): add itshan  https://github.com/tddworks/asc-cli/pull/42
```

## Typical Workflow

```bash
# 1. Set up GitHub token (once)
export GITHUB_TOKEN="ghp_..."          # or: gh auth login

# 2. Submit your app — opens a PR automatically
asc app-wall submit \
  --developer "yourhandle" \
  --developer-id "1234567890" \
  --github "yourgithub" \
  --x "yourx" \
  --pretty

# 3. The CLI will:
#    a) Fork tddworks/asc-cli on your behalf
#    b) Add your entry to homepage/apps.json
#    c) Open a PR — URL is in the output

# 4. Open the PR in your browser
open "https://github.com/tddworks/asc-cli/pull/<number>"
```

## Error Cases

| Error | Cause | Fix |
|-------|-------|-----|
| `Provide --developer-id or at least one --app URL` | Neither flag supplied | Add `--developer-id` or at least one `--app` URL |
| `GitHub token required` | No token found | Pass `--github-token`, set `GITHUB_TOKEN`, or run `gh auth login` |
| `Developer X is already listed` | Duplicate `developer` in `apps.json` | Entry already submitted; check existing PR |
| `Timed out waiting for fork` | Fork creation took > 24 seconds | Retry after a moment |
| `GitHub API error (422)` | Branch already exists | Safe to ignore — command continues with the existing branch |

## Architecture

```
ASCCommand (AppWallSubmit)
    │  --developer, --developer-id, --github, --x, --app
    │  resolves GitHub token (flag → $GITHUB_TOKEN → gh auth token)
    ▼
Domain (AppWallRepository)
    │  submit(app: AppWallApp) -> AppWallSubmission
    ▼
Infrastructure (GitHubAppWallRepository)
    │  GitHub REST API
    ├─ GET  /user                                  → authenticated username
    ├─ POST /repos/tddworks/asc-cli/forks          → fork (idempotent)
    ├─ POST /repos/{user}/asc-cli/merge-upstream   → sync to main
    ├─ GET  /repos/{user}/asc-cli/contents/…       → fetch apps.json + SHA
    ├─ POST /repos/{user}/asc-cli/git/refs         → create feature branch
    ├─ PUT  /repos/{user}/asc-cli/contents/…       → commit updated apps.json
    └─ POST /repos/tddworks/asc-cli/pulls          → open PR
```

No ASC authentication required — only a GitHub token.

## Domain Models

### `AppWallApp`

Represents an app entry on the app wall. Maps directly to one object in `homepage/apps.json`.

| Field | Type | Notes |
|-------|------|-------|
| `developer` | `String` | Required. Display handle. Also the `id`. |
| `developerId` | `String?` | Optional. Auto-fetches all App Store apps. |
| `github` | `String?` | Optional. GitHub profile link. |
| `x` | `String?` | Optional. X/Twitter profile link. |
| `apps` | `[String]?` | Optional. Specific App Store URLs. |

Custom `Codable`: nil fields are omitted from JSON output (`encodeIfPresent`).

### `AppWallSubmission`

The result of a successful submit — the opened GitHub pull request.

| Field | Type | Notes |
|-------|------|-------|
| `prNumber` | `Int` | PR number. Also the `id`. |
| `prUrl` | `String` | Full GitHub PR URL. |
| `title` | `String` | PR title (`feat(app-wall): add <developer>`). |
| `developer` | `String` | Developer handle from the submitted app. |

**Affordances:** `openPR` → `open <prUrl>`

### `AppWallError`

| Case | Description |
|------|-------------|
| `alreadySubmitted(developer:)` | Entry with same `developer` already in `apps.json` |
| `forkTimeout` | Fork not ready after 8 retries (24 seconds) |
| `githubAPIError(statusCode:message:)` | GitHub API returned non-2xx |

### `AppWallRepository` (protocol)

```swift
@Mockable
public protocol AppWallRepository: Sendable {
    func submit(app: AppWallApp) async throws -> AppWallSubmission
}
```

## File Map

```
Sources/
├── Domain/AppWall/
│   ├── AppWallApp.swift           ← AppWallApp model (Codable, omits nil fields)
│   ├── AppWallSubmission.swift    ← PR result model + affordances
│   ├── AppWallRepository.swift    ← @Mockable protocol
│   └── AppWallError.swift         ← alreadySubmitted / forkTimeout / githubAPIError
├── Infrastructure/AppWall/
│   └── GitHubAppWallRepository.swift  ← GitHub REST API implementation
└── ASCCommand/Commands/AppWall/
    ├── AppWallCommand.swift        ← parent command (commandName: "app-wall")
    └── AppWallSubmit.swift         ← submit subcommand + token resolution

Tests/
├── DomainTests/AppWall/
│   └── AppWallEntryTests.swift    ← AppWallApp encoding, optionals, affordances
└── ASCCommandTests/Commands/AppWall/
    └── AppWallSubmitTests.swift   ← execute() with MockAppWallRepository
```

**Wiring:**
- `ASC.swift` — registers `AppWallCommand`
- `ClientProvider.makeAppWallRepository(token:)` — returns `GitHubAppWallRepository`

## API Reference

| Step | GitHub API endpoint | Notes |
|------|-------------------|-------|
| Identify user | `GET /user` | Resolves fork owner username |
| Fork repo | `POST /repos/tddworks/asc-cli/forks` | 202 = queued, 200/201 = already exists |
| Sync fork | `POST /repos/{user}/asc-cli/merge-upstream` | Best-effort, errors ignored |
| Fetch file | `GET /repos/{user}/asc-cli/contents/homepage/apps.json` | Base64 content + SHA |
| Create branch | `POST /repos/{user}/asc-cli/git/refs` | `refs/heads/app-wall/{developer}` |
| Commit | `PUT /repos/{user}/asc-cli/contents/homepage/apps.json` | Includes branch + SHA |
| Open PR | `POST /repos/tddworks/asc-cli/pulls` | head: `{user}:app-wall/{developer}` |

**Token resolution order:** `--github-token` flag → `$GITHUB_TOKEN` → `gh auth token`

## Testing

```swift
@Test func `submit returns PR details as formatted JSON`() async throws {
    let mockRepo = MockAppWallRepository()
    given(mockRepo).submit(app: .any).willReturn(
        AppWallSubmission(
            prNumber: 42,
            prUrl: "https://github.com/tddworks/asc-cli/pull/42",
            title: "feat(app-wall): add itshan",
            developer: "itshan"
        )
    )

    var cmd = try AppWallSubmit.parse([
        "--developer", "itshan",
        "--developer-id", "1725133580",
        "--github", "hanrw",
        "--pretty",
    ])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output.contains("\"prNumber\" : 42"))
    #expect(output.contains("\"developer\" : \"itshan\""))
}
```

```bash
swift test --filter 'AppWallAppTests|AppWallSubmitTests'
```

## Architecture (homepage pipeline)

```
apps.json                  ← community registry — developers submit PRs here
     │
     │  node homepage/fetch-apps-data.js
     ▼
apps-data.json             ← static iTunes metadata cache, committed to repo
     │
     │  node homepage/build-i18n.js
     ▼
homepage/index.html        ← fetch('apps-data.json') → render cards, no API calls
homepage/{lang}/index.html   (same for all 12 localized pages)
```

### Why static pre-fetch?

Fetching the iTunes API directly from the browser triggers CORS errors. Pre-fetching at build time avoids this — the browser only loads a static JSON file from the same origin.

## apps.json Format

Two modes (combinable):

```json
[
  {
    "developer": "your-github-handle",
    "developerId": "1234567890",
    "github": "your-github-handle",
    "x": "your-x-handle"
  }
]
```

| Field | Required | Description |
|-------|----------|-------------|
| `developer` | ✓ | Display handle shown on the card (`@developer`) |
| `developerId` | — | Apple developer ID — auto-fetches **all** your App Store apps |
| `github` | — | GitHub username; card links to `github.com/<handle>` with a GitHub icon |
| `x` | — | X/Twitter handle; card links to `x.com/<handle>` with an X icon |
| `apps` | — | Array of explicit App Store URLs for specific apps only |

Both `developerId` and `apps` can be combined. Duplicate apps (by `trackId`) are deduplicated automatically.

**Option B — specific URLs only:**

```json
{
  "developer": "your-github-handle",
  "github": "your-github-handle",
  "apps": [
    "https://apps.apple.com/us/app/your-app/idXXXXXXXXX"
  ]
}
```

## apps-data.json Format

Auto-generated by `fetch-apps-data.js`. **Do not edit manually.**

```json
{
  "generated": "2026-02-27T12:00:00.000Z",
  "items": [
    {
      "developer": "itshan",
      "github": "hanrw",
      "x": "itshanrw",
      "trackId": 1599719154,
      "trackName": "App Name",
      "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/.../100x100bb.jpg",
      "primaryGenreName": "Productivity",
      "url": "https://apps.apple.com/us/app/app-name/id1599719154"
    }
  ]
}
```

## File Map (homepage)

```
homepage/
├── apps.json              ← community registry (source of truth)
├── apps-data.json         ← generated iTunes metadata cache
├── fetch-apps-data.js     ← Node script: reads apps.json → writes apps-data.json
├── build-i18n.js          ← injects APPS_DATA_PATH per language, rebuilds HTML
├── template.html          ← app wall section + JS renderer
├── styles/layout.css      ← .app-wall-* CSS (scroll, static, cards)
└── i18n/
    ├── en.json            ← appWall.{eyebrow,title,subtitle,submitCta,ctaHint,empty}
    └── {zh,ja,ko,...}.json  (same keys, native translations)
```

## Extending

### Automate apps-data.json regeneration

Add a GitHub Actions workflow to refresh `apps-data.json` whenever `apps.json` changes:

```yaml
# .github/workflows/update-app-wall.yml
name: Update App Wall
on:
  push:
    paths:
      - 'homepage/apps.json'
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: node homepage/fetch-apps-data.js
      - run: node homepage/build-i18n.js
      - uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: 'chore(app-wall): refresh apps-data.json'
          file_pattern: 'homepage/apps-data.json homepage/index.html homepage/*/index.html'
```
