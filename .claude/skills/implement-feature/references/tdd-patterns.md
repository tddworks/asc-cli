# TDD Test Patterns (Chicago School)

We follow **Chicago school TDD** (state-based testing):

| Chicago School (We Use This)          | London School (Avoid)                    |
|---------------------------------------|------------------------------------------|
| Test state changes and return values  | Test interactions between objects        |
| Mocks stub data, not verify calls     | Mocks verify method calls were made      |
| Focus on "what" (outcomes)            | Focus on "how" (behavior)                |
| Design emerges from tests             | Design upfront, tests verify design      |

## Naming tests

A test name is the behaviour it guards, as one sentence in a backtick
identifier:

```
should <outcome the person / agent / REST client observes> [when <App Store Connect situation>]
```

- **Say what the observer gets, not which code runs.** The actors are the
  person running `asc`, an agent reading the JSON and its affordances, a REST
  client of `asc web-server`, and App Store Connect itself. The name never
  holds a method or type name (`execute`, `getDeclaration`, `SDKAppRepository`)
  or a mechanism verb (`returns`, `calls`, `passes`, `forwards`, `maps`,
  `parses`, `injects`). JSON keys and CLI flags are fine — they are the public
  schema the observer reads.
- **The `when` is a fact about the world**, not a code path: "when the version
  is waiting for review", not "when `state` is `.waitingForReview`"; "when App
  Store Connect has no declaration", not "when the repo throws".
- **Pair every happy path with its counterpart.** "should offer submit for
  review when the version is editable" travels with "should not offer submit
  for review when the version is live".
- **The body follows the sentence**: arrange the situation (stub the
  repository or `StubAPIClient`), do one thing through the public surface,
  assert the resulting state (no `verify()`).

| Mechanism-shaped (avoid) | Business-shaped |
|---|---|
| `execute json output` | `should list each app with its name, bundle id and next commands` |
| `execute json output omits sku when nil` | `should leave sku out when the app has none` |
| `getDeclaration injects appInfoId` | `should tie the age rating to the app info it was read from` |
| `getDeclaration maps intensity attributes` | `should show how often violence and profanity appear` |
| `delete localization calls repo with localization id` | (delete — interaction test; assert what `delete` prints instead) |
| `updates with only name passes nil description to repo` | `should keep the description when only the name is updated` |
| `readyForSale version is live` | `should be live when the version is ready for sale` |
| `throws for invalid eligibility` | `should refuse an eligibility App Store Connect doesn't accept` |

Older tests predate this rule. Rename one to this shape when you change it
or its file; don't sweep files you aren't otherwise changing.

## Command Test Rules (Phase 3)

**Three mandatory rules for every command test:**

1. **Behavior-focused name** — `should …` per [Naming tests](#naming-tests)
2. **Always assert** — every test must have `#expect(output == "...")` or equivalent; tests without assertions are not tests
3. **Exact JSON assertion** — assert the complete output string, never `output.contains(...)`

**When to delete vs convert an interaction test:**

- **Delete** if the scenario is identical to the primary test (just a different ID/value) — behaviour already proven
- **Convert** if the scenario is genuinely different (different platform, different field set, different locale) — rewrite as a state test with `#expect(output == "...")`

**URL encoding gotcha:** Swift's `JSONSerialization` escapes forward slashes as `\/` by default. In expected strings, write `\\/` for each `/` in URLs:

```swift
// In exact multi-line assertion:
"""
"marketingUrl" : "https:\\/\\/example.com",
"""
```

## Given-When-Then Structure

```swift
@Test func `should not offer submit for review when the version is live`() {
    // Given
    let version = MockRepositoryFactory.makeVersion(id: "v-1", state: .readyForSale)

    // When
    let affordances = version.affordances

    // Then
    #expect(affordances["submitForReview"] == nil)
}
```

## Swift Testing Framework

Use `@Test` and `@Suite` with backtick test names:

```swift
import Testing
@testable import Domain

@Suite
struct AppStoreVersionTests {
    @Test func `should be live and locked when the version is ready for sale`() {
        let version = MockRepositoryFactory.makeVersion(state: .readyForSale)
        #expect(version.isLive == true)
        #expect(version.isEditable == false)
    }

    @Test func `should be editable when the version is being prepared for submission`() {
        let version = MockRepositoryFactory.makeVersion(state: .prepareForSubmission)
        #expect(version.isEditable == true)
    }
}
```

## MockRepositoryFactory (Always Use This)

Never construct domain models inline in tests. Use the shared factory:

```swift
// Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift
// All params have sensible defaults

MockRepositoryFactory.makeVersion(id: "v1", appId: "app-1", state: .readyForSale)
MockRepositoryFactory.makeLocalization(id: "loc-1", versionId: "v-1")
MockRepositoryFactory.makeScreenshotSet(id: "set-1", localizationId: "loc-1")
MockRepositoryFactory.makeScreenshot(id: "img-1", setId: "set-1")
MockRepositoryFactory.makeApp(id: "app-1", name: "My App")
```

Add a new `make*` method when adding a new domain model.

## Affordance Tests

Add to `Tests/DomainTests/Apps/AffordancesTests.swift` (or a domain-specific file):

```swift
@Test func `should point to the model's children and siblings`() {
    let model = MockRepositoryFactory.makeNewModel(id: "m1", parentId: "p1")
    #expect(model.affordances["listChildren"] == "asc children list --parent-id m1")
    #expect(model.affordances["listParents"] == "asc parents list --grandparent-id p1")
}

