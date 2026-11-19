# Architecture Diagram Patterns

ASCII diagrams for documenting feature architecture before implementation.

## Table of Contents

- [Concept Folder Layout](#concept-folder-layout)
- [Data Flow Diagrams](#data-flow-diagrams)
- [Sequence Diagrams](#sequence-diagrams)
- [Component Interaction Tables](#component-interaction-tables)

---

## Concept Folder Layout

No `Domain/` or `Infrastructure/` layer folders: each concept folder carries
its public face at the top, its implementations in `Internal/`, and the bare
outside call in `Internal/System/`.

### One Concept (Standard)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FEATURE: [Feature Name]                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Sources/[Concept]/        [Concept]/Internal/   Internal/System/    │
│  ┌─────────────────┐       ┌─────────────────┐   ┌───────────────┐   │
│  │  [Model]        │◀──────│  [Adapter]      │──▶│ [Bare call]   │──▶ API/DB
│  │  (value types)  │ impl. │  (decode, map,  │   │ (≤100 lines,  │   │
│  │  [Role]         │       │   decisions)    │   │  no decisions)│   │
│  │  (@Mockable)    │       └─────────────────┘   └───────────────┘   │
│  │  [Actor]        │                                                 │
│  └─────────────────┘                                                 │
│          ▲ public face only                                          │
│  ┌───────────────────────────────────────┐                           │
│  │  Sources/App/                          │                           │
│  │  [Views] · [Entry point: wires         │                           │
│  │           Internal/ adapters in]       │                           │
│  └───────────────────────────────────────┘                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Full System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Swift App System                                │
├─────────────────────────────────────────────────────────────────────────┤
│  Sources/App/            views (@Observable state) · entry point/wiring  │
│        │ imports public faces                                            │
│        ▼                                                                 │
│  ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────┐  │
│  │ Orders/              │ │ Users/               │ │ [NewConcept]/    │  │
│  │  Order, OrderStatus  │ │  User                │ │  [Model]         │  │
│  │  Orders              │ │  Users               │ │  [Role]          │  │
│  │  OrderBook (actor)   │ │                      │ │                  │  │
│  │  Internal/           │ │  Internal/           │ │  Internal/       │  │
│  │   APIOrders          │ │   APIUsers           │ │   [Adapter]      │  │
│  │   OrderDTO           │ │   System/            │ │   System/        │  │
│  └──────────────────────┘ └──────────────────────┘ └──────────────────┘  │
│        │ every concept may use                                           │
│        ▼                                                                 │
│  Sources/Core/           ids · errors · HTTP role                        │
│    Internal/System/      URLSessionHTTP (the one network call)           │
└─────────────────────────────────────────────────────────────────────────┘
```

Concepts never reach into each other's `Internal/`.

---

## Data Flow Diagrams

### Collection Data Flow (Orders → APIOrders)

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│  API/DB   │────▶│ APIOrders │────▶│  Mapper   │────▶│  Domain   │
│  Response │     │  Fetch    │     │  Logic    │     │  Model    │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
     Raw               Fetch            Parse            Domain
     Data              Data             Data             Model
```

### Actor Orchestration Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ACTOR FLOW                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  View ──▶ OrderBook (actor) ──▶ Orders.fetch() ──▶ API/DB          │
│               │                                        │            │
│               │                                        ▼            │
│               │                              ┌─────────────────┐   │
│               │                              │ External Call   │   │
│               │                              └─────────────────┘   │
│               │                                        │            │
│               │                                        ▼            │
│               │                              ┌─────────────────┐   │
│               │                              │ Parse Response  │   │
│               │                              └─────────────────┘   │
│               │                                        │            │
│               ▼                                        ▼            │
│       ┌─────────────────┐                   ┌─────────────────┐     │
│       │ Update State    │◀──────────────────│ Domain Model    │     │
│       │ (notify views)  │                   │ (returned)      │     │
│       └─────────────────┘                   └─────────────────┘     │
│               │                                                     │
│               ▼                                                     │
│       ┌─────────────────┐                                           │
│       │ SwiftUI Updates │                                           │
│       └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Error Handling Flow

```
┌─────────┐     ┌───────────┐     ┌─────────────┐     ┌──────────────┐
│ Orders  │────▶│ Try Fetch │────▶│   Success   │────▶│ Return Data  │
└─────────┘     └───────────┘     └─────────────┘     └──────────────┘
                      │
                      ▼ (failure)
               ┌─────────────┐     ┌─────────────────┐
               │ Catch Error │────▶│ Map to Domain   │
               └─────────────┘     │ Error           │
                                   └─────────────────┘
                                          │
                                          ▼
                                   ┌─────────────────┐
                                   │ Actor handles   │
                                   │ or propagates   │
                                   └─────────────────┘
```

---

## Sequence Diagrams

### User Action Flow

```
User          View          OrderBook        Orders            API
 │              │               │                │               │
 │──tap()──────▶│               │                │               │
 │              │──action()────▶│                │               │
 │              │               │──fetch()──────▶│               │
 │              │               │                │──request()───▶│
 │              │               │                │               │
 │              │               │                │◀──response────│
 │              │               │◀──model────────│               │
 │              │               │                │               │
 │              │               │──notify()─────▶│ (if changed)  │
 │◀───UI update─│               │                │               │
 │              │               │                │               │
```

### State Change Notification

```
Orders          OrderBook       @Observable      View
  │                 │               │               │
  │──model─────────▶│               │               │
  │                 │──update()────▶│               │
  │                 │               │               │
  │                 │               │ (state changed)
  │                 │               │──invalidate()─▶│
  │                 │               │               │
  │                 │               │               │──redraw
  │                 │               │               │
```

---

## Component Interaction Tables

### Standard Table Format

```
| Component    | Purpose                    | Inputs         | Outputs        | Dependencies |
|--------------|----------------------------|----------------|----------------|--------------|
| Orders       | The collection of orders   | OrderId        | Order          | -            |
| APIOrders    | Plays Orders over the API  | OrderId        | Order          | HTTP         |
| OrderBook    | Keeps orders current       | Order, Status  | Updated Order  | Orders       |
| OrderMapper  | Converts DTO to an Order   | OrderDTO       | Order          | None         |
```

### Extended Table (for complex features)

```
| Component       | Place                  | Protocol | Creates/Modifies | Test File               |
|-----------------|------------------------|----------|------------------|-------------------------|
| APIOrders       | Orders/Internal/       | Orders   | Creates          | APIOrdersTests.swift    |
| OrderMapper     | Orders/Internal/       | -        | Creates          | OrderMapperTests.swift  |
| URLSessionHTTP  | Core/Internal/System/  | HTTP     | Creates          | (integration only)      |
| OrderBook       | Orders/ (public face)  | -        | Manages          | OrderBookTests.swift    |
| OrderListView   | App/                   | -        | Displays         | -                       |
```

### Files to Create/Modify Table

```
| File Path                                            | Action | Description                     |
|------------------------------------------------------|--------|---------------------------------|
| docs/CANONICAL_MODEL.md                              | Modify | Orders in the tree, laws, words |
| Sources/Orders/Orders.swift                          | Create | @Mockable collection (face)     |
| Sources/Orders/OrderBook.swift                       | Create | Actor keeping orders current    |
| Sources/Orders/Internal/APIOrders.swift              | Create | Plays Orders over the API       |
| Tests/AppTests/Orders/OrderBookTests.swift           | Create | Actor behavior tests            |
| Tests/AppTests/Orders/Internal/APIOrdersTests.swift  | Create | Adapter behavior tests          |
| Sources/App/Views/OrderListView.swift                | Create | SwiftUI view for orders         |
| Sources/App/App.swift                                | Modify | Wire APIOrders into Orders      |
```

---

## Design Presentation Template

Show the design, then start Phase 1 — no approval question:

```
## Design: [Feature Name]

### Canonical model
[diff to docs/CANONICAL_MODEL.md, or "already covered by §<n>"]

[Diagram Here]

### Components Summary

| Component | Purpose |
|-----------|---------|
| [Name]    | [Desc]  |

### Files to Create/Modify

- `Sources/<Concept>/NewType.swift` - [Description]
- `Sources/<Concept>/Internal/NewAdapter.swift` - [Description]
- `Tests/<Target>Tests/<Concept>/NewTypeTests.swift` - [Description]

Starting with the first failing test: `should <outcome> [when <situation>]`.
```
