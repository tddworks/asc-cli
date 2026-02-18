---
name: implement-feature
description: |
  Guide for implementing features in asc-swift (App Store Connect CLI) following architecture-first design, TDD, rich domain models, and Swift 6.2 patterns. Use this skill when:
  (1) Adding new functionality to the CLI tool
  (2) Creating domain models that follow user's mental model
  (3) Building new CLI commands that consume domain repositories
  (4) User asks "how do I implement X" or "add feature Y"
  (5) Implementing any feature that spans Domain, Infrastructure, and ASCCommand layers
---

# Implement Feature in asc-swift

Implement features using architecture-first design, TDD, rich domain models, and Swift 6.2 patterns.

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  1. ARCHITECTURE DESIGN (Required - User Approval Needed)  │
├─────────────────────────────────────────────────────────────┤
│  • Analyze requirements                                     │
│  • Create component diagram                                 │
│  • Show data flow and interactions                          │
│  • Present to user for review                               │
│  • Wait for approval before proceeding                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼ (User Approves)
┌─────────────────────────────────────────────────────────────┐
│  2. TDD IMPLEMENTATION                                      │
├─────────────────────────────────────────────────────────────┤
│  • Domain model tests → Domain value types + protocol       │
│  • Infrastructure tests → OpenAPI adapter                   │
│  • Command wiring + integration                             │
└─────────────────────────────────────────────────────────────┘
```

## Phase 0: Architecture Design (MANDATORY)

Before writing any code, create an architecture diagram and get user approval.

### Step 1: Analyze Requirements

Identify:
- What new models/types are needed
- Which repository protocols to define or extend
- Data flow: ASC API → Infrastructure adapter → Domain model → CLI output
- Which `appstoreconnect-swift-sdk` endpoints to call

### Step 2: Create Architecture Diagram

Use ASCII diagram showing all components and their interactions:

```
Example: Adding BetaFeedback feature

┌─────────────────────────────────────────────────────────────────────┐
│                           ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EXTERNAL              INFRASTRUCTURE              DOMAIN            │
│  ┌─────────────┐     ┌──────────────────────┐   ┌────────────────┐  │
│  │  ASC API    │────▶│  OpenAPIFeedback     │──▶│ BetaFeedback   │  │
│  │  /feedback  │     │  Repository          │   │ (struct)       │  │
│  └─────────────┘     │  (implements         │   └────────────────┘  │
│                      │  FeedbackRepository) │          │            │
│                      └──────────────────────┘          ▼            │
│                                                 ┌────────────────┐  │
│                                                 │FeedbackRepository│ │
│                                                 │ (protocol)     │  │
│                                                 └────────────────┘  │
│                                                         │            │
│                                                         ▼            │
│                      ┌────────────────────────────────────────────┐ │
│                      │  ASCCommand Layer                           │ │
│                      │  ┌──────────────────────────────────────┐  │ │
│                      │  │  FeedbackCommand (AsyncParsableCmd)  │  │ │
│                      │  │  FeedbackList subcommand             │  │ │
│                      │  └──────────────────────────────────────┘  │ │
│                      └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 3: Document Component Interactions

```
| Component                 | Purpose                   | Inputs            | Outputs         | Dependencies         |
|---------------------------|---------------------------|-------------------|-----------------|----------------------|
| BetaFeedback              | Domain value type         | API response      | Formatted data  | None                 |
| FeedbackRepository        | DI boundary protocol      | appId, groupId    | [BetaFeedback]  | None                 |
| OpenAPIFeedbackRepository | API adapter               | APIProvider       | [BetaFeedback]  | appstoreconnect-sdk  |
| FeedbackList (command)    | CLI subcommand            | --app, --output   | Table/JSON/MD   | FeedbackRepository   |
```

### Step 4: Present for User Approval

**IMPORTANT**: Ask user to review the architecture before implementing.

Use AskUserQuestion tool with options:
- "Approve - proceed with implementation"
- "Modify - I have feedback on the design"

Do NOT proceed to Phase 1 until user explicitly approves.

---

## Core Principles

### 1. Rich Domain Models (User's Mental Model)

Domain models encapsulate behavior, not just data:

```swift
// User thinks: "What's the status of this build?"
public struct Build: Sendable, Equatable {
    public let id: String
    public let version: String
    public let uploadedDate: Date
    public let processingState: ProcessingState

    // User asks: "Is this build ready to test?"
    public var isReady: Bool { processingState == .valid }

    // User asks: "How old is this build?"
    public var ageDescription: String { /* relative date string */ }
}

public enum ProcessingState: String, Sendable {
    case processing = "PROCESSING"
    case failed = "FAILED"
    case invalid = "INVALID"
    case valid = "VALID"

    // Domain rule: ready for TestFlight distribution
    public var isReady: Bool { self == .valid }
    public var hasFailed: Bool { self == .failed || self == .invalid }
}
```

