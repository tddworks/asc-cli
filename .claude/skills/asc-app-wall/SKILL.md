---
name: asc-app-wall
description: |
  Submit an app to the asc app wall at asccli.app by opening a GitHub pull request.
  Use this skill when:
  (1) User wants to add their app to the app wall: "submit my app", "add to app wall", "list my app on asc"
  (2) User asks how to get their apps shown at asccli.app
  (3) User asks what apps.json is for or how the app wall community registry works
  (4) Explaining the GitHub PR flow for submitting to homepage/apps.json
---

# asc app-wall — Submit Your App to the App Wall

Adds your app to the community showcase at [asccli.app/#app-wall](https://asccli.app/#app-wall) by forking `tddworks/asc-cli`, adding your entry to `homepage/apps.json`, and opening a pull request — all in one command.

No ASC authentication required. Only a GitHub token is needed.

## Command

```bash
asc app-wall submit --developer <handle> [options]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--developer` | ✓ | Display handle shown on the card (`@developer`) |
| `--developer-id` | ✓* | Apple developer/seller ID — auto-fetches **all** your App Store apps |
| `--github` | — | GitHub username |
| `--x` | — | X/Twitter handle |
| `--app` | ✓* | Specific App Store URL (repeat for multiple) |
| `--github-token` | — | GitHub token (or set `GITHUB_TOKEN` / `gh auth login`) |

_✓* At least one of `--developer-id` or `--app` is required — without it there are no apps to display on the wall._

## Typical Workflow

```bash
# 1. Authenticate with GitHub (once)
gh auth login
# or: export GITHUB_TOKEN="ghp_..."

# 2. Submit — the CLI handles fork + commit + PR automatically
asc app-wall submit \
  --developer "yourhandle" \
  --developer-id "1234567890" \
  --github "yourgithub" \
  --x "yourx" \
  --pretty

# 3. Open the PR in your browser (URL is in the output)
open "https://github.com/tddworks/asc-cli/pull/<number>"
```

## Two Submission Modes

**Mode A — all apps by developer ID** (recommended):
```bash
asc app-wall submit \
  --developer "itshan" \
  --developer-id "1725133580" \
  --github "hanrw"
```
Find your Apple developer ID at `https://apps.apple.com/us/developer/name/id<NUMBER>`.

**Mode B — specific App Store URLs:**
```bash
asc app-wall submit \
  --developer "itshan" \
  --app "https://apps.apple.com/us/app/my-app/id123456789" \
  --app "https://apps.apple.com/us/app/other-app/id987654321"
```

Both modes can be combined in one command.

## JSON Output

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

## What Happens Under the Hood

1. Authenticates with GitHub using your token
2. Forks `tddworks/asc-cli` (idempotent — safe to run multiple times)
3. Syncs the fork to upstream `main`
4. Fetches current `homepage/apps.json` from your fork
5. Checks for duplicate (`developer` field)
6. Creates branch `app-wall/<developer>`
7. Commits updated `apps.json` to that branch
8. Opens a PR against `tddworks/asc-cli:main`

## Error Cases

| Error | Cause | Fix |
|-------|-------|-----|
| `Provide --developer-id or at least one --app URL` | Neither flag supplied | Add `--developer-id` or `--app` |
| `GitHub token required` | No token found | Pass `--github-token`, set `GITHUB_TOKEN`, or run `gh auth login` |
| `Developer X is already listed` | Duplicate `developer` in `apps.json` | Entry already submitted; check existing PR |
| `Timed out waiting for fork` | Fork creation took > 24 seconds | Retry after a moment |
| `GitHub API error (422)` | Branch already exists | Safe to ignore — command continues |

## apps.json Format

The entry added to `homepage/apps.json`:

```json
{
  "developer": "yourhandle",
  "developerId": "1234567890",
  "github": "yourgithub",
  "x": "yourx"
}
```

Nil fields are omitted automatically. After the PR is merged, `fetch-apps-data.js` regenerates `apps-data.json` to pull in your apps from the iTunes API.

## See Also

- Full feature doc: `docs/features/app-wall.md`
- App wall live: `https://asccli.app/#app-wall`
- Upstream repo: `https://github.com/tddworks/asc-cli`