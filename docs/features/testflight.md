# TestFlight Beta Tester Management

Manage TestFlight beta groups and testers — list groups, invite testers, remove testers, and bulk import/export via CSV. Every response includes `affordances` with ready-to-run next-step commands.

## CLI Usage

### List Beta Groups

```bash
asc testflight groups list [--app-id <APP_ID>] [--limit N]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-id` | *(optional)* | Filter groups by app ID |
| `--limit` | *(optional)* | Maximum groups to return |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc testflight groups list --app-id 6450406024 --pretty
```

**JSON output:**

```json
{
  "data": [
    {
      "id": "g-abc123",
      "appId": "6450406024",
      "name": "External Beta",
      "isInternalGroup": false,
      "publicLinkEnabled": false,
      "affordances": {
        "exportTesters": "asc testflight testers export --beta-group-id g-abc123",
        "importTesters": "asc testflight testers import --beta-group-id g-abc123 --file testers.csv",
        "listTesters": "asc testflight testers list --beta-group-id g-abc123"
      }
    }
  ]
}
```

---

### Create Beta Group

```bash
asc testflight groups create --app-id <APP_ID> --name <NAME> [--internal] \
  [--public-link-enabled] [--feedback-enabled]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-id` | *(required)* | App ID that owns the group |
| `--name` | *(required)* | Group name |
| `--internal` | `false` | Create an internal group (team members only). When omitted, an external group is created. |
| `--public-link-enabled` | `false` | Enable the public TestFlight link (external groups only) |
| `--feedback-enabled` | `false` | Enable tester feedback (external groups only) |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# External group with public link
asc testflight groups create --app-id 6450406024 --name "External Beta" --public-link-enabled --pretty

# Internal group (team members only)
asc testflight groups create --app-id 6450406024 --name "Company Team" --internal --pretty
```

**JSON output:** same shape as `list`, with one group.

---

### List Beta Testers

```bash
asc testflight testers list --beta-group-id <GROUP_ID> [--limit N]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--beta-group-id` | *(required)* | Beta group ID |
| `--limit` | *(optional)* | Maximum testers to return |
| `--output` | `json` | Output format |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc testflight testers list --beta-group-id g-abc123 --pretty
```

**JSON output:**

```json
{
  "data": [
    {
      "id": "t-xyz789",
      "groupId": "g-abc123",
      "email": "jane@example.com",
      "firstName": "Jane",
      "lastName": "Doe",
      "inviteType": "EMAIL",
      "affordances": {
        "listSiblings": "asc testflight testers list --beta-group-id g-abc123",
        "remove": "asc testflight testers remove --beta-group-id g-abc123 --tester-id t-xyz789"
      }
    }
  ]
}
```

---

### Add Beta Tester

Invite a new tester by email and immediately add them to the group.

```bash
asc testflight testers add --beta-group-id <GROUP_ID> --email <EMAIL> \
  [--first-name <NAME>] [--last-name <NAME>]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--beta-group-id` | *(required)* | Beta group ID |
| `--email` | *(required)* | Tester email address |
| `--first-name` | *(optional)* | Tester first name |
| `--last-name` | *(optional)* | Tester last name |

**Example:**

```bash
asc testflight testers add \
  --beta-group-id g-abc123 \
  --email jane@example.com \
  --first-name Jane \
  --last-name Doe \
  --pretty
```

**JSON output:** same shape as `list`, with one tester.

---

### Remove Beta Tester

Remove a tester from a group (does not delete their account).

```bash
asc testflight testers remove --beta-group-id <GROUP_ID> --tester-id <TESTER_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--beta-group-id` | *(required)* | Beta group ID |
| `--tester-id` | *(required)* | Tester ID (from `testers list`) |

**Example:**

```bash
asc testflight testers remove --beta-group-id g-abc123 --tester-id t-xyz789
```

**Output:**

```
Removed tester t-xyz789 from group g-abc123
```

---

### Import Beta Testers from CSV

Bulk-add testers from a CSV file. The file must have a header row with columns `email,firstName,lastName`.

```bash
asc testflight testers import --beta-group-id <GROUP_ID> --file <PATH>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--beta-group-id` | *(required)* | Beta group ID |
| `--file` | *(required)* | Path to CSV file |
| `--output` | `json` | Output format |
| `--pretty` | `false` | Pretty-print JSON |

**CSV format (`testers.csv`):**

```
email,firstName,lastName
jane@example.com,Jane,Doe
john@example.com,John,Smith
anon@example.com,,
```

**Example:**

```bash
asc testflight testers import \
  --beta-group-id g-abc123 \
  --file testers.csv \
  --pretty
