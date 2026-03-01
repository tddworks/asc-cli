# Version Review Detail Feature

Manage App Store review information for a version — contact details and demo account credentials that the App Review team needs. Setting this before submission prevents a `reviewContactCheck` warning in `asc versions check-readiness`.

## CLI Usage

### Get Review Detail

```bash
asc version-review-detail get --version-id <VERSION_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--version-id` | *(required)* | App Store version ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc version-review-detail get --version-id 74ed4466-8dc4-4ec7-b2ce-3c1bbe620964 --pretty
```

**JSON output (contact info set):**

```json
{
  "data": [
    {
      "affordances": {
        "getReviewDetail": "asc version-review-detail get --version-id 74ed4466-...",
        "updateReviewDetail": "asc version-review-detail update --version-id 74ed4466-..."
      },
      "contactEmail": "dev@example.com",
      "contactFirstName": "Jane",
      "contactLastName": "Smith",
      "contactPhone": "+1-555-0100",
      "demoAccountRequired": false,
      "id": "rd-abc123",
      "versionId": "74ed4466-..."
    }
  ]
}
```

**JSON output (never set — empty record):**

```json
{
  "data": [
    {
      "affordances": {
        "getReviewDetail": "asc version-review-detail get --version-id 74ed4466-...",
        "updateReviewDetail": "asc version-review-detail update --version-id 74ed4466-..."
      },
      "demoAccountRequired": false,
      "id": "",
      "versionId": "74ed4466-..."
    }
  ]
}
```

**Note:** When review info has never been submitted, the API returns `{"data": null}`. The CLI normalises this to an empty record with `id: ""`. Nil optional fields (contactFirstName, contactEmail, etc.) are omitted from JSON output.

**Table output:**

```
ID        Contact Email      Contact Phone   Demo Required
--------  -----------------  --------------  -------------
rd-abc123  dev@example.com   +1-555-0100     no
```

---

### Update Review Detail

```bash
asc version-review-detail update --version-id <VERSION_ID> [flags]
```

**Upsert semantics:** GET the current record first. If none exists (empty `id`), POST a new one. If one exists, PATCH it with the supplied fields. Only provided flags are sent — unspecified fields are left unchanged on an existing record.

**Options:**

| Flag | Type | Description |
|------|------|-------------|
| `--version-id` | String *(required)* | App Store version ID |
| `--contact-first-name` | String | Reviewer contact first name |
| `--contact-last-name` | String | Reviewer contact last name |
| `--contact-phone` | String | Reviewer contact phone number |
| `--contact-email` | String | Reviewer contact email address |
| `--demo-account-required` | Bool | Whether a demo account is required (`true`/`false`) |
| `--demo-account-name` | String | Demo account username |
| `--demo-account-password` | String | Demo account password |
| `--notes` | String | Additional notes for the App Review team |
| `--output` | String | Output format: `json`, `table`, `markdown` |
| `--pretty` | Flag | Pretty-print JSON |

**Examples:**

```bash
# Set contact info (minimum to pass reviewContactCheck)
asc version-review-detail update --version-id <id> \
  --contact-first-name Jane \
  --contact-last-name Smith \
  --contact-email dev@example.com \
  --contact-phone "+1-555-0100"

# With demo account
asc version-review-detail update --version-id <id> \
  --contact-email dev@example.com \
  --contact-phone "+1-555-0100" \
  --demo-account-required true \
  --demo-account-name demo_user \
  --demo-account-password "secret" \
  --notes "Use the staging environment at https://staging.example.com"
```

**JSON output:**

```json
{
  "data": [
    {
      "affordances": {
        "getReviewDetail": "asc version-review-detail get --version-id 74ed4466-...",
        "updateReviewDetail": "asc version-review-detail update --version-id 74ed4466-..."
      },
      "contactEmail": "dev@example.com",
      "contactFirstName": "Jane",
      "contactLastName": "Smith",
      "contactPhone": "+1-555-0100",
      "demoAccountRequired": false,
      "id": "rd-abc123",
      "versionId": "74ed4466-..."
    }
  ]
}
```

---

## Typical Workflow

```bash
# 1. Find the version in PREPARE_FOR_SUBMISSION state
asc versions list --app-id <APP_ID> --output table

# 2. Check what review info is currently set
asc version-review-detail get --version-id <VERSION_ID> --pretty

# 3. Set contact info (required before submission)
asc version-review-detail update --version-id <VERSION_ID> \
  --contact-first-name Jane \
  --contact-email dev@example.com \
  --contact-phone "+1-555-0100"

