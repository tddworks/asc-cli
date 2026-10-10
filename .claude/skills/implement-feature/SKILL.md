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

2. TDD IMPLEMENTATION (Always write tests FIRST)
   • NEVER write implementation code without a failing test
   • Think from user's mental model — test cases describe what the user expects, not internals
   • Write domain tests first → then infrastructure tests → then command tests
   • Each test must FAIL (red) before writing implementation
   • Domain tests → Domain value types + AffordanceProviding + @Mockable protocol
   • Infrastructure: SDK adapter injecting parent IDs, composing multi-call flows
   • Command: formatAgentItems → {"data":[{...,"affordances":{...}}]}

3. REST EXPOSURE (no feature is done until reachable via REST)
   • Add affordanceMode parameter to execute(repo:)
   • Wire a controller in Sources/ASCCommand/Commands/Web/Controllers/
   • Register the route in RESTRoutes.swift
   • Verify _links is populated for the parent resource

4. DOCS
   • docs/features/<feature>/README.md (user-facing, ≤200 lines), one CHANGELOG line, make docs
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

### 1. Affordances: prefer `structuredAffordances` (single source of truth)

`structuredAffordances: [Affordance]` is the canonical source. Both the CLI string (`affordances`) and the REST `_links` (`apiLinks`) auto-derive from it. **Do not override `apiLinks` directly** — that bypasses SSOT and creates two parallel surfaces to maintain.

```swift
extension MyModel: AffordanceProviding {
    public var structuredAffordances: [Affordance] {
        var items: [Affordance] = [
            Affordance(key: "listChildren",  command: "children",  action: "list",
                       params: ["parent-id": id]),
            Affordance(key: "listSiblings",  command: "my-models", action: "list",
                       params: ["grandparent-id": parentId]),
            Affordance(key: "update",        command: "my-models", action: "update",
                       params: ["model-id": id, "name": "<name>"]),
        ]
        if isActionable {
            items.append(Affordance(key: "doAction", command: "my-models", action: "action",
                                    params: ["model-id": id]))
        }
        return items
    }
}
```

**Param ordering caveat:** `Affordance.cliCommand` sorts params alphabetically by key. Migration from a raw `affordances` override may shift the CLI string order — update existing test JSON snapshots to match. The CLI parser doesn't care about flag order.

**Nested CLI subcommands:** when the CLI is `asc iap price-points list` (subcommand of `iap`), register the route key with the literal space: `command: "iap price-points"`. Both `Affordance.cliCommand` and `RESTPathResolver` use the same key, so they stay in sync.

### 2. REST routes register in two places

Every `registerRoute(...)` call must be reachable from `RESTPathResolver.ensureInitialized()`. Add `_ = _yourRoutes` there. Forgetting this means `_links` silently resolves to `[:]` because the route table is empty when the protocol's `apiLinks` derivation runs in tests / fresh process state.

### 3. Every domain model must

```swift
public struct MyModel: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let parentId: String  // always carry parent ID (ASC API omits it)
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

### 4. Repository protocol — primitives only, but allow composition in adapters

```swift
@Mockable
public protocol MyRepository: Sendable {
    func listMyModels(parentId: String) async throws -> [MyModel]
}
```

Protocol methods stay primitive (one user-visible operation per method). The **SDK adapter** is allowed to compose multiple ASC API calls inside a single method when the user-visible operation requires it — see "Multi-call composition" below.

### 5. Command wiring — accept `affordanceMode` for REST reuse

```swift
struct MyList: AsyncParsableCommand {
    @OptionGroup var globals: GlobalOptions
    @Option(name: .long) var parentId: String