```

**Output:** JSON array of all successfully created testers (same shape as `list`).

---

### Export Beta Testers to CSV

Export all testers in a group to CSV format (suitable for re-importing to another group).

```bash
asc testflight testers export --beta-group-id <GROUP_ID> [--limit N]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--beta-group-id` | *(required)* | Beta group ID |
| `--limit` | *(optional)* | Maximum testers to export |

**Example:**

```bash
asc testflight testers export --beta-group-id g-abc123 > testers.csv
```

**Output:**

```csv
email,firstName,lastName
jane@example.com,Jane,Doe
john@example.com,John,Smith
```

---

## Typical Workflow

```bash
# 1. Find your app's beta groups
asc testflight groups list --app-id 6450406024 --pretty

# 2. List testers in a group (use affordance from step 1)
asc testflight testers list --beta-group-id g-abc123 --pretty

# 3. Add a new tester
asc testflight testers add \
  --beta-group-id g-abc123 \
  --email newbeta@example.com \
  --first-name Alex

# 4. Bulk add testers from CSV
asc testflight testers import --beta-group-id g-abc123 --file new-testers.csv

# 5. Export to seed a new group
asc testflight testers export --beta-group-id g-abc123 > testers.csv
asc testflight testers import --beta-group-id g-new456 --file testers.csv

# 6. Remove a specific tester (use affordance "remove" from tester JSON)
asc testflight testers remove --beta-group-id g-abc123 --tester-id t-xyz789
```

---

## Architecture

```
ASCCommand layer
  BetaGroupsList   → formatAgentItems → {"data":[{...appId..., "affordances":{...}}]}
  BetaTestersList  → formatAgentItems → {"data":[{...groupId..., "affordances":{...}}]}
  BetaTestersAdd   → formatAgentItems → {"data":[{...}]}
  BetaTestersRemove → plain string confirmation
  BetaTestersImport → reads CSV file, loops addBetaTester, formatAgentItems
  BetaTestersExport → listBetaTesters, formats CSV
        │
        ▼ TestFlightRepository (@Mockable)
        │  listBetaGroups(appId:limit:)
        │  listBetaTesters(groupId:limit:)
        │  addBetaTester(groupId:email:firstName:lastName:)
        │  removeBetaTester(groupId:testerId:)
        ▼
Infrastructure layer
  SDKTestFlightRepository
  GET  /v1/betaGroups             → injects appId from relationships
  GET  /v1/betaTesters?filter[betaGroups]=<id>  → injects groupId
  POST /v1/betaTesters            → create + assign to group
  DELETE /v1/betaGroups/{id}/relationships/betaTesters
```

---

## Domain Models

### BetaGroup

```swift
public struct BetaGroup: Sendable, Codable, Equatable, Identifiable, AffordanceProviding {
    public let id: String
    public let appId: String          // parent app ID (injected by infrastructure)
    public let name: String
    public let isInternalGroup: Bool
    public let publicLinkEnabled: Bool
    public let createdDate: Date?     // nil-omitted in JSON output
}
```

**Affordances:** `exportTesters` · `importTesters` · `listTesters`

### BetaTester

```swift
public struct BetaTester: Sendable, Codable, Equatable, Identifiable, AffordanceProviding {
    public let id: String
    public let groupId: String        // parent group ID (injected by infrastructure)
    public let firstName: String?     // nil-omitted in JSON output
    public let lastName: String?      // nil-omitted in JSON output
    public let email: String?         // nil-omitted in JSON output
    public let inviteType: InviteType?  // nil-omitted in JSON output

