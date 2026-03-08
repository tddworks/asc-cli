# Game Center

Manage Game Center achievements and leaderboards for your app via the App Store Connect API.

## CLI Usage

### `asc game-center detail get`

Get Game Center configuration for an app.

```
asc game-center detail get --app-id <id> [--output json|table|markdown] [--pretty]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | ✅ | App ID |

**Example:**
```bash
asc game-center detail get --app-id 6450000000 --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "affordances": {
        "getDetail": "asc game-center detail get --app-id 6450000000",
        "listAchievements": "asc game-center achievements list --detail-id gc-abc123",
        "listLeaderboards": "asc game-center leaderboards list --detail-id gc-abc123"
      },
      "appId": "6450000000",
      "id": "gc-abc123",
      "isArcadeEnabled": false
    }
  ]
}
```

---

### `asc game-center achievements list`

List achievements for a Game Center detail.

```
asc game-center achievements list --detail-id <id> [--output json|table|markdown] [--pretty]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | ✅ | Game Center detail ID |

**Table output:**
```
ID          Reference Name   Vendor ID         Points   Archived
ach-abc123  First Steps      first_steps       10       no
```

---

### `asc game-center achievements create`

Create a new Game Center achievement.

```
asc game-center achievements create \
  --detail-id <id> \
  --reference-name <name> \
  --vendor-identifier <id> \
  --points <n> \
  [--show-before-earned] \
  [--repeatable]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | ✅ | Game Center detail ID |
| `--reference-name` | ✅ | Internal name (not shown to users) |
| `--vendor-identifier` | ✅ | Unique identifier (e.g. `first_steps`) |
| `--points` | ✅ | Point value (e.g. `10`) |
| `--show-before-earned` | ❌ | Show in UI before player earns it |
| `--repeatable` | ❌ | Allow earning multiple times |

---

### `asc game-center achievements delete`

Delete a Game Center achievement.

```
asc game-center achievements delete --achievement-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--achievement-id` | ✅ | Achievement ID |

---

### `asc game-center leaderboards list`

List leaderboards for a Game Center detail.

```
asc game-center leaderboards list --detail-id <id> [--output json|table|markdown] [--pretty]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | ✅ | Game Center detail ID |

**Table output:**
```
ID          Reference Name   Vendor ID         Sort   Submission
lb-abc123   All Time High    all_time_high     DESC   BEST_SCORE
```

---

### `asc game-center leaderboards create`

Create a new Game Center leaderboard.

```
asc game-center leaderboards create \
  --detail-id <id> \
  --reference-name <name> \
  --vendor-identifier <id> \
  --score-sort-type ASC|DESC \
  [--submission-type BEST_SCORE|MOST_RECENT_SCORE]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | ✅ | Game Center detail ID |
| `--reference-name` | ✅ | Internal name |
| `--vendor-identifier` | ✅ | Unique identifier |
| `--score-sort-type` | ✅ | `ASC` (lowest wins) or `DESC` (highest wins) |
| `--submission-type` | ❌ | `BEST_SCORE` (default) or `MOST_RECENT_SCORE` |

---

### `asc game-center leaderboards delete`

Delete a Game Center leaderboard.

```
asc game-center leaderboards delete --leaderboard-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--leaderboard-id` | ✅ | Leaderboard ID |

---

## Typical Workflow

```bash
# 1. Get Game Center detail for your app (use app-id from asc apps list)
asc game-center detail get --app-id 6450000000 --pretty

# 2. List existing achievements
asc game-center achievements list --detail-id gc-abc123

# 3. Create a new achievement
asc game-center achievements create \
  --detail-id gc-abc123 \
  --reference-name "First Launch" \
  --vendor-identifier "first_launch" \
  --points 10

# 4. List existing leaderboards
asc game-center leaderboards list --detail-id gc-abc123

# 5. Create a high-score leaderboard
asc game-center leaderboards create \
  --detail-id gc-abc123 \
  --reference-name "All Time High" \
  --vendor-identifier "all_time_high" \
  --score-sort-type DESC \
  --submission-type BEST_SCORE

# 6. Delete an achievement or leaderboard
asc game-center achievements delete --achievement-id ach-abc123
asc game-center leaderboards delete --leaderboard-id lb-abc123
```

---

## Architecture

```
ASCCommand
└── GameCenterCommand
    ├── GameCenterDetailCommand → GameCenterDetailGet
    ├── GameCenterAchievementsCommand → GameCenterAchievementsList / Create / Delete
    └── GameCenterLeaderboardsCommand → GameCenterLeaderboardsList / Create / Delete
         │ depends on
