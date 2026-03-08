---
name: asc-game-center
description: |
  Manage Game Center features using the `asc` CLI tool.
  Use this skill when:
  (1) Getting Game Center detail for an app: "asc game-center detail get --app-id ID"
  (2) Listing achievements: "asc game-center achievements list --detail-id ID"
  (3) Creating achievements: "asc game-center achievements create --detail-id ID --reference-name NAME --vendor-identifier ID --points N"
  (4) Deleting achievements: "asc game-center achievements delete --achievement-id ID"
  (5) Listing leaderboards: "asc game-center leaderboards list --detail-id ID"
  (6) Creating leaderboards: "asc game-center leaderboards create --detail-id ID --reference-name NAME --vendor-identifier ID --score-sort-type ASC|DESC --submission-type BEST_SCORE|MOST_RECENT_SCORE"
  (7) Deleting leaderboards: "asc game-center leaderboards delete --leaderboard-id ID"
  Trigger phrases: "game center", "achievements", "leaderboards", "arcade enabled", "score sort", "best score", "most recent score"
---

# Game Center with `asc`

Manage Game Center detail, achievements, and leaderboards through the App Store Connect API.

## Authentication

```bash
asc auth login --key-id <id> --issuer-id <id> --private-key-path ~/.asc/AuthKey.p8
```

## How to Navigate (CAEOAS Affordances)

Every JSON response contains an `"affordances"` field with ready-to-run commands — IDs already filled in. Start from the Game Center detail and navigate to achievements and leaderboards.

```json
{
  "id": "gc-abc123",
  "appId": "6443417124",
  "isArcadeEnabled": false,
  "affordances": {
    "getDetail": "asc game-center detail get --app-id 6443417124",
    "listAchievements": "asc game-center achievements list --detail-id gc-abc123",
    "listLeaderboards": "asc game-center leaderboards list --detail-id gc-abc123"
  }
}
```

## Typical Workflow

### Set up Game Center for an app

```bash
# 1. Get the Game Center detail (find the detail ID)
asc game-center detail get --app-id 6443417124 --pretty

# 2. List existing achievements
asc game-center achievements list --detail-id gc-abc123 --pretty

# 3. Create a new achievement
asc game-center achievements create \
  --detail-id gc-abc123 \
  --reference-name "First Steps" \
  --vendor-identifier first_steps \
  --points 10 \
  --pretty

# 4. Create a leaderboard
asc game-center leaderboards create \
  --detail-id gc-abc123 \
  --reference-name "All Time High" \
  --vendor-identifier all_time_high \
  --score-sort-type DESC \
  --submission-type BEST_SCORE \
  --pretty
```

### View all Game Center content at a glance

```bash
DETAIL_ID=$(asc game-center detail get --app-id APP_ID | jq -r '.data[0].id')
asc game-center achievements list --detail-id "$DETAIL_ID" --output table
asc game-center leaderboards list --detail-id "$DETAIL_ID" --output table
```

### Clean up — delete an achievement

```bash
# Copy the delete affordance from the achievement and run it
asc game-center achievements delete --achievement-id ach-abc123
```

## Commands

### `asc game-center detail get`

Get Game Center configuration for an app.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | yes | App Store Connect app ID |
| `--output table\|json` | no | Output format (default: json) |
| `--pretty` | no | Pretty-print JSON |

```bash
asc game-center detail get --app-id 6443417124 --pretty
asc game-center detail get --app-id 6443417124 --output table
```

### `asc game-center achievements list`

List all achievements for a Game Center detail.

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | yes | Game Center detail ID |
| `--output table\|json` | no | Output format |
| `--pretty` | no | Pretty-print JSON |

```bash
asc game-center achievements list --detail-id gc-abc123 --pretty
asc game-center achievements list --detail-id gc-abc123 --output table
```

### `asc game-center achievements create`

Create a new achievement.

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | yes | Game Center detail ID |
| `--reference-name` | yes | Internal reference name |
| `--vendor-identifier` | yes | Unique identifier (e.g. `first_steps`) |
| `--points` | yes | Point value for the achievement |
| `--show-before-earned` | no | Show achievement before earned (flag) |
| `--repeatable` | no | Achievement can be earned multiple times (flag) |
| `--pretty` | no | Pretty-print JSON |

```bash
asc game-center achievements create \
  --detail-id gc-abc123 \
  --reference-name "Speed Runner" \
  --vendor-identifier speed_runner \
  --points 50 \
  --repeatable
```

### `asc game-center achievements delete`

Delete an achievement.

| Flag | Required | Description |
|------|----------|-------------|
| `--achievement-id` | yes | Achievement ID to delete |

```bash
asc game-center achievements delete --achievement-id ach-abc123
```

### `asc game-center leaderboards list`

List all leaderboards for a Game Center detail.

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | yes | Game Center detail ID |
| `--output table\|json` | no | Output format |
| `--pretty` | no | Pretty-print JSON |

```bash
asc game-center leaderboards list --detail-id gc-abc123 --output table
```

### `asc game-center leaderboards create`

Create a new leaderboard.

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | yes | Game Center detail ID |
| `--reference-name` | yes | Internal reference name |
| `--vendor-identifier` | yes | Unique identifier (e.g. `all_time_high`) |
| `--score-sort-type` | yes | `ASC` or `DESC` |
| `--submission-type` | yes | `BEST_SCORE` or `MOST_RECENT_SCORE` |
| `--pretty` | no | Pretty-print JSON |

```bash
asc game-center leaderboards create \
  --detail-id gc-abc123 \
  --reference-name "Speed Run" \
  --vendor-identifier speed_run \
  --score-sort-type ASC \
  --submission-type MOST_RECENT_SCORE
```

### `asc game-center leaderboards delete`

Delete a leaderboard.

| Flag | Required | Description |
|------|----------|-------------|
| `--leaderboard-id` | yes | Leaderboard ID to delete |

```bash
asc game-center leaderboards delete --leaderboard-id lb-abc123
```

## Domain Models

**`GameCenterDetail`** — Game Center configuration for an app
- `id` — Game Center detail ID
- `appId` — parent App ID (injected from request, not returned by API)
- `isArcadeEnabled` — whether Apple Arcade is enabled
- Affordances: `getDetail`, `listAchievements`, `listLeaderboards`

**`GameCenterAchievement`** — A single Game Center achievement
- `id` — achievement ID
- `gameCenterDetailId` — parent detail ID (injected)
- `referenceName` — internal name
- `vendorIdentifier` — unique bundle-style identifier
- `points` — point value
- `isShowBeforeEarned` — visible before earned
- `isRepeatable` — can be earned multiple times
- `isArchived` — whether archived
- Affordances: `listAchievements`, `delete`

**`GameCenterLeaderboard`** — A single Game Center leaderboard
- `id` — leaderboard ID
- `gameCenterDetailId` — parent detail ID (injected)
- `referenceName` — internal name
- `vendorIdentifier` — unique identifier
- `scoreSortType` — `ASC` or `DESC`
- `submissionType` — `BEST_SCORE` or `MOST_RECENT_SCORE`
- `isArchived` — whether archived
- Affordances: `listLeaderboards`, `delete`

## Full Command Reference

See [commands.md](../asc-cli/references/commands.md) for all flags and examples.