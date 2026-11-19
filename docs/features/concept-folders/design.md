---
description: The source layout reworked from layers (Domain/, Infrastructure/) to concept folders — one ASCKit module where each App Store Connect concept holds its public face at the top, its implementations in Internal/, and the bare outside call in Internal/System/. Evidence from today's code, the target tree, the rules and their owners, and the refactor as one-PR steps.
---

# Concept folders, not layers

**Status: BUILT** — steps 1–5: one `ASCKit` module in concept folders; docs and skills follow; one composition root, held by a test; every adapter's decisions tested with only the bare call in `Internal/System/`; `Repository` for CRUD, role nouns for workflows. asc-cli is split by layer: `Sources/Domain/`
and `Sources/Infrastructure/` are two modules that mirror each other folder
for folder. Every concept therefore lives in two places, and every change to
one touches both trees. The goal, stated as a test:

> **A concept is one folder.** Adding or changing a resource (a model, its
> repository, its SDK adapter, its tests) touches `Sources/ASCKit/<Concept>/`
> and `Tests/ASCKitTests/<Concept>/` and nothing else below the way in.

| For | Read |
|---|---|
| why the CLI is built this way (CAEOAS, parent ids) | [docs/design.md](../../design.md) |
| how the REST server is wired | [web-server-architecture](../web-server-architecture/design.md) |
| the pattern this follows | `.claude/skills/app-implement-feature/SKILL.md` |

## 1 · What's wrong today (measured on `main`, f75d42821)