### 2. Repository Pattern for External Data

Protocols in Domain, OpenAPI adapters in Infrastructure:

```swift
// Domain: defines the interface
@Mockable
public protocol AppRepository: Sendable {
    func fetchApps(limit: Int?) async throws -> [App]
}

// Infrastructure: maps SDK types → domain types
public struct OpenAPIAppRepository: AppRepository {
    private let provider: APIProvider

    public func fetchApps(limit: Int?) async throws -> [App] {
        let response = try await provider.request(...)
        return response.data.map { App.from($0) }
    }
}
```

### 3. Commands Consume Repositories

Commands use repositories via `ClientProvider`:

```swift
struct AppsList: AsyncParsableCommand {
    @OptionGroup var globalOptions: GlobalOptions
    @Option var limit: Int = 50

    func run() async throws {
        let repo = ClientProvider.makeAppRepository(globalOptions)
        let apps = try await repo.fetchApps(limit: limit)
        OutputFormatter.print(apps, format: globalOptions.output)
    }
}
```

---

## Architecture

| Layer | Location | Purpose |
|-------|----------|---------|
| **Domain** | `Sources/Domain/` | Value types, repository protocols, error types |
| **Infrastructure** | `Sources/Infrastructure/` | OpenAPI adapters implementing domain protocols |
| **ASCCommand** | `Sources/ASCCommand/` | CLI commands, TUI, output formatting, `ClientProvider` |

**Key patterns:**
- **Repository Pattern** - Protocols in Domain, `OpenAPI*Repository` implementations in Infrastructure
- **Adapter Pattern** - Infrastructure maps SDK types to domain value types
- **Protocol-Based DI** - `@Mockable` enables testing without live API
- **Chicago School TDD** - Test state and return values, not interactions
- **Sendable Value Types** - Domain models are immutable `struct`s

## TDD Workflow (Chicago School)

We follow **Chicago school TDD** (state-based testing):
- Test **state changes** and **return values**, not interactions
- Mocks stub dependencies to return data, not to verify calls
- Design emerges from tests

### Phase 1: Domain Model Tests

Test computed properties and state:

```swift
@Suite
struct BuildTests {
    @Test func `valid processing state is ready`() {
        let build = Build(id: "1", version: "1.0", processingState: .valid, uploadedDate: .now)
        #expect(build.isReady == true)
    }

    @Test func `failed processing state is not ready`() {
        let build = Build(id: "1", version: "1.0", processingState: .failed, uploadedDate: .now)
        #expect(build.isReady == false)
        #expect(build.processingState.hasFailed == true)
    }
}
```

### Phase 2: Infrastructure Tests

Stub dependencies, assert on returned domain models:

```swift
@Suite
struct OpenAPIAppRepositoryTests {
    @Test func `fetchApps maps SDK response to domain models`() async throws {
        // Given - stub APIProvider with fixture data
        let provider = MockAPIProvider()
        given(provider).request(any()).willReturn(appsResponseFixture)
        let repo = OpenAPIAppRepository(provider: provider)

        // When
        let apps = try await repo.fetchApps(limit: nil)

        // Then - verify mapping, not that SDK was called
        #expect(apps.count == 3)
        #expect(apps[0].bundleId == "com.example.app")
    }
}
```

### Phase 3: Command Integration

1. Add `makeXRepository()` factory to `ClientProvider.swift`
2. Create command in `Sources/ASCCommand/Commands/X/`
3. Register in `ASC.swift` subcommands array

## References

- [Architecture diagram patterns](references/architecture-diagrams.md) - ASCII diagrams for asc-swift layers
- [Rich domain model patterns](references/domain-models.md) - App, Build, BetaGroup examples
- [TDD test patterns](references/tdd-patterns.md) - Chicago school patterns with @Mockable
- [Swift 6.2 concurrency patterns](references/swift-concurrency.md) - Sendable, async/await in CLI

## Checklist

### Architecture Design (Phase 0)
- [ ] Analyze requirements and identify components
- [ ] Create ASCII architecture diagram with component interactions
- [ ] Document component table (purpose, inputs, outputs, dependencies)
- [ ] **Get user approval before proceeding**

### Implementation (Phases 1-3) - Chicago School TDD
- [ ] Write failing test asserting expected STATE (Red)
- [ ] Write minimal code to pass the test (Green)
- [ ] Refactor while keeping tests green
- [ ] Define domain value types in `Sources/Domain/` with behavior
- [ ] Define repository protocol with `@Mockable`
- [ ] Implement OpenAPI adapter in `Sources/Infrastructure/`
- [ ] Add command to `Sources/ASCCommand/Commands/`
- [ ] Register in `ASC.swift` subcommands
- [ ] Add factory to `ClientProvider.swift`
- [ ] Run `swift test` to verify all tests pass