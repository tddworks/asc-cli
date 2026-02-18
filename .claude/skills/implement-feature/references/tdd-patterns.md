# TDD Test Patterns (Chicago School)

We follow **Chicago school TDD** (state-based testing):

| Chicago School (We Use This)          | London School (Avoid)                    |
|---------------------------------------|------------------------------------------|
| Test state changes and return values  | Test interactions between objects        |
| Mocks stub data, not verify calls     | Mocks verify method calls were made      |
| Focus on "what" (outcomes)            | Focus on "how" (behavior)                |
| Design emerges from tests             | Design upfront, tests verify design      |

## Swift Testing Framework

Use `@Test` and `@Suite` instead of XCTest:

```swift
import Testing
import Foundation
@testable import Domain

@Suite
struct BuildTests {
    @Test func `valid processing state is ready`() {
        let build = Build(id: "1", version: "1.0", processingState: .valid, uploadedDate: .now)
        #expect(build.isReady == true)
    }

    @Test func `failed processing state has failed`() {
        let build = Build(id: "1", version: "1.0", processingState: .failed, uploadedDate: .now)
        #expect(build.isReady == false)
        #expect(build.processingState.hasFailed == true)
    }
}
```

## Given-When-Then Structure

```swift
@Test func `app provides short identifier from bundle ID`() {
    // Given
    let app = App(id: "123", name: "My App", bundleId: "com.example.myapp", sku: nil, primaryLocale: "en-US")

    // When
    let identifier = app.shortIdentifier

    // Then
    #expect(identifier == "myapp")
}
```

## Mocking with @Mockable (Chicago Style)

Define mockable protocols for all repository boundaries:

```swift
import Mockable

@Mockable
public protocol AppRepository: Sendable {
    func fetchApps(limit: Int?) async throws -> [App]
}

@Mockable
public protocol BuildRepository: Sendable {
    func fetchBuilds(appId: String?, limit: Int?) async throws -> [Build]
}
```

**Chicago school mock usage** - stub return values, verify resulting state:

```swift
@Suite
struct AppRepositoryTests {
    @Test func `fetchApps returns mapped domain models`() async throws {
        // Given - STUB repository to return data
        let mockRepo = MockAppRepository()
        given(mockRepo).fetchApps(limit: .any).willReturn([
            App(id: "123", name: "My App", bundleId: "com.example.app", sku: nil, primaryLocale: "en-US")
        ])

        // When
        let apps = try await mockRepo.fetchApps(limit: nil)

        // Then - verify STATE, not that methods were called
        #expect(apps.count == 1)
        #expect(apps[0].bundleId == "com.example.app")
        // ❌ AVOID: verify(mockRepo).fetchApps(limit: .any).called(1)  // London school
    }
}
```

**Key principle**: Use `given().willReturn()` to stub data. Avoid `verify().called()` for interactions.

## Infrastructure Adapter Tests

Test that the adapter correctly maps SDK responses to domain models:

```swift
@Suite
struct OpenAPIAppRepositoryTests {
    @Test func `fetchApps maps SDK response fields to domain App`() async throws {
        // Given - fixture representing SDK response
        let mockProvider = MockAPIProvider()
        given(mockProvider).request(any()).willReturn(makeAppsFixture())
        let repo = OpenAPIAppRepository(provider: mockProvider)

        // When
        let apps = try await repo.fetchApps(limit: nil)

        // Then - verify field mapping
        #expect(apps.count == 2)
        #expect(apps[0].name == "My App")
        #expect(apps[0].bundleId == "com.example.app")
    }

    @Test func `fetchApps throws on unauthorized response`() async {
        let mockProvider = MockAPIProvider()
        given(mockProvider).request(any()).willThrow(APIError.unauthorized)
        let repo = OpenAPIAppRepository(provider: mockProvider)

        // When/Then - verify error propagation
        await #expect(throws: APIError.unauthorized) {
            try await repo.fetchApps(limit: nil)
        }
    }
}
```

## Domain Model Tests

Test computed properties and domain rules:

```swift
@Suite
struct ProcessingStateTests {
    @Test func `valid state is ready and not failed`() {
        #expect(ProcessingState.valid.isReady == true)
        #expect(ProcessingState.valid.hasFailed == false)
    }

    @Test func `failed state is not ready and has failed`() {
        #expect(ProcessingState.failed.isReady == false)
        #expect(ProcessingState.failed.hasFailed == true)
    }

    @Test func `processing state is not ready and not failed`() {
        #expect(ProcessingState.processing.isReady == false)
        #expect(ProcessingState.processing.hasFailed == false)
    }
}

@Suite
struct BetaTesterTests {
    @Test func `display name combines first and last name`() {
        let tester = BetaTester(id: "1", firstName: "Jane", lastName: "Smith",
                                email: "jane@example.com", inviteType: .email)
        #expect(tester.displayName == "Jane Smith")
    }

    @Test func `display name handles missing first name`() {
        let tester = BetaTester(id: "1", firstName: nil, lastName: "Smith",
                                email: "jane@example.com", inviteType: .email)
        #expect(tester.displayName == "Smith")
    }
}
```

## Async Test Patterns

```swift
@Test func `fetchBuilds returns builds for app`() async throws {
    // Given
    let mockRepo = MockBuildRepository()
    given(mockRepo).fetchBuilds(appId: .any, limit: .any).willReturn([
        Build(id: "b1", version: "1.0.1", processingState: .valid, uploadedDate: .now)
    ])

    // When
    let builds = try await mockRepo.fetchBuilds(appId: "app123", limit: 10)

    // Then
    #expect(builds.count == 1)
    #expect(builds[0].version == "1.0.1")
    #expect(builds[0].isReady == true)
}

@Test func `fetchBuilds throws on API error`() async {
    let mockRepo = MockBuildRepository()
    given(mockRepo).fetchBuilds(appId: .any, limit: .any)
        .willThrow(APIError.notFound(resource: "App"))

    await #expect(throws: APIError.self) {
        try await mockRepo.fetchBuilds(appId: "missing", limit: nil)
    }
}
```

## Test Organization

```
Tests/
├── DomainTests/
│   ├── Apps/
│   │   └── AppTests.swift                 # App struct behavior
│   ├── Builds/
│   │   └── BuildTests.swift               # Build struct + ProcessingState
│   ├── TestFlight/
│   │   ├── BetaGroupTests.swift
│   │   └── BetaTesterTests.swift
│   └── Shared/
│       └── PaginatedResponseTests.swift
└── InfrastructureTests/
    ├── Apps/
    │   └── OpenAPIAppRepositoryTests.swift  # Adapter mapping tests
    ├── Builds/
    │   └── OpenAPIBuildRepositoryTests.swift
    └── Auth/
        └── EnvironmentAuthProviderTests.swift
```

## Running Tests

```bash
# Run all tests
swift test

# Run specific target
swift test --filter DomainTests

# Run specific test
swift test --filter "BuildTests/valid processing state is ready"
```

## Chicago School Summary

### What to Test

| Test Type           | What to Assert                                    |
|---------------------|---------------------------------------------------|
| Domain models       | Computed properties, enum cases, state rules      |
| Repository adapters | Field mapping, error propagation, returned values |
| Commands            | Output format, argument parsing behavior          |

### What NOT to Test

- That `fetchApps` was called N times
- Internal implementation details of adapters
- SDK internals

### Red-Green-Refactor Cycle

```
1. RED    - Write a failing test that asserts expected STATE
2. GREEN  - Write minimal code to make the test pass
3. REFACTOR - Improve code while keeping tests green
```

Design emerges from this cycle - let tests guide structure.