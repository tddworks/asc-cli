# Architecture Diagram Patterns

ASCII diagrams for documenting feature architecture before implementation.

## Table of Contents

- [Layered Architecture](#layered-architecture)
- [Data Flow Diagrams](#data-flow-diagrams)
- [Sequence Diagrams](#sequence-diagrams)
- [Component Interaction Tables](#component-interaction-tables)

---

## Layered Architecture

### Three-Layer Pattern (asc-swift Standard)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FEATURE: [Feature Name]                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EXTERNAL              INFRASTRUCTURE           DOMAIN               │
│  ┌─────────────┐       ┌─────────────────┐     ┌─────────────────┐  │
│  │  ASC API    │──────▶│  OpenAPI[X]     │────▶│  [DomainModel]  │  │
│  │  endpoint   │       │  Repository     │     │  (struct)       │  │
│  └─────────────┘       │  (implements    │     └─────────────────┘  │
│                        │   [X]Repository)│             │             │
│                        └─────────────────┘             ▼             │
│                                                ┌─────────────────┐  │
│                                                │ [X]Repository   │  │
│                                                │ (protocol)      │  │
│                                                └─────────────────┘  │
│                                                         │            │
│                                                         ▼            │
│                        ┌───────────────────────────────────────┐    │
│                        │  ASCCommand Layer                       │    │
│                        │  ┌─────────────────────────────────┐   │    │
│                        │  │  [X]Command (AsyncParsableCmd)  │   │    │
│                        │  └─────────────────────────────────┘   │    │
│                        └───────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Full System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          asc-swift System                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                         Domain Layer                                │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │ │
│  │  │ App          │  │ Build        │  │ BetaGroup / BetaTester   │  │ │
│  │  │ (struct)     │  │ (struct)     │  │ (structs)                │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │ │
│  │  │AppRepository │  │BuildRepository  │TestFlightRepository      │  │ │
│  │  │ (protocol)   │  │ (protocol)   │  │ (protocol)               │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                    ▲                                     │
│                                    │ implements                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                      Infrastructure Layer                           │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │ │
│  │  │ OpenAPIApp       │  │ OpenAPIBuild     │  │ OpenAPITestFlight │  │ │
│  │  │ Repository       │  │ Repository       │  │ Repository       │  │ │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘  │ │
│  │  ┌──────────────────────────┐  ┌────────────────────────────────┐  │ │
│  │  │ ClientFactory            │  │ EnvironmentAuthProvider        │  │ │
│  │  └──────────────────────────┘  └────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                    ▲                                     │
│                                    │ uses                                │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                       ASCCommand Layer                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │ │
│  │  │ AppsCommand  │  │BuildsCommand │  │ TestFlightCommand        │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘  │ │
│  │  ┌──────────────────┐  ┌────────────────────────────────────────┐  │ │
│  │  │ TUICommand       │  │ OutputFormatter / ClientProvider       │  │ │
│  │  └──────────────────┘  └────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### API Fetch Data Flow

```
┌───────────┐     ┌────────────┐     ┌───────────────┐     ┌───────────┐
│  ASC API  │────▶│  OpenAPI   │────▶│  Map SDK type │────▶│  Domain   │
│  endpoint │     │  Request   │     │  → struct     │     │  Model    │
└───────────┘     └────────────┘     └───────────────┘     └───────────┘
    Raw              Fetch             Transform            Value Type
   JSON Data          Data              Data              (App/Build/etc)
```

### Command Execution Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        COMMAND EXECUTION                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CLI Input ──▶ AsyncParsableCommand ──▶ Repository.fetch()          │
│                      │                         │                    │
│                      │                         ▼                    │
│                      │               ┌─────────────────┐            │
│                      │               │  OpenAPI call   │            │
│                      │               └─────────────────┘            │
│                      │                         │                    │
│                      │                         ▼                    │
│                      │               ┌─────────────────┐            │
│                      │               │  Map to domain  │            │
│                      │               │  value types    │            │
│                      │               └─────────────────┘            │
│                      │                         │                    │
│                      ▼                         ▼                    │
│             ┌─────────────────┐     ┌─────────────────────────┐    │
│             │ OutputFormatter │◀────│  [App]/[Build]/[Group]  │    │
│             │ (JSON/Table/MD) │     └─────────────────────────┘    │
│             └─────────────────┘                                     │
│                      │                                               │
│                      ▼                                               │
│             ┌─────────────────┐                                     │
│             │  stdout output  │                                      │
│             └─────────────────┘                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Error Handling Flow

```
┌──────────┐     ┌────────────┐     ┌─────────────┐     ┌──────────────┐
│  Adapter │────▶│ API Request│────▶│   Success   │────▶│ Return [T]   │
└──────────┘     └────────────┘     └─────────────┘     └──────────────┘
                      │
                      ▼ (failure)
               ┌─────────────┐     ┌────────────────────────┐
               │ Catch Error │────▶│ Map to APIError /      │
               └─────────────┘     │ AuthError              │
                                   └────────────────────────┘
                                              │
                                              ▼
                                   ┌─────────────────────┐
                                   │ CommandError message │
                                   │ printed to stderr   │
                                   └─────────────────────┘
```

---

## Sequence Diagrams

### User Runs `asc apps list`

```
User      ASC.swift    AppsCommand    AppRepository    OutputFormatter
  │           │              │               │                │
  │──asc apps▶│              │               │                │
  │           │──route()────▶│               │                │
  │           │              │──fetchApps()─▶│                │
  │           │              │               │──OpenAPI──▶ API│
  │           │              │               │◀──JSON─────────│
  │           │              │               │──map [App]────▶│
  │           │◀──[App]──────│◀──[App]───────│                │
  │           │              │──format()──────────────────────▶
  │◀──output──│              │               │◀──string───────│
```

### Auth Check Flow

```
User      AuthCommand    AuthProvider    EnvironmentVars
  │           │               │                │
  │──asc auth▶│               │                │
  │           │──credentials()▶               │
  │           │               │──read env─────▶│
  │           │               │◀──values───────│
  │           │◀──credentials─│                │
  │◀──✓ valid─│               │                │
```

---

## Component Interaction Tables

### Standard Table Format

```
| Component                | Purpose                   | Inputs            | Outputs         | Dependencies         |
|--------------------------|---------------------------|-------------------|-----------------|----------------------|
| NewDomainModel           | Value type with behavior  | Init params       | Computed props  | None                 |
| NewRepository (protocol) | Data access boundary      | filter params     | [NewModel]      | None (DI boundary)   |
| OpenAPINewRepository     | API adapter               | APIProvider       | [NewModel]      | appstoreconnect-sdk  |
| NewCommand               | CLI subcommand            | CLI args/options  | stdout output   | NewRepository        |
```

### Files to Create/Modify Table

```
| File Path                                           | Action   | Description                             |
|-----------------------------------------------------|----------|-----------------------------------------|
| Sources/Domain/New/NewModel.swift                   | Create   | Domain value type with behavior         |
| Sources/Domain/New/NewRepository.swift              | Create   | @Mockable repository protocol           |
| Sources/Infrastructure/New/OpenAPINewRepository.swift | Create | Implements NewRepository using SDK      |
| Sources/ASCCommand/Commands/New/NewCommand.swift    | Create   | AsyncParsableCommand group              |
| Sources/ASCCommand/Commands/New/NewList.swift       | Create   | List subcommand                         |
| Sources/ASCCommand/ASC.swift                        | Modify   | Add NewCommand to subcommands           |
| Sources/ASCCommand/ClientProvider.swift             | Modify   | Factory method for NewRepository        |
| Tests/DomainTests/New/NewModelTests.swift           | Create   | Domain model behavior tests             |
| Tests/InfrastructureTests/New/OpenAPINewTests.swift | Create   | Adapter mapping tests                   |
```

---

## Approval Prompt Template

After presenting the architecture, ask for user approval:

```
## Architecture Review

I've designed the architecture for [Feature Name]:

[Diagram Here]

### Components Summary

| Component | Layer          | Purpose  |
|-----------|----------------|----------|
| [Name]    | Domain/Infra/ASCCommand | [Desc] |

### Files to Create/Modify

- `Sources/Domain/New/NewModel.swift` - [Description]
- `Sources/Infrastructure/New/OpenAPINewRepository.swift` - [Description]
- `Tests/DomainTests/New/NewModelTests.swift` - [Description]

**Ready to proceed with TDD implementation?**
```

Use AskUserQuestion with:
- "Approve - proceed with implementation"
- "Modify - I have feedback on the design"