    func run() async throws {
        let repo = try ClientProvider.makeMyRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any MyRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let items = try await repo.listMyModels(parentId: parentId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
```

The REST controller calls the same `execute(repo:affordanceMode: .rest)` — no duplicate logic.

---

## Multi-call composition in SDK adapters

When ASC paginates a relationship or splits a single user-visible resource across endpoints, compose them inside the SDK adapter. **Apple's parent-endpoint `include=foo` truncates the relationship to ~10 entries** — for full lists, hit the dedicated relationship endpoint with explicit `limit`. The iOS SDK does this for `fetchAvailability`, `fetchPriceSchedule`, `fetchEqualizations`, and others.

```swift
public func getAvailability(iapId: String) async throws -> Domain.InAppPurchaseAvailability {
    // Two parallel calls — `include=availableTerritories` truncates to ~10.
    async let availResponse = client.request(
        APIEndpoint.v2.inAppPurchases.id(iapId).inAppPurchaseAvailability.get(parameters: .init())
    )
    async let terrResponse = client.request(
        APIEndpoint.v1.inAppPurchaseAvailabilities.id(iapId).availableTerritories.get(
            fieldsTerritories: [.currency], limit: 200
        )
    )
    let (avail, terr) = try await (availResponse, terrResponse)

    let territories = terr.data.map { Domain.Territory(id: $0.id, currency: $0.attributes?.currency) }
    return Domain.InAppPurchaseAvailability(
        id: avail.data.id, iapId: iapId,
        isAvailableInNewTerritories: avail.data.attributes?.isAvailableInNewTerritories ?? false,
        territories: territories
    )
}
```

**Test these with `StubAPIClient.willReturn(_:)` once per response type.** The stub keys responses by `String(describing: T.self)`, so each `willReturn` for a different response type queues up the next call's return value. Adding a regression test that returns 175 entries proves pagination works.

---

## TDD Workflow

**ALWAYS write tests first, then implement. Never write implementation code without a failing test. This is non-negotiable.**

See [tdd-patterns.md](references/tdd-patterns.md) for complete patterns including:
- `MockRepositoryFactory` (always use, never construct models inline)
- Affordance tests
- Infrastructure parent-ID injection tests
- `@Mockable` / `given().willReturn()` usage

Name each test `should <outcome> [when <situation>]`, in the words of the person, agent or REST client who sees the result — never a method, type or mechanism verb → [Naming tests](references/tdd-patterns.md#naming-tests).

### Phase 1: Domain

```swift
@Test func `should belong to the parent it was listed under`() {
    let model = MockRepositoryFactory.makeMyModel(id: "m1", parentId: "p1")
    #expect(model.parentId == "p1")
}

@Test func `should point to its children on the CLI`() {
    let model = MockRepositoryFactory.makeMyModel(id: "m1", parentId: "p1")
    #expect(model.affordances["listChildren"] == "asc children list --parent-id m1")
}

@Test func `should point to its children over REST`() {
    let model = MockRepositoryFactory.makeMyModel(id: "m1", parentId: "p1")
    #expect(model.apiLinks["listChildren"]?.href == "/api/v1/my-models/m1/children")
    #expect(model.apiLinks["listChildren"]?.method == "GET")
}
```

Both `affordances` and `apiLinks` derive from the same `structuredAffordances` — testing each catches both the CLI and REST surfaces in one set of assertions.

### Phase 2: Infrastructure

```swift
@Test func `should tie each model to the parent it was listed under`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(makeFixture())
    let repo = SDKMyRepository(client: stub)
    let models = try await repo.listMyModels(parentId: "p-42")
    #expect(models.allSatisfy { $0.parentId == "p-42" })
}
```

For multi-call adapters, stub each response type:

```swift
@Test func `should show the thing together with its related items`() async throws {
    let stub = StubAPIClient()
    stub.willReturn(ThingResponse(data: ..., links: .init(this: "")))
    stub.willReturn(RelatedResponse(data: [...], links: .init(this: "")))
    let repo = SDKMyRepository(client: stub)
    let result = try await repo.getThing(id: "t-1")
    // assert the composed result
}
```

### Phase 3: Command

Start by thinking like the user: **"When I run `asc my-models list --parent-id p-1`, what should I see?"**

#### Step 1: Define what the user expects

Before writing any code, write down the exact JSON the user should see. This is your specification:

```json
{
  "data" : [
    {
      "id" : "m-1",
      "parentId" : "p-1",
      "affordances" : {
        "listChildren" : "asc children list --parent-id m-1",
        "listSiblings" : "asc my-models list --grandparent-id p-1"
      }
    }
  ]
}
```

Affordances sort alphabetically by key in the JSON output, and params within each affordance sort alphabetically by flag name. Match that ordering in your expected JSON snapshot.

Also think about affordances from the user's perspective: **"What can I do next?"** — these are the commands the user would naturally want to run after seeing this output.

#### Step 2: Write the test (red)

Create a minimal command skeleton (struct + `@Option` fields + `execute()` returning `""`) — just enough to compile, NOT enough to pass. Then write the test:

```swift
@Test func `should list my models with their parent and next commands`() async throws {
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
```

Run it — **must fail** because `execute()` returns `""`.

#### Step 3: Implement and wire (green)

1. Add `makeMyRepository()` to `ClientProvider.swift` + factory to `ClientFactory.swift`
2. Implement `execute()` — just enough to make the test pass
3. Register in `ASC.swift` subcommands array
4. Run `swift test` — all must pass

#### Test rules

- **Name = user expectation** — `` `should offer submit for review when the version is editable` ``, not `` `execute returns correct JSON` ``; pair it with the counterpart (`` `should not offer submit for review when the version is live` ``)
- **Always `#expect()`** — `_ = try await cmd.execute(...)` with no assertion is not a test
- **Exact JSON assertion** — assert the complete output string, never `output.contains(...)`. This verifies field names, field order, affordance content, and nil-field omission all at once
- **Think about edge cases from user's perspective** — "What if there are no results?", "What if the version is not editable — should submit still appear?"

### Phase 4: REST exposure (mandatory)

Per CLAUDE.md, **a feature is not complete until it is reachable via REST.** Steps:

1. Make sure your model has `Presentable` conformance (so `restFormat` accepts it).
2. Confirm `structuredAffordances` is in place (so `_links` auto-populates for the parent resource that lists this model).
3. Confirm the relevant route is registered AND touched in `RESTPathResolver.ensureInitialized()`.
4. Add a controller in `Sources/ASCCommand/Commands/Web/Controllers/<X>Controller.swift`:

   ```swift
   struct MyController: Sendable {
       let repo: any MyRepository
       func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
           group.get("/parents/:parentId/children") { _, context -> Response in
               guard let parentId = context.parameters.get("parentId") else { return jsonError("Missing parentId") }
               let items = try await self.repo.listMyModels(parentId: parentId)
               return try restFormat(items)
           }
       }
   }
   ```

5. Wire the controller in `Sources/ASCCommand/Commands/Web/RESTRoutes.swift`:

   ```swift
   if let myRepo = try? factory.makeMyRepository(authProvider: auth) {
       MyController(repo: myRepo).addRoutes(to: v1)
   }
   ```

6. **Advertise the resource** from `APIRoot.structuredAffordances` (`Sources/Domain/Shared/APIRoot.swift`) when it is a new top-level resource, so `GET /api/v1` lists it.

7. Add a REST test in `Tests/ASCCommandTests/Commands/Web/RESTRoutesTests.swift` that calls `execute(repo:affordanceMode: .rest)` and asserts `_links` + the resolved REST path.

8. **Smoke-test the live server.** Build (`swift build`), restart (`asc web-server`), and `curl` the parent resource — confirm `_links` for each item points at the new endpoint.

**REST rules:**
- CLI flag and REST query-param names match: `--expired-only` ↔ `?expired-only=true`, both calling the same repository method.
- Helpers in `RESTRoutes.swift`: `restFormat(items)` (REST twin of `formatAgentItems(…, affordanceMode: .rest)`) and `jsonError(message, status:)` (from `Infrastructure/Web/ASCWebServer.swift`).
- `RESTPathResolver` maps affordance actions to HTTP: `list`/`get` → GET, `create`/`add` → POST to the parent's collection, `update` → PATCH, `delete`/`remove` → DELETE, anything else (e.g. `submit`) → POST `…/{id}/{action}`.
- Controllers are structs with dependencies injected at init; repositories are constructed once in `RESTRoutes.configure`, never per request.

### Phase 5: Docs

Docs follow `docs/documentation-design/README.md`: each fact has one home, and nothing repeats `--help` or the source.

1. **`docs/features/<feature>/README.md`** — user-facing, ≤200 lines, written from the actual implementation (read the code, never write from memory):
   - frontmatter `description:` — one sentence, what + "Use when …", ≤250 chars (it becomes the docs index row)
   - Quick start → Workflows → REST (paths + query-param mapping) → Gotchas → See also
   - **No** flag tables (`docs/commands.md` is generated), architecture, domain model listings, file maps or test snippets. Non-obvious reasons (Apple caps, multi-call workarounds) go in Gotchas as one-liners.
   - Examples use placeholders (`1234567890`, `ver-1`, `sub-1`), never IDs, names or text copied from a real account.
   - A topic that doesn't fit goes into `docs/features/<feature>/<topic>.md` next to the README.
   - Example: `docs/features/testflight/README.md`.
2. **`CHANGELOG.md`** — one bullet under `[Unreleased]`, ≤300 chars: starts with what the user types, says the effect (not the implementation), ends with `→ [docs](docs/features/<feature>/README.md)` and the PR link. Implementation detail goes in the PR.
3. **`make docs`** — regenerates `docs/commands.md` and the `docs/README.md` index. Never edit those by hand.
4. **README.md** — only if the feature is a new row in its "What It Covers" table.
5. `make check-docs` — no broken links, within budgets.

---

## Anti-patterns (don't)

- ❌ **Override `apiLinks` directly.** Use `structuredAffordances` so CLI and REST stay in sync. The protocol's default `apiLinks` derivation handles the REST mapping for you.
- ❌ **Override `affordances` with raw strings when migrating.** That blocks the default-derivation path. If you need a CLI string the `Affordance` renderer can't produce (e.g. multi-value flags like `--territory USA --territory CHN`), simplify the affordance — pick one representative value — rather than maintaining two surfaces.
- ❌ **`include=relationship` for full lists.** Apple paginates the included relationship to ~10 entries. Use the dedicated relationship endpoint with explicit `limit:`.
- ❌ **`output.contains(...)` in command tests.** Always assert the full JSON string so you catch field renames, ordering changes, and nil-omission regressions.
- ❌ **Forgetting `_ = _yourRoutes`** in `RESTPathResolver.ensureInitialized()`. Tests pass locally because some other model touched the lazy first; live `/api/v1/...` returns empty `_links`.
- ❌ **Skipping the smoke test.** Tests can pass while `_links` is empty in production due to test-time route side-effects. Always `curl` the live endpoint after restart.

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
- [ ] `XModel.swift` — `struct` + `Sendable` + `Equatable` + `Identifiable` + `Codable`
- [ ] Carries `parentId` (ASC API omits parent IDs from response — Infrastructure injects them)
- [ ] `Presentable` conformance (`tableHeaders`, `tableRow`)
- [ ] `AffordanceProviding` via `structuredAffordances` (NOT raw `affordances`)
- [ ] State enum with semantic booleans (`isLive`, `isEditable`, `isPendingReview`, etc.)
- [ ] `XRepository.swift` — `@Mockable` protocol with primitive methods only
- [ ] `make*` factory added to `MockRepositoryFactory.swift`
- [ ] Domain tests: model fields, semantic booleans, affordances, **and `apiLinks`** for the new keys

### Phase 2: Infrastructure
- [ ] `SDKXRepository.swift` — implements protocol, injects parent IDs in mappers
- [ ] Multi-call composition where needed (relationships paginate at ~10 — use dedicated endpoints with `limit:`)
- [ ] Factory registered in `ClientFactory.swift`
- [ ] `_xRoutes` registered AND touched in `RESTPathResolver.ensureInitialized()`
- [ ] Infrastructure tests cover: parent ID injection, multi-call composition, >10-entry regression

### Phase 3: Command
- [ ] `XCommand.swift` + subcommands using `formatAgentItems`
- [ ] `execute(repo:affordanceMode: .cli)` — accepts mode for REST reuse
- [ ] `ClientProvider.swift` — static factory method
- [ ] Registered in `ASC.swift` subcommands array
- [ ] Command tests: `should …` names, always `#expect()`, exact JSON snapshot
- [ ] Affordance keys sort alphabetically; params within each affordance sort alphabetically — match this in JSON snapshots

### Phase 4: REST exposure
- [ ] Controller added under `Sources/ASCCommand/Commands/Web/Controllers/`
- [ ] Wired in `Sources/ASCCommand/Commands/Web/RESTRoutes.swift`
- [ ] New top-level resource advertised in `APIRoot.structuredAffordances`
- [ ] REST query-param names match the CLI flags
- [ ] REST test in `RESTRoutesTests.swift` — calls `execute(repo:affordanceMode: .rest)`, asserts `"_links"` + resolved path
- [ ] **Smoke-tested live server** — restarted and curl'd the parent resource; `_links` confirms the new endpoint URL

### Phase 5: Docs
- [ ] `docs/features/<feature>/README.md` with `description`, written from actual code, ≤200 lines
- [ ] **REST section** with path table + query-param mapping
- [ ] No flag tables, architecture, domain listings or file maps
- [ ] `make docs` run; `make check-docs` clean for the new files
- [ ] CHANGELOG.md entry under `[Unreleased]`