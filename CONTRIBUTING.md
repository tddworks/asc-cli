# Contributing

## Build & test

Requires Swift 6.2+ on macOS 14+.

```bash
git clone https://github.com/tddworks/asc-cli.git && cd asc-cli
swift build                       # debug build
swift test                        # all tests
swift test --filter 'AppTests'    # a subset
make run ARGS="apps list"         # run the CLI
swift format --in-place --recursive Sources Tests

swift build -c release && cp .build/release/asc /usr/local/bin/   # install from source
```

## How the code is organised

Concept folders, not layers. Imports point one way: `ASCCommand → ASCKit`.

```
Sources/
├── ASCKit/<Concept>/  # public face: models, @Mockable repositories — zero I/O
│   └── Internal/      # SDK adapters (appstoreconnect-swift-sdk), parent ID injection
└── ASCCommand/        # CLI commands, REST server, output formatting, TUI
```

`Tests/ASCKitTests/` mirrors `Sources/ASCKit/`. The layout's rules: [concept-folders design](docs/features/concept-folders/design.md).

Why it's built this way (CAEOAS, rich domain models, parent IDs): [docs/design.md](docs/design.md).

## Rules

- **Apache 2.0.** By opening a pull request you agree that your contribution is licensed under the [Apache License 2.0](LICENSE), like the rest of asc-cli.
- **Tests first.** Write a failing test before any production code (Chicago-school, state-based, `@Testing`). See the gate at the top of [CLAUDE.md](CLAUDE.md).
- **CLI and REST ship together.** A command that returns data is also exposed by `asc web-server`. The step-by-step checklist is in the [implement-feature skill](.claude/skills/implement-feature/SKILL.md).

## Docs

Docs follow [docs/documentation-design](docs/documentation-design/README.md). In short:

| Change | Update |
|---|---|
| New feature | `docs/features/<x>/README.md` with a `description`, one CHANGELOG line, `make docs` |
| New or changed flag | Nothing by hand; `make docs` regenerates [docs/commands.md](docs/commands.md) |
| Improvement | The affected feature doc section, one CHANGELOG line |
| Bug fix | One CHANGELOG line |

`make check-docs` reports broken links and size budgets.

## Dependencies

[appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk) · [swift-argument-parser](https://github.com/apple/swift-argument-parser) · [Hummingbird](https://github.com/hummingbird-project/hummingbird) · [TauTUI](https://github.com/steipete/TauTUI) · [Mockable](https://github.com/Kolos65/Mockable) · [SweetCookieKit](https://github.com/steipete/SweetCookieKit)
