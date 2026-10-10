---
description: Get an app's Game Center setup, manage achievements and leaderboards, and block cheating scores or players. Use when setting up or moderating Game Center for a game.
---

# Game Center

Game Center achievements, leaderboards and leaderboard moderation for an app. Everything hangs off the app's Game Center detail ID.
Every flag: [command reference](../../commands.md#asc-game-center).

## Quick start

```bash
asc game-center detail get --app-id 6450000000 --pretty
asc game-center achievements list --detail-id gc-abc123
asc game-center leaderboards list --detail-id gc-abc123
```

## Workflows

### Set up achievements and leaderboards

```bash
# 1. Get the Game Center detail for your app (app-id from asc apps list)
asc game-center detail get --app-id 6450000000 --pretty

# 2. Create an achievement
asc game-center achievements create \
  --detail-id gc-abc123 \
  --reference-name "First Launch" \
  --vendor-identifier "first_launch" \
  --points 10

# 3. Create a high-score leaderboard
asc game-center leaderboards create \
  --detail-id gc-abc123 \
  --reference-name "All Time High" \
  --vendor-identifier "all_time_high" \
  --score-sort-type DESC \
  --submission-type BEST_SCORE

# 4. Verify
asc game-center achievements list --detail-id gc-abc123
asc game-center leaderboards list --detail-id gc-abc123
```

The detail response gives you the `id` to pass as `--detail-id`, plus ready-to-run next steps:

```json
{
  "data": [
    {
      "affordances": {
        "getDetail": "asc game-center detail get --app-id 6450000000",
        "listAchievements": "asc game-center achievements list --detail-id gc-abc123",
        "listBlockedPlayers": "asc game-center blocked-players list --detail-id gc-abc123",
        "listLeaderboards": "asc game-center leaderboards list --detail-id gc-abc123"
      },
      "appId": "6450000000",
      "id": "gc-abc123",
      "isArcadeEnabled": false
    }
  ]
}
```

Each achievement and leaderboard carries a `delete` affordance and a link back to its list. Each leaderboard also links to its submitted scores (`listScoreModerations`).

### Remove an achievement or leaderboard

```bash
asc game-center achievements delete --achievement-id ach-abc123
asc game-center leaderboards delete --leaderboard-id lb-abc123
```

### Moderate leaderboard scores and players

```bash
# 1. See the scores submitted to a leaderboard (rank, score, player, blocked state)
asc game-center score-moderations list --leaderboard-id lb-abc123 --output table

# 2. Hide a cheating score, or show it again
asc game-center score-moderations block   --moderation-id mod-abc123
asc game-center score-moderations unblock --moderation-id mod-abc123

# 3. Block the player behind it from every leaderboard of the game
asc game-center players block --player-id player-abc123

# 4. Review blocked players, and unblock one
asc game-center blocked-players list --detail-id gc-abc123
asc game-center players unblock --player-id player-abc123
```

`--blocked-only` on `score-moderations list` shows only blocked scores. Each score offers `block` or `unblock` by its state, and `blockPlayer` when its player isn't blocked yet:

```json
{
  "affordances": {
    "block": "asc game-center score-moderations block --moderation-id mod-abc123",
    "blockPlayer": "asc game-center players block --player-id player-abc123",
    "listScoreModerations": "asc game-center score-moderations list --leaderboard-id lb-abc123"
  },
  "challengeIds": [],
  "id": "mod-abc123",
  "isBlocked": false,
  "isPlayerBlocked": false,
  "isPreReleased": false,
  "leaderboardId": "lb-abc123",
  "playerId": "player-abc123",
  "playerNickname": "Player One",
  "rank": "1",
  "score": "9999",
  "submittedDate": "2026-01-01T00:00:00Z"
}
```

`rank` and `score` are strings so 64-bit values survive JSON. `isPreReleased` marks scores from TestFlight or development builds.

## REST

`asc web-server` serves the same data under `/api/v1`; `_links` in each response point at these paths.

| Method | Path | CLI |
|---|---|---|
| GET | `/apps/{appId}/game-center` | `detail get --app-id` |
| GET | `/game-center/details/{detailId}/leaderboards` | `leaderboards list --detail-id` |
| DELETE | `/game-center/leaderboards/{leaderboardId}` | `leaderboards delete` |
| GET | `/game-center/leaderboards/{leaderboardId}/score-moderations?blocked-only=true` | `score-moderations list [--blocked-only]` |
| POST | `/game-center/score-moderations/{id}/block`, `/unblock` | `score-moderations block`, `unblock` |
| GET | `/game-center/details/{detailId}/blocked-players` | `blocked-players list` |
| POST | `/game-center/players/{id}/block`, `/unblock` | `players block`, `unblock` |

Achievements, and creating achievements or leaderboards, are CLI-only.

## Gotchas

- `--score-sort-type`: `ASC` means lowest score wins, `DESC` means highest score wins.
- `--submission-type`: `BEST_SCORE` (default) tracks the player's personal best; `MOST_RECENT_SCORE` tracks their latest submission.
- `--reference-name` is internal only and not shown to players; `--vendor-identifier` must be unique (e.g. `first_steps`).
- `--show-before-earned` shows the achievement before the player earns it; `--repeatable` lets it be earned more than once.
- There are no update commands yet, and leaderboard sets are not supported.
- Score moderation uses Apple's v2 leaderboard endpoint with the leaderboard IDs from `leaderboards list` (v1). They are expected to be the same IDs, but this is not yet verified against a live account.
- Apple may reject unblocking a score; blocking is the reliable direction.
- `--blocked-only` maps to Apple's `exists[blocked]` filter.
- `score-moderations block`/`unblock` and `players block`/`unblock` responses don't name the leaderboard or detail, so the back-link to the list is missing from them.

## See also

[apps](../../commands.md#asc-apps)
