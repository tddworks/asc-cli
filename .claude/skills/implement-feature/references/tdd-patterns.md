# TDD Test Patterns (Chicago School)

We follow **Chicago school TDD** (state-based testing):

| Chicago School (We Use This)          | London School (Avoid)                    |
|---------------------------------------|------------------------------------------|
| Test state changes and return values  | Test interactions between objects        |
| Mocks stub data, not verify calls     | Mocks verify method calls were made      |
| Focus on "what" (outcomes)            | Focus on "how" (behavior)                |
| Design emerges from tests             | Design upfront, tests verify design      |

## Swift Testing Framework

Use `@Test` and `@Suite` with backtick test names:

```swift
import Testing
@testable import Domain

@Suite
struct AppStoreVersionTests {
    @Test func `readyForSale version is live`() {
        let version = MockRepositoryFactory.makeVersion(state: .readyForSale)
        #expect(version.isLive == true)
        #expect(version.isEditable == false)
    }

    @Test func `prepareForSubmission version is editable`() {
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
@Test func `new model affordances include list children command`() {
    let model = MockRepositoryFactory.makeNewModel(id: "m1", parentId: "p1")
    #expect(model.affordances["listChildren"] == "asc children list --parent-id m1")
    #expect(model.affordances["listParents"] == "asc parents list --grandparent-id p1")
}

@Test func `action affordance only appears when state allows it`() {
    let active  = MockRepositoryFactory.makeNewModel(state: .active)
    let expired = MockRepositoryFactory.makeNewModel(state: .expired)
    #expect(active.affordances["doAction"] != nil)
    #expect(expired.affordances["doAction"] == nil)
}
```

## Mocking with @Mockable (Chicago Style)

```swift
// Domain: declare protocol
@Mockable
public protocol AppRepository: Sendable {
    func listVersions(appId: String) async throws -> [AppStoreVersion]
}

// Test: stub return values
@Suite
struct AppRepositoryTests {
    @Test func `list versions returns versions for app`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listVersions(appId: .any).willReturn([
            MockRepositoryFactory.makeVersion(id: "v1", appId: "app-1")
        ])

        let versions = try await mockRepo.listVersions(appId: "app-1")

        #expect(versions.count == 1)
        #expect(versions[0].appId == "app-1")
        // ❌ AVOID: verify(mockRepo).listVersions(appId: .any).called(1)
    }
}
```

## Infrastructure Adapter Tests

Test field mapping from SDK type to domain type:

```swift
@Suite
struct SDKScreenshotRepositoryTests {
    @Test func `listLocalizations injects versionId into each localization`() async throws {
        let mockProvider = MockAPIProvider()
        given(mockProvider).request(any()).willReturn(makeLocalizationsFixture())
        let repo = SDKScreenshotRepository(provider: mockProvider)

        let locs = try await repo.listLocalizations(versionId: "v-42")

        #expect(locs.allSatisfy { $0.versionId == "v-42" })
    }
}
```

Key thing to test: parent ID injection (since ASC API doesn't include parent IDs in responses).

## Domain Model State Tests

```swift
@Suite
struct AppStoreVersionStateTests {
    @Test func `raw values match App Store Connect API strings`() {
        #expect(AppStoreVersionState.readyForSale.rawValue == "READY_FOR_SALE")
        #expect(AppStoreVersionState.prepareForSubmission.rawValue == "PREPARE_FOR_SUBMISSION")
    }

    @Test func `readyForSale is live`() {
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