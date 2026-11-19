---
name: app-implement-feature
description: |
  Guide for implementing features in a Swift app laid out by concept, not by layer: each concept folder holds its public face (rich values, @Mockable roles named for what they are), its implementations in Internal/, and the bare outside call in Internal/System/; no Domain/ or Infrastructure/ folders. Covers placing the change in docs/CANONICAL_MODEL.md, Chicago-school TDD and Swift 6.2 patterns. Use this skill when:
  (1) Adding new functionality to a Swift app
  (2) Creating domain models that follow user's mental model
  (3) Building SwiftUI views that consume domain models directly
  (4) User asks "how do I implement X" or "add feature Y"
  (5) Implementing any feature that spans a concept folder, its Internal/ implementations, and the App
---

# Implement Feature

Implement features using architecture-first design, TDD, rich domain models, and Swift 6.2 patterns.

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│  0. DESIGN (no approval gate — design, then build)           │
├─────────────────────────────────────────────────────────────┤
│  • Place it in the canonical model (docs/CANONICAL_MODEL.md) │
│  • Name every type for what it is in the domain              │
│  • Diagram: public face · Internal/ · Internal/System/       │
│  • Show the design and the files to touch, then go on        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  1-3. TDD IMPLEMENTATION                                     │
├─────────────────────────────────────────────────────────────┤
│  • Public face: value types, @Mockable roles (<Concept>/)    │
│  • Implementations (<Concept>/Internal/)                     │
│  • Bare outside call (<Concept>/Internal/System/, ≤100 LOC)  │
│  • The way in: App wiring and views                          │
└─────────────────────────────────────────────────────────────┘
```

## Phase 0: Design

Design before writing code, show it, then build it test-first. Don't stop to
ask for approval; the user interrupts if the design is wrong. Ask only when a
decision is genuinely theirs (a concept that fits no folder, a changed law).

### Step 1: Place it in the canonical model

`docs/CANONICAL_MODEL.md` is the single map of the domain: the tree of
concepts, the words (ubiquitous language), every law with its **one owner**,
and the folder each concept lives in. Read it, then answer:

| Question | If yes |
|---|---|
| Which concept owns the question it answers? | its type goes in `Sources/<Concept>/`, its implementation in that concept's `Internal/`. A concept that fits no folder is a missing word — ask before inventing a folder |
| Which node is told? | a new verb lands on one node of the tree; `App/` only parses, calls and renders |
| Does it add or change a law? | it gets **one** owner — the type that holds the data. Grep for the rule first: if it is already written, that is the owner, or the duplicate to remove |
| Does it need the outside world? | a `@Mockable` role in the public face, named for the role ([Naming](#4-name-every-abstraction-for-its-role)), implemented in `Internal/` |
| Does what differs between cases become a branch? | make it data: a table, a value, a registration — not an `if` |

When the doc doesn't cover the change, write it into `CANONICAL_MODEL.md`
first (tree lines, a law with its owner, a word in the glossary). That diff
is part of the design. If the project has no `CANONICAL_MODEL.md` yet, start
one with just the concepts this feature touches. Code that disagrees with the
doc is behind; don't bend the design to it.

Then ask the five questions of every type the change touches — would the user
say it, does it decide about itself, can you see every state, is it as small as
it can be, is what differs data — and check each concept it touches →
[domain-shape.md](references/domain-shape.md).

### Step 2: Create Architecture Diagram

Use an ASCII diagram showing the concept folder, what sits in its public face,
what sits in `Internal/`, and the one bare call in `Internal/System/`:

```
Sources/Orders/                 Orders/Internal/                 Orders/Internal/System/
┌──────────────────┐           ┌──────────────────────┐ any      ┌────────────────────────┐
│ Order, OrderItem │           │ APIOrders            │ HTTP     │ URLSessionHTTP         │
│ (values + rules) │ ◀──────── │ (request, decode,    │ ───────▶ │ (≤100 lines: only the  │
│ Orders           │ implements│  map DTO → Order,    │          │  URLSession call)      │
│ (@Mockable role) │           │  error mapping)      │ ◀─ Mock  └────────────────────────┘
│ OrderBook (actor)│           └──────────────────────┘   HTTP
└──────────────────┘                                       in tests
         ▲
         │ imports the public face only