Infrastructure
└── SDKGameCenterRepository
    ├── getDetail(appId:)                → GET /v1/apps/{id}/gameCenterDetail
    ├── listAchievements(detailId:)      → GET /v1/gameCenterDetails/{id}/gameCenterAchievements
    ├── createAchievement(...)           → POST /v1/gameCenterAchievements
    ├── deleteAchievement(id:)           → DELETE /v1/gameCenterAchievements/{id}
    ├── listLeaderboards(detailId:)      → GET /v1/gameCenterDetails/{id}/gameCenterLeaderboards
    ├── createLeaderboard(...)           → POST /v1/gameCenterLeaderboards
    └── deleteLeaderboard(id:)           → DELETE /v1/gameCenterLeaderboards/{id}
         │ depends on
Domain
└── GameCenterDetail, GameCenterAchievement, GameCenterLeaderboard
    GameCenterRepository (@Mockable protocol)
    ScoreSortType, LeaderboardSubmissionType
```

**Dependency:** `ASCCommand → Infrastructure → Domain` (unidirectional, strictly enforced).

---

## Domain Models

### `GameCenterDetail`

```swift
public struct GameCenterDetail: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String          // parent — injected by Infrastructure
    public let isArcadeEnabled: Bool
}
```

**Affordances:**
- `getDetail` — `asc game-center detail get --app-id <appId>`
- `listAchievements` — `asc game-center achievements list --detail-id <id>`
- `listLeaderboards` — `asc game-center leaderboards list --detail-id <id>`

---

### `GameCenterAchievement`

```swift
public struct GameCenterAchievement: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let gameCenterDetailId: String  // parent — injected by Infrastructure
    public let referenceName: String
    public let vendorIdentifier: String
    public let points: Int
    public let isShowBeforeEarned: Bool
    public let isRepeatable: Bool
    public let isArchived: Bool
}
```

**Affordances:**
- `listAchievements` — `asc game-center achievements list --detail-id <gameCenterDetailId>`
- `delete` — `asc game-center achievements delete --achievement-id <id>`

---

### `GameCenterLeaderboard`

```swift
public struct GameCenterLeaderboard: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let gameCenterDetailId: String  // parent — injected by Infrastructure
    public let referenceName: String
    public let vendorIdentifier: String
    public let scoreSortType: ScoreSortType
    public let submissionType: LeaderboardSubmissionType
    public let isArchived: Bool
}
```

**Affordances:**
- `listLeaderboards` — `asc game-center leaderboards list --detail-id <gameCenterDetailId>`
- `delete` — `asc game-center leaderboards delete --leaderboard-id <id>`

---

### `ScoreSortType`

| Case | Raw Value | Meaning |
|------|-----------|---------|
| `.asc` | `"ASC"` | Lowest score wins |
| `.desc` | `"DESC"` | Highest score wins |

### `LeaderboardSubmissionType`

| Case | Raw Value | Meaning |
|------|-----------|---------|
| `.bestScore` | `"BEST_SCORE"` | Track player's personal best |
| `.mostRecentScore` | `"MOST_RECENT_SCORE"` | Track player's most recent submission |

---

### `GameCenterRepository`

```swift
@Mockable
public protocol GameCenterRepository: Sendable {
    func getDetail(appId: String) async throws -> GameCenterDetail

    func listAchievements(gameCenterDetailId: String) async throws -> [GameCenterAchievement]
    func createAchievement(
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        points: Int,
        isShowBeforeEarned: Bool,
        isRepeatable: Bool
    ) async throws -> GameCenterAchievement
    func deleteAchievement(id: String) async throws

