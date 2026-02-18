# Architecture Diagram Patterns

## Table of Contents

- [Three-Layer Pattern](#three-layer-pattern)
- [Full System Overview](#full-system-overview)
- [Command Tree](#command-tree)
- [Agent-First Output Flow](#agent-first-output-flow)
- [Component Tables](#component-tables)
- [Files Checklist](#files-checklist)

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
Domain Layer
  App                AppStoreVersion       AppStoreVersionLocalization
  AppRepository      (+ affordances)       AppScreenshotSet
  BuildRepository    AppStoreVersionState  AppScreenshot
  TestFlight repos   ScreenshotRepository  AffordanceProviding

Infrastructure Layer  (implements Domain protocols)
  SDKAppRepository         SDKBuildRepository
  SDKTestFlightRepository  SDKScreenshotRepository
  ClientFactory            EnvironmentAuthProvider

ASCCommand Layer
  asc apps list            → formatAgentItems  → {"data":[{...,"affordances":{...}}]}
  asc versions list        → formatAgentItems
  asc localizations list   → formatAgentItems
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
├── apps list [--limit N]                         AppRepository.listApps()
├── versions list --app-id <id>                   AppRepository.listVersions()
├── localizations list --version-id <id>          ScreenshotRepository.listLocalizations()
├── screenshot-sets list --localization-id <id>   ScreenshotRepository.listScreenshotSets()
├── screenshots list --set-id <id>                ScreenshotRepository.listScreenshots()
├── builds list [--app-id <id>]                   BuildRepository.listBuilds()
├── testflight
│   ├── groups  [--app-id <id>]                   TestFlightRepository.listBetaGroups()
│   └── testers [--group-id <id>]                 TestFlightRepository.listBetaTesters()
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
  ├─ ClientProvider.makeXRepository()
  │         │
  │         ▼
  │   OpenAPI call → map SDK types → Domain structs (with parentId injected)
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
| `Sources/Domain/X/XModel.swift`                            | Create   | Struct + AffordanceProviding                 |
| `Sources/Domain/X/XRepository.swift`                       | Create   | @Mockable protocol                           |
| `Sources/Infrastructure/X/SDKXRepository.swift`            | Create   | Implements XRepository, injects parent IDs   |
| `Sources/Infrastructure/Client/ClientFactory.swift`        | Modify   | Add `makeXRepository()` factory              |
| `Sources/ASCCommand/Commands/X/XCommand.swift`             | Create   | AsyncParsableCommand group + List subcommand |
| `Sources/ASCCommand/ASC.swift`                             | Modify   | Add XCommand to subcommands                  |
| `Sources/ASCCommand/ClientProvider.swift`                  | Modify   | Add `makeXRepository()` static factory       |
| `Tests/DomainTests/X/XModelTests.swift`                    | Create   | State, computed props, Codable               |
| `Tests/DomainTests/X/XRepositoryTests.swift`               | Create   | Mock-based repository tests                  |
| `Tests/DomainTests/Apps/AffordancesTests.swift`            | Modify   | Add affordance tests for new model           |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift`| Modify   | Add `makeX(...)` factory method              |

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

- `Sources/Domain/X/XModel.swift` — ...
- ...

**Proceed with TDD implementation?**
```

Use `AskUserQuestion` with:
- "Approve — proceed with implementation"
- "Modify — I have feedback"