| Cost | Evidence | What it costs a change |
|---|---|---|
| **A concept lives in two trees** | `Domain/` 269 files and `Infrastructure/` 107 files mirror each other: `Domain/Apps/Builds/` beside `Infrastructure/Apps/Builds/`, 17 concept folders each side | one feature opens two folder trees and two test targets (`DomainTests`, `InfrastructureTests`) |
| **The two trees already disagree** | `Domain/Screenshots/` is implemented by `Infrastructure/ScreenshotPlans/`; `Infrastructure/Client/`, `Web/` and `Iris/Auth/` have no Domain twin | finding an implementation means knowing a second name |
| **The module split is paid for by hand** | 613 `Domain.X` qualifiers in 69 files, to tell a Domain type from the SDK type of the same name (`Domain.Territory` vs the SDK's `Territory`) | every new adapter repeats the qualifier dance |
| **Implementations leak to the way in** | `ASCCommand` imports `Infrastructure` in 80 files; outside `ClientProvider`, 14 files name 12 implementation types (22 uses) — `FileAuthStorage()` in 10 auth and report commands, and `RESTRoutes` builds its own `CompositeAuthProvider`, `ClientFactory` and five more | swapping an implementation (keychain auth storage, another renderer) edits every command that names it |
| **The outside call is mixed with decisions** | the SDK adapters are already split right: they depend on the narrow `APIClient` role, whose real implementation is the SDK's own `APIProvider`, and 472 tests drive them through `StubAPIClient`. The rest are not: seven adapters (`ShellRunner`, `IrisClient`, `WebKitHTMLRenderer`, `BrowserIrisCookieProvider`, `IrisSDKAppBundleRepository`, `IrisSDKSignIn`, `MarketplacePlugins`, ~860 lines) hold their decisions beside a `Process`, `URLSession`, WebKit or cookie call, and `codecov.yml` skips each by file path | their decisions — argv, environment, status → error, parsing — have no test |

## 2 · The shape — outside to inside

```
        asc <command>            asc web-server (REST + _links)        asc tui
              │                            │                              │
              └────────────────────────────┴──────────────────────────────┘
                                           │   parse, call one concept, render
                                           ▼
  ASCCommand/          THE WAY IN — commands, output formatting, the TUI, the composition root (ClientProvider)
                                           │   imports the public face only
                                           ▼
  ASCKit/<Concept>/    WHAT IT IS — models, state enums with semantic booleans, affordances,
                       @Mockable repositories; the CLI and REST both derive from these
                                           │
  ASCKit/<Concept>/Internal/          HOW IT WORKS — SDK adapters, DTO mapping, file storage
                                           │
  ASCKit/<Concept>/Internal/System/   THE BARE CALL — the SDK request, URLSession, WebKit, SRP; ≤100 lines
                                           ▼
                              App Store Connect API · iris · the file system
```

```
Sources/
├── ASCCommand/                   THE WAY IN (unchanged)
├── ASCPlugin/                    the plugin SDK third parties link (unchanged)
└── ASCKit/                       ONE module, one folder per App Store Connect concept
    ├── Shared/                   the kernel: Affordance, APIError, OutputFormat, pagination, RESTPathResolver
    │   └── Internal/             APIClient, ClientFactory, HTTPPerforming, SDKFilter, uploads
    ├── Apps/
    │   ├── App.swift  AppRepository.swift  App+RESTRoutes.swift      public face
    │   ├── Internal/OpenAPIAppRepository.swift                        implementation
    │   ├── Builds/
    │   │   ├── Build.swift  BuildRepository.swift …                    public face
    │   │   └── Internal/SDKBuildRepository.swift …                    implementation
    │   ├── Versions/  TestFlight/  InAppPurchases/  Subscriptions/  …  (same shape, nested as today)
    ├── Auth/            Internal/  (FileAuthProvider, EnvironmentAuthProvider, CompositeAuthProvider)
    ├── Iris/            Internal/  Internal/Auth/  Internal/Auth/SRP/
    ├── Screenshots/     Internal/  (was Infrastructure/ScreenshotPlans/)
    ├── Web/             the REST server (ASCWebServer, CORS, routes)
    └── CodeSigning/  GameCenter/  Plugins/  Projects/  Reports/  Simulators/
        Skills/  Submissions/  Territories/  Users/  XcodeCloud/  AppWall/
Tests/
├── ASCKitTests/                  mirrors Sources/ASCKit/ folder for folder (was DomainTests + InfrastructureTests)
└── ASCCommandTests/              unchanged
```

| Part | Holds | Access | Tested how |
|---|---|---|---|
| `<Concept>/` | models, state enums, affordances, `@Mockable` repositories, `+RESTRoutes` | `public` | 100%, state-based |
| `<Concept>/Internal/` | the SDK adapters, DTO mappers, file storage — every decision about the outside | `public` only where `ASCCommand`'s composition root builds it; otherwise `internal` | via `MockAPIClient` / the role's mock |
| `<Concept>/Internal/System/` | the irreducible call: the SDK request, `URLSession`, `WebKit`, SRP | `internal` | integration only; the one folder coverage leaves out |
| `ASCCommand/` | parse, call, render; the composition root | — | command tests assert the full output |

## 3 · The rules, each with one owner

| Rule | Owner — and how it's checked |
|---|---|
| **A concept is one folder**: its face, its `Internal/`, its tests | the tree (§2); no `Domain/` or `Infrastructure/` folder exists |
| **Imports flow inward**: `ASCCommand → ASCKit`; a concept may use another's public face, never its `Internal/` | the module graph; a grep for `/Internal/` type names outside their concept |
| **Only the composition root names an `Internal/` type** | `ASCCommand/ClientProvider.swift`; `CompositionRootTests` fails, naming the file and type, when any other `ASCCommand` file names one |
| **The bare call is ≤100 lines with no decisions** | `Internal/System/`; a decision found there moves up into `Internal/` with a test |
| **Every model carries its parent id; affordances are state-aware; CLI and REST ship together** | unchanged — [CLAUDE.md](../../../CLAUDE.md) still owns these |

## 4 · Adding a resource, under this design

| Step | Touches |
|---|---|
| the model, its repository, its affordances | `ASCKit/<Concept>/<Resource>.swift` (+ test beside it in `ASCKitTests/<Concept>/`) |
| the SDK adapter | `ASCKit/<Concept>/Internal/SDK<Resource>Repository.swift` (+ test) |
| wiring | one factory in `ClientProvider` |
| the command and the route | `ASCCommand/Commands/<x>/`, `<Concept>/<Resource>+RESTRoutes.swift` |

Contrast with today: the same resource is split over `Domain/`, `Infrastructure/`,
`DomainTests/` and `InfrastructureTests/`.

## 5 · The refactor, step by step

Each step is one PR: green (`swift test`, `make check-docs`), no behaviour a
user sees changed. A pure move adds no behaviour, so the existing tests are its
safety net; any step that moves a rule writes its test first.

| # | Step | Today | Change | Test first |
|---|---|---|---|---|
| 0 | **this doc** | — | the target tree and rules | — |
| 1 | **one module, concept folders** ✓ | `Domain` + `Infrastructure` targets, `DomainTests` + `InfrastructureTests` | `git mv` into `Sources/ASCKit/<Concept>/` and `<Concept>/Internal/`; `ScreenshotPlans` → `Screenshots/Internal/`; `Client` + infra `Shared` → `Shared/Internal/`; one `ASCKit` target, one `ASCKitTests`; `import Domain`/`Infrastructure` → `import ASCKit`; `Domain.X` → `ASCKit.X`. Library users and `examples/blitz-screenshots` change two imports to one (CHANGELOG line, `docs/library.md`) | — (move only; 787+ tests stay green) |
| 2 | **docs and skills follow** ✓ | `CLAUDE.md`, `docs/design.md`, `implement-feature` / `fix-bug` / `improvement` skills describe `Domain → Infrastructure` (16 files) | describe concept folders; link this doc | — |
| 3 | **one composition root** ✓ | 22 uses of 12 `Internal/` types in 14 `ASCCommand` files outside `ClientProvider`; `RESTRoutes` wires its own `ClientFactory` | `ClientProvider` gains `makeAuthStorage`, `makeEnvironmentAuthProvider`, `makeXcodeBuildRunner`, `makeProjectConfigStorage`; commands and `RESTRoutes` ask it for the public protocol | "should build every concept's Internal implementation only in the composition root" |
| 4 | **`Internal/System/` per adapter** ✓ (one commit each) | seven untested adapters mix decisions with I/O; `codecov.yml` lists each file | each adapter's decisions become a tested value or orchestrator in `Internal/`; only the call stays, ≤100 lines, in `Internal/System/`; the per-file ignores become one `**/Internal/System/**` rule. The SDK adapters stay as they are | per adapter, its decisions: e.g. "should add the given variables on top of the inherited environment" |
| 5 | **names for roles** ✓ | 75 `XxxRepository` protocols, 11 of which run a workflow rather than CRUD | `XxxRepository` stays for the 64 CRUD protocols. The 11 workflows take role nouns: `IrisSignIn`, `Reports`, `ReviewSubmissions`, `InAppPurchaseSubmissions`, `SubscriptionSubmissions`, `IrisInAppPurchaseSubmissions`, `AppWall`, `Simulators`, `Skills`, `Plugins`, `Themes`; their implementations, mocks and `make…` factories follow. `XxxProvider`s stay | none — behaviour unchanged; 2,958 tests before and after |

Step 1 removes most of §1's cost on its own; 3 and 4 make the fence real; 5 is
cosmetic and can wait.

## 6 · Decided

- **`Web/`** stays in `ASCKit/Web/` for step 1, so the step is a pure move.
  Whether it moves out to the way in is still open (below).
- **Library users break cleanly**: one CHANGELOG line, no `Domain` /
  `Infrastructure` re-export shims.
- **`MOCKING` in release builds** is its own fix, not part of this refactor.

## 7 · Open

- **`Web/`** — the REST server is a *way in*, like `ASCCommand`. Move it into
  `ASCCommand/` (or its own module), or keep it in `ASCKit` because plugins
  mount routes on it?
- **`MOCKING` in release builds** — the `ASCKit` target defines it
  unconditionally (inherited from `Domain`), so mocks ship in `asc`.
- **`IdmsaAPIClient`'s wire** — 46% covered; its own HTTP tests miss most of
  sign-in-complete and verify. Its URLProtocol tests are the right tool there:
  they pin the bytes Apple expects.
- **The other iris repositories' tests** still drive a real `IrisClient` through
  `URLProtocol` stubs; they can move onto `MockIrisAPI` as they are touched.
