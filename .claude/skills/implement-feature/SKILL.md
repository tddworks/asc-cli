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

Implement features using architecture-first design, TDD, rich domain models, and Command Affordances.

## Workflow

```
1. ARCHITECTURE DESIGN (Required — User Approval)
   • Think from user's mental model → identify domain models + commands
   • Analyze requirements, create ASCII diagram
   • Present to user → wait for approval

2. TDD IMPLEMENTATION
   • Think from user's mental model for test cases by writing domain tests first, then infrastructure, then command tests
   • Domain tests → Domain value types + AffordanceProviding + @Mockable protocol
   • Infrastructure: SDK adapter injecting parent IDs
   • Command: formatAgentItems → {"data":[{...,"affordances":{...}}]}

3. FEATURE DOC
   • Write docs/features/<feature>.md from the actual implementation
```

## Phase 0: Architecture Design (MANDATORY)

See [architecture-diagrams.md](references/architecture-diagrams.md) for diagram templates and the files-to-create table.

Steps:
1. Identify new models, protocols, and SDK endpoints needed
2. Draw the three-layer ASCII diagram
3. Fill the component table (purpose / inputs / outputs / dependencies)
4. Present with `AskUserQuestion` — options: "Approve" / "Modify"

**Do NOT write code until user approves.**

---

## Core Design Rules

### Every domain model must

```swift
public struct MyModel: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let parentId: String  // always carry parent ID (ASC API omits it)
}

extension MyModel: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds = [
            "listChildren": "asc children list --parent-id \(id)",
            "listSiblings": "asc my-models list --grandparent-id \(parentId)",
        ]
        if isActionable { cmds["doAction"] = "asc my-models action --id \(id)" }
        return cmds
    }
}
```

See [domain-models.md](references/domain-models.md) for complete patterns including:
- Parent ID injection in infrastructure mappers
- Semantic booleans on state enums
- `MockRepositoryFactory` usage
- **Domain operations** — extension methods that take `repo: some Protocol` to express what a model can do with its own ID (e.g. `set.importScreenshots(entries:imageURLs:repo:)`)

See [command-affordances.md](references/command-affordances.md) for:
- `AffordanceProviding` protocol
- `formatAgentItems` vs `formatItems`
- JSON output shape `{"data":[{...,"affordances":{...}}]}`

### Repository protocol

```swift
@Mockable
public protocol MyRepository: Sendable {
    func listMyModels(parentId: String) async throws -> [MyModel]
}
```

### Command wiring

```swift
struct MyList: AsyncParsableCommand {
    @OptionGroup var globals: GlobalOptions
    @Option(name: .long) var parentId: String

    func run() async throws {
        let repo = try ClientProvider.makeMyRepository()
        let items = try await repo.listMyModels(parentId: parentId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        print(try formatter.formatAgentItems(
            items,
            headers: ["ID", "Name"],
            rowMapper: { [$0.id, $0.name] }
        ))
    }
}
```

---

## TDD Workflow

See [tdd-patterns.md](references/tdd-patterns.md) for complete patterns including:
- `MockRepositoryFactory` (always use, never construct models inline)
- Affordance tests
- Infrastructure parent-ID injection tests
- `@Mockable` / `given().willReturn()` usage

### Phase 1: Domain

```swift
@Test func `new model carries parent id`() {
    let model = MockRepositoryFactory.makeMyModel(id: "m1", parentId: "p1")
    #expect(model.parentId == "p1")
}

@Test func `new model affordances include list children command`() {
    let model = MockRepositoryFactory.makeMyModel(id: "m1", parentId: "p1")
    #expect(model.affordances["listChildren"] == "asc children list --parent-id m1")
}
```

### Phase 2: Infrastructure

```swift
@Test func `listMyModels injects parentId into each model`() async throws {
    let mockProvider = MockAPIProvider()
    given(mockProvider).request(any()).willReturn(makeFixture())
    let repo = SDKMyRepository(provider: mockProvider)
    let models = try await repo.listMyModels(parentId: "p-42")
    #expect(models.allSatisfy { $0.parentId == "p-42" })
}
```

### Phase 3: Command wiring

1. Add `makeMyRepository()` to `ClientProvider.swift`
2. Add factory to `ClientFactory.swift`
3. Create `Sources/ASCCommand/Commands/MyModels/MyCommand.swift`
4. Register in `ASC.swift` subcommands array
5. Run `swift test` — all must pass