    public var displayName: String    // "Jane Doe" or email or id
}
```

**Affordances:** `listSiblings` · `remove`

### TestFlightRepository

```swift
@Mockable
public protocol TestFlightRepository: Sendable {
    func listBetaGroups(appId: String?, limit: Int?) async throws -> PaginatedResponse<BetaGroup>
    func listBetaTesters(groupId: String, limit: Int?) async throws -> PaginatedResponse<BetaTester>
    func addBetaTester(groupId: String, email: String, firstName: String?, lastName: String?) async throws -> BetaTester
    func removeBetaTester(groupId: String, testerId: String) async throws
}
```

---

## File Map

**Sources:**

```
Sources/Domain/Apps/TestFlight/
  ├── BetaGroup.swift               – struct + AffordanceProviding
  ├── BetaTester.swift              – struct + custom Codable + AffordanceProviding
  └── TestFlightRepository.swift    – @Mockable protocol

Sources/Infrastructure/Apps/TestFlight/
  └── OpenAPITestFlightRepository.swift  – SDKTestFlightRepository (implements protocol)

Sources/ASCCommand/Commands/TestFlight/
  └── TestFlightCommand.swift       – all 6 subcommands
```

**Wiring:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | `makeTestFlightRepository()` (existing) |
| `Sources/ASCCommand/ClientProvider.swift` | `makeTestFlightRepository()` (existing) |
| `Sources/ASCCommand/ASC.swift` | `TestFlightCommand` registered (existing) |

**Tests:**

```
Tests/DomainTests/Apps/TestFlight/
  ├── BetaGroupTests.swift         – parent ID + affordance tests
  └── BetaTesterTests.swift        – parent ID + displayName + affordance tests

Tests/DomainTests/Apps/
  └── AffordancesTests.swift       – BetaGroup + BetaTester affordance assertions

Tests/DomainTests/TestHelpers/
  └── MockRepositoryFactory.swift  – makeBetaGroup(appId:) + makeBetaTester(groupId:)

Tests/InfrastructureTests/Apps/TestFlight/
  └── SDKTestFlightRepositoryTests.swift  – parent ID injection + new method tests

Tests/ASCCommandTests/Commands/TestFlight/
  └── TestFlightCommandTests.swift  – all 6 command output tests
```

---

## API Reference

| Operation | ASC API Endpoint | SDK Call |
|-----------|-----------------|----------|
| List groups | `GET /v1/betaGroups` | `APIEndpoint.v1.betaGroups.get(parameters:)` |
| List testers | `GET /v1/betaTesters?filter[betaGroups]=id` | `APIEndpoint.v1.betaTesters.get(parameters:)` |
| Add tester | `POST /v1/betaTesters` (with `betaGroups` relationship) | `APIEndpoint.v1.betaTesters.post(_:)` |
| Remove tester | `DELETE /v1/betaGroups/{id}/relationships/betaTesters` | `APIEndpoint.v1.betaGroups.id(_:).relationships.betaTesters.delete(_:)` |

---

## Testing

```swift
@Test func `testers list includes affordances and groupId in json output`() async throws {
    let mockRepo = MockTestFlightRepository()
    given(mockRepo).listBetaTesters(groupId: .any, limit: .any).willReturn(
        PaginatedResponse(data: [
            BetaTester(id: "t-1", groupId: "g-1", firstName: "Jane", lastName: "Doe",
                       email: "jane@example.com", inviteType: .email)
        ], nextCursor: nil)
    )

    let cmd = try BetaTestersList.parse(["--beta-group-id", "g-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output.contains("\"remove\" : \"asc testflight testers remove --beta-group-id g-1 --tester-id t-1\""))
}
```

Run the full suite:

```bash
swift test --filter 'BetaGroup\|BetaTester\|TestFlight'
```

---

## Extending

**Add a `testers update` command** (change firstName/lastName):

```swift
// Repository
func updateBetaTester(testerId: String, firstName: String?, lastName: String?) async throws -> BetaTester

// Infrastructure: PATCH /v1/betaTesters/{id}

// Command: BetaTestersUpdate
```

**Add public link management** (enable/disable group public link):

```swift
func updateBetaGroup(groupId: String, publicLinkEnabled: Bool) async throws -> BetaGroup
```