Sources/App/   SwiftUI views + entry point (wires Internal/ implementations in)
```

### Step 3: Document Component Interactions

List each component with:
- **Purpose**: What it does
- **Inputs**: What it receives
- **Outputs**: What it produces
- **Dependencies**: What it needs

```
| Component  | Purpose               | Inputs       | Outputs      | Dependencies |
|------------|-----------------------|--------------|--------------|--------------|
| Users      | Find and save users   | UserId       | User         | HTTP         |
| OrderBook  | Keep orders current   | Order, User  | Order        | Orders       |
```

### Step 4: Show the design, then build

Present the `CANONICAL_MODEL.md` diff (if any), the diagram and a "files to
touch" list ([template](references/architecture-diagrams.md#design-presentation-template)),
then go straight to Phase 1. No approval question.

---

## Core Principles

### 1. Rich Domain Models (User's Mental Model)

Domain models encapsulate behavior, not just data:

```swift
// Rich domain model with behavior
public struct Order: Sendable, Equatable {
    public let items: [OrderItem]
    public let status: OrderStatus

    // Domain behavior - computed from state
    public var totalAmount: Decimal {
        items.reduce(0) { $0 + $1.subtotal }
    }

    public var canBeCancelled: Bool {
        [.pending, .processing].contains(status)
    }

    public var itemCount: Int { items.count }
}
```

### 2. Swift 6.2 Patterns (No ViewModel Layer)

Views consume domain models directly:

```swift
// Views consume domain directly - NO ViewModel layer
struct OrderListView: View {
    let orders: [Order]

    var body: some View {
        ForEach(orders, id: \.id) { order in
            OrderRow(order: order)
        }
    }
}

struct OrderRow: View {
    let order: Order  // Domain model directly

    var body: some View {
        HStack {
            Text(order.status.displayName)
            Spacer()
            Text(order.totalAmount, format: .currency(code: "USD"))
        }
    }
}
```

### 3. Protocol-Based DI with @Mockable

```swift
@Mockable
public protocol Orders: Sendable {
    func all() async throws -> [Order]
    func fetch(id: OrderId) async throws -> Order
    func save(_ order: Order) async throws
}