# 4. If the app needs a demo account
asc version-review-detail update --version-id <VERSION_ID> \
  --demo-account-required true \
  --demo-account-name demo_user \
  --demo-account-password "secret" \
  --notes "Tap 'Get Started' then log in with the demo credentials"

# 5. Run readiness check — reviewContactCheck should now pass
asc versions check-readiness --version-id <VERSION_ID> --pretty

# 6. Submit
asc versions submit --version-id <VERSION_ID>
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  ASCCommand                                                         │
│  VersionReviewDetailCommand (version-review-detail)                 │
│    ├── VersionReviewDetailGet    (get --version-id)                 │
│    └── VersionReviewDetailUpdate (update --version-id [flags])      │
│          upsert = GET → POST (new) | PATCH (existing)              │
└───────────────────────┬─────────────────────────────────────────────┘
                        │ uses
┌───────────────────────▼─────────────────────────────────────────────┐
│  Domain/Apps/Versions/                                              │
│  AppStoreReviewDetail — id, versionId (parent),                    │
│                          contactFirstName?, contactLastName?,       │
│                          contactPhone?, contactEmail?,              │
│                          demoAccountRequired, demoAccountName?,     │
│                          demoAccountPassword?, notes?               │
│    hasContact:           contactEmail != nil && contactPhone != nil │
│    demoAccountConfigured: !required || (name != nil && pw != nil)  │
│    affordances:          getReviewDetail, updateReviewDetail        │
│                                                                     │
│  ReviewDetailUpdate — all fields optional, nil = leave unchanged   │
│                                                                     │
│  ReviewDetailRepository (protocol, @Mockable)                      │
│    getReviewDetail(versionId:) → AppStoreReviewDetail              │
│    upsertReviewDetail(versionId:update:) → AppStoreReviewDetail    │
└───────────────────────┬─────────────────────────────────────────────┘
                        │ implements
┌───────────────────────▼─────────────────────────────────────────────┐
│  Infrastructure/Apps/Versions/                                      │
│  SDKReviewDetailRepository                                          │
│    getReviewDetail   → GET  /v1/appStoreVersions/{id}/             │
│                              appStoreReviewDetail                  │
│                       returns empty (id:"") on 404/null            │
│    upsertReviewDetail → GET current                                 │
│                       → POST /v1/appStoreReviewDetails   (if new)  │
│                       → PATCH /v1/appStoreReviewDetails/{id} (exists)│
└─────────────────────────────────────────────────────────────────────┘
```

**Dependency direction:** `ASCCommand → Infrastructure → Domain`

---

## Domain Models

### `AppStoreReviewDetail`

```swift
public struct AppStoreReviewDetail: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let versionId: String         // parent version ID — always injected
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountRequired: Bool
    public let demoAccountName: String?
    public let demoAccountPassword: String?
    public let notes: String?

    // Computed
    public var hasContact: Bool { contactEmail != nil && contactPhone != nil }
    public var demoAccountConfigured: Bool {
        !demoAccountRequired || (demoAccountName != nil && demoAccountPassword != nil)
    }
}
```

Custom `Codable` uses `encodeIfPresent` — nil optional fields are omitted from JSON output.

**Affordances:**
```
"getReviewDetail"    → asc version-review-detail get --version-id <versionId>    (always)
"updateReviewDetail" → asc version-review-detail update --version-id <versionId> (always)
```

### `ReviewDetailUpdate`

Parameters struct used by the CLI command and passed to the repository. All fields optional.

```swift
public struct ReviewDetailUpdate: Sendable, Equatable {
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountRequired: Bool?
    public let demoAccountName: String?
    public let demoAccountPassword: String?
    public let notes: String?
}
```

### `ReviewDetailRepository`

```swift
@Mockable
public protocol ReviewDetailRepository: Sendable {
    func getReviewDetail(versionId: String) async throws -> AppStoreReviewDetail
    func upsertReviewDetail(versionId: String, update: ReviewDetailUpdate) async throws -> AppStoreReviewDetail
}
```

---

## File Map

```
Sources/
├── Domain/Apps/Versions/
│   ├── AppStoreReviewDetail.swift        # model + AffordanceProviding
│   ├── ReviewDetailUpdate.swift          # upsert parameters struct
│   └── ReviewDetailRepository.swift      # @Mockable protocol
│
├── Infrastructure/Apps/Versions/
│   └── SDKReviewDetailRepository.swift   # GET / upsert (POST or PATCH)
│
└── ASCCommand/Commands/VersionReviewDetail/
    └── VersionReviewDetailCommand.swift  # get + update subcommands