    func listLeaderboards(gameCenterDetailId: String) async throws -> [GameCenterLeaderboard]
    func createLeaderboard(
        gameCenterDetailId: String,
        referenceName: String,
        vendorIdentifier: String,
        scoreSortType: ScoreSortType,
        submissionType: LeaderboardSubmissionType
    ) async throws -> GameCenterLeaderboard
    func deleteLeaderboard(id: String) async throws
}
```

---

## File Map

```
Sources/
├── Domain/GameCenter/
│   ├── GameCenterDetail.swift           # GameCenterDetail model + AffordanceProviding
│   ├── GameCenterAchievement.swift      # GameCenterAchievement model + AffordanceProviding
│   ├── GameCenterLeaderboard.swift      # GameCenterLeaderboard + ScoreSortType + LeaderboardSubmissionType
│   └── GameCenterRepository.swift      # @Mockable protocol
├── Infrastructure/GameCenter/
│   └── SDKGameCenterRepository.swift   # SDK adapter, injects parent IDs
└── ASCCommand/Commands/GameCenter/
    └── GameCenterCommand.swift          # All commands (detail/achievements/leaderboards)

Tests/
├── DomainTests/GameCenter/
│   └── GameCenterTests.swift
├── InfrastructureTests/GameCenter/
│   └── SDKGameCenterRepositoryTests.swift
└── ASCCommandTests/Commands/GameCenter/
    └── GameCenterCommandTests.swift
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/ASCCommand/ASC.swift` | Added `GameCenterCommand.self` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeGameCenterRepository()` |
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeGameCenterRepository(authProvider:)` |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | Added `makeGameCenterDetail/Achievement/Leaderboard()` |

---

## API Reference

| Endpoint | SDK call | Repository method |
|----------|----------|-------------------|
| `GET /v1/apps/{id}/gameCenterDetail` | `APIEndpoint.v1.apps.id(appId).gameCenterDetail.get()` | `getDetail(appId:)` |
| `GET /v1/gameCenterDetails/{id}/gameCenterAchievements` | `APIEndpoint.v1.gameCenterDetails.id(id).gameCenterAchievements.get()` | `listAchievements(gameCenterDetailId:)` |
| `POST /v1/gameCenterAchievements` | `APIEndpoint.v1.gameCenterAchievements.post(body)` | `createAchievement(...)` |
| `DELETE /v1/gameCenterAchievements/{id}` | `APIEndpoint.v1.gameCenterAchievements.id(id).delete` | `deleteAchievement(id:)` |
| `GET /v1/gameCenterDetails/{id}/gameCenterLeaderboards` | `APIEndpoint.v1.gameCenterDetails.id(id).gameCenterLeaderboards.get()` | `listLeaderboards(gameCenterDetailId:)` |
| `POST /v1/gameCenterLeaderboards` | `APIEndpoint.v1.gameCenterLeaderboards.post(body)` | `createLeaderboard(...)` |
| `DELETE /v1/gameCenterLeaderboards/{id}` | `APIEndpoint.v1.gameCenterLeaderboards.id(id).delete` | `deleteLeaderboard(id:)` |

---

## Testing

```bash
swift test --filter 'GameCenter'
```

Representative test:

```swift
@Test func `achievements list returns id, detailId, and affordances`() async throws {
    let mockRepo = MockGameCenterRepository()
    given(mockRepo).listAchievements(gameCenterDetailId: .any)
        .willReturn([
            GameCenterAchievement(
                id: "ach-1", gameCenterDetailId: "gc-1",
                referenceName: "First Steps", vendorIdentifier: "first_steps",
                points: 10, isShowBeforeEarned: true,
                isRepeatable: false, isArchived: false
            )
        ])

    let cmd = try GameCenterAchievementsList.parse(["--detail-id", "gc-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "delete" : "asc game-center achievements delete --achievement-id ach-1",
            "listAchievements" : "asc game-center achievements list --detail-id gc-1"
          },
          ...
        }
      ]
    }
    """)
}
```

---

## Extending

**Natural next steps:**

- **Update achievement** — `asc game-center achievements update --achievement-id <id> --points <n>`
  ```swift
  func updateAchievement(id: String, points: Int?, ...) async throws -> GameCenterAchievement
  // PATCH /v1/gameCenterAchievements/{id}
  ```

- **Update leaderboard** — `asc game-center leaderboards update --leaderboard-id <id> --score-sort-type DESC`
  ```swift
  func updateLeaderboard(id: String, scoreSortType: ScoreSortType?, ...) async throws -> GameCenterLeaderboard
  // PATCH /v1/gameCenterLeaderboards/{id}
  ```

- **Leaderboard sets** — `asc game-center leaderboard-sets list --detail-id <id>`
  ```swift
  // GET /v1/gameCenterDetails/{id}/gameCenterLeaderboardSets
  ```