@Mockable
public protocol HTTP: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
```

### 4. Name every abstraction for its role

Every `@Mockable` protocol, actor and adapter is named **for what it is in the
domain**, never for its architectural pattern:

- **Never `XxxService`, `XxxManager`, `XxxPort`, `XxxHelper`.** If you reach for
  one, the abstraction isn't named yet — keep going until the noun describes
  what the thing *is* (`OrderBook`, `Checkout`, `HTTP`, `Subprocess`). If no
  noun comes, the abstraction probably shouldn't exist yet.
- **Aggregate persistence takes the plural of the aggregate** — `Orders`,
  `Users`, `Books` — never the suffix `XxxRepository`. This carve-out is only
  for collection-like load / save / delete by identity; anything else (an
  adapter, an event source, a process) gets a role noun.
- **Implementations are named for how they do it**: `APIOrders`,
  `SQLiteOrders`, `URLSessionHTTP`, `InMemoryOrders` — each plays the role it
  is named after.
- **Tests are named for the outcome**, in the user's words:
  `` `should show the new status after an update` ``, never the method or
  mechanism (`returns`, `calls`, `fetches`).

## Architecture

**No `Domain/` folder, no `Infrastructure/` folder.** Code is grouped by the
concept it is about, not by the layer it sits in. Every folder has the same
shape:

```
Sources/
├── <Core>/                         # shared kernel: ids, errors, small values — imports nothing of ours
├── Orders/                         # one folder per concept (nest sub-concepts: Orders/Items/)
│   ├── Order.swift                 # PUBLIC FACE — values with behaviour,
│   ├── OrderStatus.swift           #   @Mockable roles, actors; what other folders may use
│   ├── Orders.swift                #   (Orders = the collection of Order: load / save by id)
│   └── Internal/                   # IMPLEMENTATIONS — adapters that play the roles,
│       ├── APIOrders.swift         #   DTOs, mappers, wire formats; decisions, unit-tested
│       ├── OrderDTO.swift
│       └── System/                 # THE BARE OUTSIDE CALL — URLSession, a DB driver,
│           └── URLSessionHTTP.swift #  Process, a private symbol; ≤100 lines, no decisions
└── App/                            # THE WAY IN — SwiftUI views (no ViewModel), entry point, wiring
Tests/<Target>Tests/                # mirrors Sources/ folder for folder
├── Orders/OrderTests.swift
└── Orders/Internal/APIOrdersTests.swift
```

| Part | Location | Holds | Tested how |
|------|----------|-------|------------|
| **Public face** | `Sources/<Concept>/` | rich value types, `@Mockable` role protocols, actors — the single source of truth | 100%, state-based |
| **Implementations** | `Sources/<Concept>/Internal/` | the adapters that play the roles, DTOs, mappers — every decision about the outside | ≥90%, via the collaborator's `MockXxx` |
| **Bare outside call** | `Sources/<Concept>/Internal/System/` | the irreducible call (`URLSession`, `Process`, `dlopen`, a socket), ≤100 lines | integration-only; the only code coverage leaves out |
| **The way in** | `Sources/App/` (or `Commands/`, `Server/`) | views, entry point, registration — parse, call, render; no rules | views are thin; wiring by a smoke test |

**Rules:**
- **Imports flow inward**: `App → <Concept> → <Core>`. A concept never imports another concept's `Internal/`; it may use another concept's public face only.
- **`Internal/` is a fence, not just a folder**: nothing outside the concept names a type in its `Internal/`, except the composition root in `App/` that wires an implementation into a role. Prefer `internal` access; make an `Internal/` type `public` only when the concept is its own module and `App/` must construct it.
- **Split adapters that wrap I/O**: the decisions (request building, decoding, mapping, retries, error mapping) live in `Internal/` and are tested through a small `@Mockable` collaborator (`HTTP`, `Subprocess`); only the call itself goes in `Internal/System/`. If a `System/` file grows a decision, move the decision up.
- **A concept that fits no folder is a missing word** — ask before inventing a folder.

**Key patterns:**
- **Collections of aggregates** - Data access behind a plural-noun protocol (`Orders`) in the public face
- **Protocol-Based DI** - `@Mockable` for testing
- **Chicago School TDD** - Test state, not interactions
- **No ViewModel layer** - Views consume the public face directly

## TDD Workflow (Chicago School)

We follow **Chicago school TDD** (state-based testing):
- Test **state changes** and **return values**, not interactions
- Focus on the "what" (observable outcomes), not the "how" (method calls)
- Mocks stub dependencies to return data, not to verify calls
- Design emerges from tests (emergent design)

### Phase 1: Public Face Tests (`Tests/.../<Concept>/`)

Test the values and actors in the concept folder through their state and
computed properties:

```swift
@Suite
struct OrderTests {
    @Test func `should total an order from its items`() {
        let order = Order(items: [
            OrderItem(price: 10, quantity: 2),
            OrderItem(price: 5, quantity: 1)
        ], status: .pending)

        #expect(order.totalAmount == 25)
    }

    @Test func `should let a pending order be cancelled`() {
        #expect(Order(items: [], status: .pending).canBeCancelled == true)
    }

