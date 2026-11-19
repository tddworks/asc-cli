# Architecture Diagram Patterns

## Table of Contents

- [Three-Layer Pattern](#three-layer-pattern)
- [Full System Overview](#full-system-overview)
- [Command Tree](#command-tree)
- [Agent-First Output Flow](#agent-first-output-flow)
- [Component Tables](#component-tables)
- [Files to Create/Modify](#files-to-createmodify)

---

## Three-Layer Pattern

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FEATURE: [Feature Name]                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EXTERNAL              INFRASTRUCTURE           DOMAIN               │
│  ┌─────────────┐       ┌─────────────────┐     ┌─────────────────┐  │
│  │  ASC API    │──────▶│  SDK[X]         │────▶│  [DomainModel]  │  │
│  │  endpoint   │       │  Repository     │     │  (struct)       │  │
│  └─────────────┘       │  (implements    │     │  + affordances  │  │
│                        │   [X]Repository)│     └─────────────────┘  │
│                        └─────────────────┘             │             │
│                                                         ▼             │
│                                                ┌─────────────────┐  │
│                                                │ [X]Repository   │  │
│                                                │ (@Mockable)     │  │
│                                                └─────────────────┘  │
│                                                         │            │
│                                                         ▼            │
│                        ┌───────────────────────────────────────┐    │
│                        │  ASCCommand Layer                       │    │
│                        │  [X]Command → [X]List                  │    │
│                        │  formatter.formatAgentItems(...)        │    │
│                        └───────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Full System Overview

```
ASCKit/<Concept>/  (public face)
  App                AppStoreVersion       AppStoreVersionLocalization
  Apps      (+ affordances)       AppScreenshotSet
  Builds    AppStoreVersionState  AppScreenshot
  TestFlight repos   AppScreenshots  AffordanceProviding

ASCKit/<Concept>/Internal/  (implements the face's protocols)
  SDKApps         SDKBuilds
  SDKTestFlight  SDKAppScreenshots
  ClientFactory            EnvironmentAuthProvider

ASCCommand  (the way in)
  asc apps list            → formatAgentItems  → {"data":[{...,"affordances":{...}}]}
  asc versions list        → formatAgentItems
  asc version-localizations list   → formatAgentItems
  asc screenshot-sets list → formatAgentItems
  asc screenshots list     → formatItems
  asc builds list          → formatItems
  asc testflight groups    → formatItems
  asc testflight testers   → formatItems
  asc auth check
  asc tui                  → TUIApp (@MainActor)
```

---

## Command Tree

```
asc
├── apps list [--limit N]                         Apps.listApps()
├── versions list --app-id <id>                   Apps.listVersions()
├── localizations list --version-id <id>          AppScreenshots.listLocalizations()
├── screenshot-sets list --localization-id <id>   AppScreenshots.listScreenshotSets()
├── screenshots list --set-id <id>                AppScreenshots.listScreenshots()
├── builds list [--app-id <id>]                   Builds.listBuilds()
├── testflight
│   ├── groups  [--app-id <id>]                   TestFlight.listBetaGroups()
│   └── testers [--group-id <id>]                 TestFlight.listBetaTesters()
├── auth check
├── version
└── tui
```

Resource hierarchy the commands mirror:
```
App
└── AppStoreVersion  (one per platform: iOS/macOS/tvOS/watchOS/visionOS)
    └── AppStoreVersionLocalization  (one per locale: en-US, zh-Hans, …)
        └── AppScreenshotSet  (one per display type: iPhone 6.7", iPad 12.9", …)
            └── AppScreenshot
```

---

## Agent-First Output Flow

```
CLI args
  │
  ▼
AsyncParsableCommand.run()
  │
  ├─ ClientProvider.makeXs()
  │         │
  │         ▼
  │   OpenAPI call → map SDK types → ASCKit structs (with parentId injected)
  │
  ├─ OutputFormatter.formatAgentItems(items, ...)
  │         │
  │         ├── JSON mode → DataResponse { data: [WithAffordances<T>] }
  │         │              → {"data":[{...fields..., "affordances":{...cmds...}}]}
  │         ├── table mode → renderTable(headers, rows)
  │         └── markdown   → renderMarkdownTable(headers, rows)
  │
  └─ print(output) → stdout
```

---

## Component Tables

### Standard Feature Table

| Component                | Purpose                   | Inputs              | Outputs              | Dependencies        |
|--------------------------|---------------------------|---------------------|----------------------|---------------------|
| NewDomainModel           | Value type + affordances  | Init params         | Computed props, cmds | None                |
| NewRepository (protocol) | @Mockable DI boundary     | filter params       | [NewModel]           | None                |
| SDKNewRepository         | ASC API adapter           | APIProvider         | [NewModel]           | appstoreconnect-sdk |
| NewCommand               | Top-level command group   | CLI subcommands     | —                    | —                   |
| NewList                  | `list` subcommand         | CLI options         | JSON/table/markdown  | NewRepository       |

### Files to Create/Modify

| File                                                        | Action   | Notes                                        |
|-------------------------------------------------------------|----------|----------------------------------------------|
| `Sources/ASCKit/X/XModel.swift`                            | Create   | Struct + AffordanceProviding                 |
| `Sources/ASCKit/X/Xs.swift`                                | Create   | @Mockable protocol                           |
| `Sources/ASCKit/X/Internal/SDKXs.swift`                    | Create   | Implements Xs, injects parent IDs           |
| `Sources/ASCKit/Shared/Internal/ClientFactory.swift`        | Modify   | Add `makeXs()` factory              |
| `Sources/ASCCommand/Commands/X/XCommand.swift`             | Create   | AsyncParsableCommand group + List subcommand |
| `Sources/ASCCommand/ASC.swift`                             | Modify   | Add XCommand to subcommands                  |
| `Sources/ASCCommand/ClientProvider.swift`                  | Modify   | Add `makeXs()` static factory       |
| `Tests/ASCKitTests/X/XModelTests.swift`                    | Create   | State, computed props, Codable               |
| `Tests/ASCKitTests/X/SDKXsTests.swift`               | Create   | Mock-based repository tests                  |
| `Tests/ASCKitTests/Apps/AffordancesTests.swift`            | Modify   | Add affordance tests for new model           |
| `Tests/ASCKitTests/TestHelpers/MockRepositoryFactory.swift`| Modify   | Add `makeX(...)` factory method              |

---

## Approval Prompt Template

```
## Architecture Review: [Feature Name]

[Diagram]

### Components

| Component | Layer | Purpose |
|-----------|-------|---------|
| ...       | ...   | ...     |

### Files

- `Sources/ASCKit/X/XModel.swift` — ...
- ...

**Proceed with TDD implementation?**
```

Use `AskUserQuestion` with:
- "Approve — proceed with implementation"
- "Modify — I have feedback"