Tests/
├── DomainTests/Apps/Versions/
│   └── AppStoreReviewDetailTests.swift   # hasContact, demoAccountConfigured,
│                                         # affordances, notes Codable
├── DomainTests/Apps/
│   └── AffordancesTests.swift            # getReviewDetail on AppStoreVersion
├── InfrastructureTests/Apps/Versions/
│   └── SDKReviewDetailRepositoryTests.swift  # get + upsert (create + patch)
└── ASCCommandTests/Commands/VersionReviewDetail/
    └── VersionReviewDetailTests.swift    # get + update JSON assertions
```

**Modified wiring files:**

| File | Change |
|------|--------|
| `Sources/Domain/Apps/Versions/AppStoreVersion.swift` | Added `getReviewDetail` affordance |
| `Sources/ASCCommand/ASC.swift` | Registered `VersionReviewDetailCommand` |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | Added `notes:` to `makeReviewDetail` |
| `Tests/ASCCommandTests/Commands/Versions/VersionsListTests.swift` | Updated expected JSON: added `getReviewDetail` affordance |
| `Tests/ASCCommandTests/Commands/Versions/VersionsCreateTests.swift` | Updated expected JSON: added `getReviewDetail` affordance |

---

## App Store Connect API Reference

| Endpoint | SDK call | Repository method |
|----------|----------|-------------------|
| `GET /v1/appStoreVersions/{id}/appStoreReviewDetail` | `.appStoreVersions.id(id).appStoreReviewDetail.get()` | `getReviewDetail(versionId:)` |
| `POST /v1/appStoreReviewDetails` | `.appStoreReviewDetails.post(body)` | `upsertReviewDetail` — create path |
| `PATCH /v1/appStoreReviewDetails/{id}` | `.appStoreReviewDetails.id(id).patch(body)` | `upsertReviewDetail` — update path |

**Key detail:** The GET endpoint returns `{"data": null}` (not a 404) when review info has never been submitted. The infrastructure layer catches any error and returns `AppStoreReviewDetail(id: "", versionId: versionId)`. The upsert method uses `id.isEmpty` to decide POST vs PATCH.

---

## Testing

```swift
// Domain: affordances navigate to get and update commands
@Test func `review detail affordances include get and update commands`() {
    let detail = MockRepositoryFactory.makeReviewDetail(id: "rd-1", versionId: "v-42")
    #expect(detail.affordances["getReviewDetail"] == "asc version-review-detail get --version-id v-42")
    #expect(detail.affordances["updateReviewDetail"] == "asc version-review-detail update --version-id v-42")
}

// Infrastructure: upsert patches an existing record
@Test func `upsertReviewDetail patches existing record`() async throws {
    let stub = SequencedStubAPIClient()
    stub.enqueue(/* GET response with id: "rd-existing" */)
    stub.enqueue(/* PATCH response with updated fields */)
    let repo = SDKReviewDetailRepository(client: stub)
    let result = try await repo.upsertReviewDetail(versionId: "v-2", update: .init(notes: "Use staging"))
    #expect(result.notes == "Use staging")
}

// Command: exact JSON assertion verifies fields, affordances, and nil omission
@Test func `get review detail returns affordances and all fields`() async throws {
    let mockRepo = MockReviewDetailRepository()
    given(mockRepo).getReviewDetail(versionId: .any).willReturn(
        AppStoreReviewDetail(id: "rd-1", versionId: "v-1", contactEmail: "jane@example.com", ...)
    )
    let cmd = try VersionReviewDetailGet.parse(["--version-id", "v-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)
    #expect(output == "{ ... exact JSON ... }")
}
```

Run:
```bash
swift test --filter 'VersionReviewDetail'
swift test  # full suite
```

---

## Extending the Feature

### Promote `reviewContactCheck` to MUST FIX

Currently a SHOULD FIX warning in `asc versions check-readiness`. To make it block submission:

```swift
// In VersionsCheckReadiness.swift — change isReadyToSubmit calculation:
let isReadyToSubmit = stateCheck.pass && buildCheck.pass
    && pricingCheck.pass && localizationCheck.pass
    && reviewContactCheck.pass  // add this line
```

### Expose `updateReviewDetail` affordance from `VersionReadiness`

```swift
// In VersionReadiness.affordances:
cmds["updateReviewDetail"] = "asc version-review-detail update --version-id \(id)"
```

### Use `getReviewDetail` affordance in agent pipelines

```bash
# Follow affordances from version list to review detail
VERSION=$(asc versions list --app-id "$APP_ID" | jq -r '.data[0]')
REVIEW_CMD=$(echo "$VERSION" | jq -r '.affordances.getReviewDetail')
eval "$REVIEW_CMD --pretty"
```