@Test func `should offer the action only when the model is active`() {
    let active  = MockRepositoryFactory.makeNewModel(state: .active)
    let expired = MockRepositoryFactory.makeNewModel(state: .expired)
    #expect(active.affordances["doAction"] == "asc models do-action --model-id \(active.id)")
    #expect(expired.affordances["doAction"] == nil)
}
```

## Mocking with @Mockable (Chicago Style)

Stub what the repository answers, run the real command, assert what it prints.
Never assert on the mock itself — a test that calls the mock and checks its
answer proves nothing.

```swift
@Suite
struct VersionsListTests {
    @Test func `should list the app's versions with their state`() async throws {
        // Given - STUB what App Store Connect has
        let mockRepo = MockVersionRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            MockRepositoryFactory.makeVersion(id: "v1", appId: "app-1", state: .readyForSale)
        ])

        // When - run the real command
        let cmd = try VersionsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        // Then - verify STATE (the exact output), not that methods were called
        #expect(output == """
        { ... exact JSON ... }
        """)
        // ❌ AVOID: verify(mockRepo).listVersions(appId: .any).called(1)  // London school
    }
}
```

## Infrastructure Adapter Tests

Stub the SDK response with `StubAPIClient`, read through the real `SDK*Repository`,
assert the domain value:

```swift
@Suite
struct SDKAgeRatingDeclarationRepositoryTests {
    @Test func `should tie the age rating to the app info it was read from`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AgeRatingDeclarationResponse(
            data: AgeRatingDeclaration(type: .ageRatingDeclarations, id: "decl-1"),
            links: .init(this: "")
        ))
        let repo = SDKAgeRatingDeclarationRepository(client: stub)

        let result = try await repo.getDeclaration(appInfoId: "info-42")

        #expect(result.appInfoId == "info-42")
    }
}
```

Key things to test:
- **Parent ID** — the ASC API doesn't return it, the mapper sets it from the request.
- **Every SDK enum case** — when a domain enum mirrors an SDK enum, a case the
  domain lacks maps to `nil` without an error. Pin each case Apple sends
  (`should show a Korea override of twelve plus`), and re-check after every SDK bump.

## Domain Model State Tests

```swift
@Suite
struct AppStoreVersionStateTests {
    @Test func `should use App Store Connect's own state names`() {
        #expect(AppStoreVersionState.readyForSale.rawValue == "READY_FOR_SALE")
        #expect(AppStoreVersionState.prepareForSubmission.rawValue == "PREPARE_FOR_SUBMISSION")
    }

    @Test func `should be live and not pending when ready for sale`() {
        #expect(AppStoreVersionState.readyForSale.isLive == true)
        #expect(AppStoreVersionState.readyForSale.isEditable == false)
        #expect(AppStoreVersionState.readyForSale.isPending == false)
    }
}
```

## Test Organization

```
Tests/
├── DomainTests/
│   ├── Apps/
│   │   ├── AppTests.swift
│   │   ├── AppStoreVersionTests.swift
│   │   ├── AppStoreVersionStateTests.swift
│   │   ├── AppRepositoryTests.swift
│   │   └── AffordancesTests.swift       ← all affordance tests
│   ├── Screenshots/
│   │   ├── AppStoreVersionLocalizationTests.swift
│   │   ├── AppScreenshotSetTests.swift
│   │   ├── AppScreenshotTests.swift
│   │   └── ScreenshotRepositoryTests.swift
│   ├── Builds/
│   ├── Auth/
│   ├── Shared/
│   └── TestHelpers/
│       └── MockRepositoryFactory.swift  ← shared factory
├── InfrastructureTests/
│   └── Auth/
└── ASCCommandTests/
    └── OutputFormatterTests.swift
```

## Running Tests

```bash
swift test                                              # All tests
swift test --filter DomainTests                        # Domain only
swift test --filter "AppStoreVersionTests"             # One suite
```

## Red-Green-Refactor

```
1. RED    - Write failing test asserting expected STATE
2. GREEN  - Write minimal code to pass
3. REFACTOR - Improve while keeping green
```
