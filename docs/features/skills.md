# Skills Management

Manage Claude Code agent skills from the asc-cli repository. Browse available skills, install them into your agent, check for updates, and keep them current.

## CLI Usage

### List Available Skills

```bash
asc skills list
```

Lists all available skills from the `tddworks/asc-cli-skills` repository. Delegates to `npx skills add tddworks/asc-cli-skills --list`.

### Install Skills

```bash
# Install a specific skill by name
asc skills install --name asc-cli

# Install all available skills
asc skills install --all

# Install all (default when no flags)
asc skills install
```

Delegates to `npx --yes skills add tddworks/asc-cli-skills`.

### Show Installed Skills

```bash
asc skills installed
asc skills installed --pretty
```

Reads `~/.claude/skills/` directory, parses SKILL.md frontmatter, and returns structured JSON with affordances.

**Example output (JSON):**

```json
{
  "data" : [
    {
      "affordances" : {
        "listSkills" : "asc skills list",
        "uninstall" : "asc skills uninstall --name asc-cli"
      },
      "description" : "App Store Connect CLI skill",
      "id" : "asc-cli",
      "isInstalled" : true,
      "name" : "asc-cli"
    }
  ]
}
```

### Uninstall a Skill

```bash
asc skills uninstall --name asc-cli
```

Removes the skill directory from `~/.claude/skills/`.

### Check for Updates

```bash
asc skills check
```

Delegates to `npx skills check`. Returns one of:
- "All skills are up to date."
- "Skill updates are available. Run 'asc skills update' to refresh installed skills."
- "Skills CLI is not available. Install with: npm install -g skills"

### Update Skills

```bash
asc skills update
```

Delegates to `npx skills update`.

## Auto-Update Checker

On every `asc` command run, a non-blocking update check may execute in the background.

### Guard Rails (bail early if any hit)

| Condition | Action |
|-----------|--------|
| `ASC_SKIP_SKILL_CHECK=true` | Skip |
| `CI` or `CONTINUOUS_INTEGRATION` env var set | Skip |
| Last check < 24h ago | Skip |

### Check Flow

1. Runs `npx skills check` (or `skills check` if binary is on PATH)
2. Parses stdout for keywords:
   - `"all skills are up to date"` → no update
   - `"no update"` → no update
   - `"update"` + `"available"` → updates available
   - anything else → no update
3. If updates found → prints hint to stderr
4. Saves `skillsCheckedAt` timestamp to `~/.asc/skills-config.json`

### Timestamp Persistence

| Outcome | Persist? | Why |
|---------|----------|-----|
| Success (up to date) | Yes | Normal cooldown |
| Success (updates available) | Yes | Normal cooldown |
| Unavailable | No | Tool not installed, retry next time |

## Typical Workflow

```bash
# First time: install all asc skills
asc skills install --all

# Browse what's available
asc skills list

# Check what you have
asc skills installed --pretty

# Periodically check for updates
asc skills check

# Update when available
asc skills update

# Remove a skill you don't need
asc skills uninstall --name asc-game-center
```

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│ ASCCommand                                               │
│  SkillsCommand ─┬─ SkillsList       (list available)     │
│                 ├─ SkillsInstall     (install by name/all)│
│                 ├─ SkillsUninstall   (remove installed)   │
│                 ├─ SkillsInstalled   (show installed)     │
│                 ├─ SkillsCheck       (check for updates)  │
│                 └─ SkillsUpdate      (update skills)      │
│                                                          │
│  SkillUpdateChecker.checkIfNeeded()                         │
│  ← auto-check on every asc run (24h cooldown, silent)    │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────────┐
│ Infrastructure                                           │
│  ProcessSkillRepository (shells out to npx/skills)       │
│  FileSkillConfigStorage (~/.asc/skills-config.json)      │
│  ShellRunner / SystemShellRunner                         │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────────┐
│ Domain                                                   │
│  Skill (id, name, description, isInstalled)              │
│  SkillCheckResult (upToDate/updatesAvailable/unavailable)│
│  SkillConfig (skillsCheckedAt: Date?)                    │
│  SkillRepository (@Mockable protocol)                    │
│  SkillConfigStorage (@Mockable protocol)                 │
└──────────────────────────────────────────────────────────┘
```

## Domain Models

### Skill

```swift
public struct Skill: Sendable, Equatable, Identifiable, Codable {
    public let id: String           // = name
    public let name: String
    public let description: String
    public let isInstalled: Bool
}
```

**Affordances:**
- `listSkills` → `asc skills list` (always)
- `install` → `asc skills install --name <name>` (when `!isInstalled`)
- `uninstall` → `asc skills uninstall --name <name>` (when `isInstalled`)

### SkillCheckResult

```swift
public enum SkillCheckResult: String, Sendable, Equatable, Codable {
    case upToDate
    case updatesAvailable
    case unavailable
}
```

### SkillConfig

```swift
public struct SkillConfig: Sendable, Equatable, Codable {
    public var skillsCheckedAt: Date?  // omitted from JSON when nil
}
```

## File Map

### Sources

```
Sources/
├── Domain/Skills/
│   ├── Skill.swift              — model + AffordanceProviding
│   ├── SkillCheckResult.swift   — update check outcome enum
│   ├── SkillConfig.swift        — persisted config (custom Codable)
│   ├── SkillRepository.swift    — @Mockable protocol
│   └── SkillConfigStorage.swift — @Mockable storage protocol
├── Infrastructure/Skills/
│   ├── ProcessSkillRepository.swift  — shells out to npx/skills
│   ├── FileSkillConfigStorage.swift  — ~/.asc/skills-config.json
│   └── ShellRunner.swift             — ShellRunner protocol + SystemShellRunner
└── ASCCommand/Commands/Skills/
    ├── SkillsCommand.swift       — parent command group
    ├── SkillsList.swift          — asc skills list
    ├── SkillsInstall.swift       — asc skills install
    ├── SkillsUninstall.swift     — asc skills uninstall
    ├── SkillsInstalled.swift     — asc skills installed
    ├── SkillsCheck.swift         — asc skills check
    ├── SkillsUpdate.swift        — asc skills update
    └── SkillUpdateChecker.swift  — auto-check on every run
```

### Tests

```
Tests/
├── DomainTests/Skills/
│   └── SkillTests.swift
├── InfrastructureTests/Skills/
│   ├── FileSkillConfigStorageTests.swift
│   ├── ProcessSkillRepositoryTests.swift
│   └── StubShellRunner.swift
└── ASCCommandTests/Commands/Skills/
    ├── SkillsListTests.swift
    ├── SkillsInstallTests.swift
    ├── SkillsUninstallTests.swift
    ├── SkillsInstalledTests.swift
    ├── SkillsCheckTests.swift
    ├── SkillsUpdateTests.swift
    └── SkillUpdateCheckerTests.swift
```

### Wiring Files

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | `makeSkillRepository()`, `makeSkillConfigStorage()` |
| `Sources/ASCCommand/ClientProvider.swift` | Static wrappers for skill factories |
| `Sources/ASCCommand/ASC.swift` | `SkillsCommand.self` in subcommands |

## Testing

```bash
# Run all skill tests
swift test --filter 'Skill'

# Run specific test suite
swift test --filter 'SkillUpdateCheckerTests'
```

Representative test:

```swift
@Test func `installed skill affordances include uninstall but not install`() {
    let skill = MockRepositoryFactory.makeSkill(name: "asc-cli", isInstalled: true)
    #expect(skill.affordances["uninstall"] == "asc skills uninstall --name asc-cli")
    #expect(skill.affordances["install"] == nil)
}
```