    @Test func `should refuse to cancel an order once shipped`() {
        #expect(Order(items: [], status: .shipped).canBeCancelled == false)
    }
}
```

An actor in the public face is tested against a stubbed role:

```swift
@Suite
struct OrderBookTests {
    @Test func `should give back the order it was asked for`() async throws {
        let orders = MockOrders()
        given(orders).fetch(id: any()).willReturn(Order(items: [], status: .pending))

        let book = OrderBook(orders: orders)

        #expect(try await book.getOrder(OrderId("123")).status == .pending)
    }
}
```

### Phase 2: Implementation Tests (`Tests/.../<Concept>/Internal/`)

An adapter in `Internal/` holds every decision about the outside world
(request, decode, map, error mapping). Test it through its collaborator's
mock (`MockHTTP`) and assert on the domain value it produces:

```swift
@Suite
struct APIOrdersTests {
    @Test func `should load an order when the API answers`() async throws {
        let http = MockHTTP()
        given(http).request(any()).willReturn(
            OrderDTO(id: "123", status: "pending", items: [])
        )

        let order = try await APIOrders(http: http).fetch(id: OrderId("123"))

        #expect(order.id.value == "123")
        #expect(order.status == .pending)
    }

    @Test func `should fail when the network is down`() async {
        let http = MockHTTP()
        given(http).request(any()).willThrow(NetworkError.connectionFailed)

        await #expect(throws: OrdersError.networkError) {
            try await APIOrders(http: http).fetch(id: OrderId("123"))
        }
    }
}
```

The bare call in `Internal/System/` (`URLSessionHTTP`) is the collaborator's
real implementation. It has no decisions to unit-test; prove it once against
the real thing, tagged so the normal loop can skip it, with a time limit:

```swift
@Suite(.tags(.system))
struct URLSessionHTTPTests {
    @Test(.timeLimit(.minutes(1)))
    func `should reach a live server`() async throws {
        let status: HealthDTO = try await URLSessionHTTP().request(.health)
        #expect(status.ok == true)
    }
}
```

If you can't drive the adapter through a `MockXxx`, it isn't split
correctly: move the decision out of `System/` and back into `Internal/`.

### Phase 3: Integration

Wire the `Internal/` implementations into their roles at the app entry point (the only place outside the concept that names them), and create views that consume the public face.

## References

- [Architecture diagram patterns](references/architecture-diagrams.md) - ASCII diagram examples
- [Swift 6.2 @Observable patterns](references/swift-observable.md)
- [Think the domain first](references/domain-shape.md) - five questions, check by concept
- [Rich domain model patterns](references/domain-models.md)
- [TDD test patterns](references/tdd-patterns.md)

## Checklist

### Design (Phase 0)
- [ ] Place the change in `docs/CANONICAL_MODEL.md` (concept, owner of every law it adds); update the doc first if it doesn't cover it
- [ ] Ask the five questions of every type touched ([domain-shape](references/domain-shape.md))
- [ ] Name every new type for its domain role — no `Service` / `Manager` / `Port` / `Repository` suffixes
- [ ] Create ASCII diagram: public face · `Internal/` · `Internal/System/`
- [ ] Show the design and files to touch, then proceed (no approval question)

### Implementation (Phases 1-3) - Chicago School TDD
- [ ] Write failing test asserting expected STATE (Red)
- [ ] Write minimal code to pass the test (Green)
- [ ] Refactor while keeping tests green
- [ ] Define the public face in `Sources/<Concept>/` (values with behavior, `@Mockable` roles)
- [ ] Test state changes and return values (not interactions)
- [ ] Define protocols with `@Mockable` for external dependencies
- [ ] Stub mocks to return data, assert on resulting state
- [ ] Implement adapters in `Sources/<Concept>/Internal/`; bare outside call only in `Internal/System/` (≤100 lines)
- [ ] Tests mirror `Sources/` folder for folder (`Tests/<Target>Tests/<Concept>/Internal/…`)
- [ ] No new `Domain/` or `Infrastructure/` folder; nothing outside the concept (except the App wiring) names an `Internal/` type
- [ ] Create views consuming the public face directly
- [ ] Run `swift test` to verify all tests pass
