# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository. It holds only what applies to every task; everything else is linked.

## TDD is non-negotiable (read this first)

**You MUST write a failing test before writing any production code.** This rule overrides every other instinct, including "the change is small", "it's just a one-liner", "I'll add the test after". If you catch yourself opening a file under `Sources/` before a test under `Tests/` exists and fails, stop and reverse course.

**Pre-implementation gate** — before editing anything in `Sources/`, you must have done all of the following in order:

1. Stated the user-facing behaviour in one sentence (e.g. "a version is live when state is `READY_FOR_SALE`").
2. Written a test in `Tests/` that asserts the exact expected output for that behaviour.
3. Run `swift test` (or a `--filter`'d subset) and **observed the test fail** — compile error counts as a failing test only if the assertion is the reason it can't compile (e.g. missing symbol the test names).
4. Reported the red result back to the user (one line is fine: "test X fails with: <message>").

Only after step 4 may you write code under `Sources/`.

**If you skip the gate, you are violating the project's primary rule.** Treat this the same as committing secrets or force-pushing main.

### Testing rules

Chicago School — state-based, not interaction-based: tests verify what domain objects return and compute, not how they call collaborators. Red → green → refactor, every time.

- Name tests `should <outcome> [when <situation>]`, with backticks, in the words of whoever sees the result (person, agent, REST client): `` func `should be live when the version is ready for sale`() ``. Never a method, type or mechanism verb (`returns`, `calls`, `passes`, `maps`). Rename older tests when you touch them; don't sweep. → [Naming tests](.claude/skills/implement-feature/references/tdd-patterns.md#naming-tests)
- Assert exact output values (`"READY_FOR_SALE"`, `"expired": true`), never "is non-empty" or "doesn't throw". Command tests assert the full JSON string.
- Implement just enough to pass — no extra fields, no speculative branches.
- Difficult to test = design problem. Never modify a test to make it pass; if it fails unexpectedly, the spec was wrong.
- `@Testing` (not XCTest); `@Mockable` protocols with `given().willReturn()`; shared test data in `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift`.

## Commands

```bash
swift build                          # debug build (-c release for release)
swift test                           # all tests
swift test --filter 'AppTests'       # tests matching a pattern
swift test --enable-code-coverage    # with coverage
make run ARGS="apps list"            # run the CLI
make docs                            # regenerate docs/commands.md + docs/README.md
make check-docs                      # broken links, doc size budgets
```

## Architecture

Three strict layers, dependencies pointing one way: `ASCCommand → Infrastructure → Domain`.

```
Sources/
├── Domain/          # Pure value types, @Mockable protocols — zero I/O
├── Infrastructure/  # Implements Domain protocols via appstoreconnect-swift-sdk
└── ASCCommand/      # CLI entry (ASC.swift), output formatting, REST server (Commands/Web/), TUI
```

Domain folders mirror the App Store Connect resource hierarchy (`Domain/Apps/Versions/Localizations/…`); Infrastructure and `Tests/` mirror Domain exactly. Look at the tree rather than a list here.

**Rules every change follows:**
- Domain models are `public struct` + `Sendable` + `Equatable` + `Codable`; the JSON encoding is the public schema. Optional text fields use `encodeIfPresent` so nil is omitted.
- Every model carries its **parent ID** (`AppStoreVersion.appId`, `AppScreenshot.setId`). The API doesn't return parent IDs, so Infrastructure mappers inject them from the request.
- State enums expose **semantic booleans** (`isLive`, `isEditable`, `isPending`) for agent decisions.
- **CAEOAS:** every model provides `structuredAffordances` — ready-to-run next commands, state-aware (e.g. `submitForReview` only when `isEditable`). The CLI `affordances` and REST `_links` both derive from it.
- **CLI and REST ship together:** a command that returns data is also exposed by `asc web-server`. A feature isn't done until it is reachable over REST.
- `AppStoreVersionLocalization` (`asc version-localizations`: whatsNew, description, keywords) and `AppInfoLocalization` (`asc app-info-localizations`: name, subtitle, privacy URLs) are different resources with different repositories. Don't mix them up.

Why it's built this way: [docs/design.md](docs/design.md).

## When you are…

- **adding a feature** → `implement-feature` skill (architecture approval, TDD phases, REST exposure checklist, docs)
- **improving an existing one** → `improvement` skill
- **fixing a bug** → `fix-bug` skill
- **touching docs** → [docs/documentation-design](docs/documentation-design/README.md). In short: new feature = `docs/features/<x>/README.md` + one CHANGELOG line + `make docs`; fix = one CHANGELOG line. Never hand-edit `docs/commands.md` or `docs/README.md`.
- **working with auth or credentials** → [docs/features/asc-auth](docs/features/asc-auth/README.md) (`~/.asc/credentials.json` first, then `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_PRIVATE_KEY_PATH` env vars, via `CompositeAuthProvider`)
- **working with iris (private API)** → [docs/features/iris](docs/features/iris/README.md)