**Three mandatory rules for every command test:**
1. **Behavior-focused name** — describe what the user sees, not how the code works
2. **Always `#expect()`** — every test must have an assertion; `_ = try await cmd.execute(...)` with no `#expect` is not a test
3. **Exact JSON assertion** — assert the complete output string, never `output.contains(...)`

```swift
// ✅ CORRECT — behavior name, exact JSON assertion
@Test func `listed my models include parent id and affordances`() async throws {
    let mockRepo = MockMyRepository()
    given(mockRepo).listMyModels(parentId: .any).willReturn([
        MockRepositoryFactory.makeMyModel(id: "m-1", parentId: "p-1")
    ])
    let cmd = try MyList.parse(["--parent-id", "p-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)
    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "listChildren" : "asc children list --parent-id m-1",
            "listSiblings" : "asc my-models list --grandparent-id p-1"
          },
          "id" : "m-1",
          "parentId" : "p-1"
        }
      ]
    }
    """)
}

// ❌ AVOID — too loose, misses missing/extra fields and affordance regressions
#expect(output.contains("\"id\" : \"m-1\""))
```

The exact JSON assertion verifies: field names, field order, affordance content, nil-field omission — all at once.

### Phase 4: Feature doc

Write `docs/features/<feature>.md` from the actual implementation. The doc is derived from code — read the files, then write. Never write from memory.

Structure:
1. **CLI Usage** — one section per command, with flags table + examples + table-output sample
2. **Typical Workflow** — end-to-end bash script showing the happy path
3. **Architecture** — three-layer ASCII diagram + dependency note
4. **Domain Models** — every public struct/enum/protocol with fields, computed properties, and affordances
5. **File Map** — `Sources/` and `Tests/` trees + wiring files table
6. **API Reference** — endpoint → SDK call → repository method table
7. **Testing** — one representative test snippet + `swift test` command
8. **Extending** — natural next steps with stub code

Use `docs/features/screenshots.md` as the canonical reference example.

---

## References

- [Architecture diagrams](references/architecture-diagrams.md) — templates, command tree, files table
- [Domain model patterns](references/domain-models.md) — model requirements, parent IDs, mappers, MockRepositoryFactory
- [Command Affordances](references/command-affordances.md) — AffordanceProviding, formatAgentItems, JSON shape
- [TDD patterns](references/tdd-patterns.md) — MockRepositoryFactory, affordance tests, async patterns
- [Swift concurrency](references/swift-observable.md) — Sendable, @unchecked Sendable, method naming

---

## Checklist

### Phase 0: Architecture
- [ ] Requirements analyzed
- [ ] ASCII diagram created (see architecture-diagrams.md template)
- [ ] Files table filled
- [ ] **User approval received**

### Phase 1: Domain
- [ ] `XModel.swift` — `struct` (passive data) or `final class` (active object with injected repo) — see domain-models.md
- [ ] Carries `parentId`
- [ ] `AffordanceProviding` implemented (navigation + state-aware actions)
- [ ] State enum with semantic booleans (`isX`, `hasFailed`, etc.)
- [ ] If `final class`: custom `Equatable` + `Codable` exclude the repo field; `MockRepositoryFactory.makeX` gains a `repo:` parameter
- [ ] `XRepository.swift` — `@Mockable` protocol with primitive methods only (one API call each)
- [ ] `make*` factory added to `MockRepositoryFactory.swift`
- [ ] Domain tests written and passing (including domain operation tests)

### Phase 2: Infrastructure
- [ ] `SDKXRepository.swift` — implements protocol, injects parent IDs in mappers
- [ ] Factory registered in `ClientFactory.swift`
- [ ] Infrastructure tests cover parent ID injection

### Phase 3: Command
- [ ] `XCommand.swift` + `XList` subcommand using `formatAgentItems`
- [ ] `ClientProvider.swift` — static factory method
- [ ] Registered in `ASC.swift`
- [ ] Affordance tests added to `AffordancesTests.swift`
- [ ] Command tests: **behavior-focused names**, **always `#expect()`**, **exact JSON string** (not `output.contains`)
- [ ] `swift test` — all 100+ tests pass

### Phase 4: Feature Doc
- [ ] `docs/features/<feature>.md` written from actual code (read files first)
- [ ] All CLI commands documented with flags table + examples
- [ ] Domain models section matches actual struct fields
- [ ] File map reflects actual directory structure
- [ ] API reference table complete
