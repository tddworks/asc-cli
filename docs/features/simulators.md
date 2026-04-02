# Simulators

Manage local iOS simulators from the CLI — list, boot, and shutdown.

Streaming and interaction features are available via the [ASC Pro plugin](plugin-ui-architecture.md).

## CLI Usage

### List Simulators

```bash
asc simulators list [--booted] [--output json|table|markdown] [--pretty]
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--booted` | `false` | Show only booted simulators |
| `--output` | `json` | Output format: json, table, markdown |
| `--pretty` | `false` | Pretty-print JSON output |

**Examples:**

```bash
# List all available iOS simulators
asc simulators list --output table

# List only booted simulators
asc simulators list --booted --pretty
```

**Table output:**

```
UDID                                  Name                State     Runtime
----                                  ----                -----     -------
CF65871E-B600-40CB-8B18-B6B7101D38E1  iPhone 16 Pro Max   Booted    iOS 18.2
8A35796A-5F41-4933-BBD7-307089EDD509  iPad (10th gen)     Shutdown  iOS 18.2
```

**JSON output (with affordances):**

```json
{
  "data" : [
    {
      "id" : "CF65871E-B600-40CB-8B18-B6B7101D38E1",
      "name" : "iPhone 16 Pro Max",
      "state" : "Booted",
      "runtime" : "com.apple.CoreSimulator.SimRuntime.iOS-18-2",
      "displayRuntime" : "iOS 18.2",
      "isBooted" : true,
      "affordances" : {
        "shutdown" : "asc simulators shutdown --udid CF65871E-...",
        "stream" : "asc simulators stream --udid CF65871E-...",
        "listSimulators" : "asc simulators list"
      }
    }
  ]
}
```

> Note: The `stream` affordance only appears when the ASC Pro plugin is installed.

---

### Boot Simulator

```bash
asc simulators boot --udid <udid>
```

---

### Shutdown Simulator

```bash
asc simulators shutdown --udid <udid>
```

---

## Typical Workflow

```bash
# 1. List simulators and pick one
asc simulators list --output table

# 2. Boot if needed
asc simulators boot --udid CF65871E-B600-40CB-8B18-B6B7101D38E1

# 3. Shutdown when done
asc simulators shutdown --udid CF65871E-B600-40CB-8B18-B6B7101D38E1
```

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  ASCCommand                      │
│  SimulatorsCommand                               │
│  ├── SimulatorsList     (list [--booted])        │
│  ├── SimulatorsBoot     (boot --udid X)          │
│  └── SimulatorsShutdown (shutdown --udid X)      │
└──────────────┬──────────────────────────────────┘
               │ uses
               ▼
┌─────────────────────────────────────────────────┐
│              Infrastructure                      │
│  SimctlSimulatorRepository (xcrun simctl)        │
└──────────────┬──────────────────────────────────┘
               │ implements
               ▼
┌─────────────────────────────────────────────────┐
│              Domain                              │
│  Simulator, SimulatorState, SimulatorFilter       │
│  SimulatorRepository (@Mockable)                  │
│  AffordanceRegistry (plugin extensible)           │
└─────────────────────────────────────────────────┘
```

Streaming, interaction, and device bezels are provided by the ASC Pro plugin.
See [Plugin Architecture](plugin-ui-architecture.md) for details.

---

## Domain Models

### Simulator

```swift
public struct Simulator: Sendable, Equatable, Identifiable, Codable {
    public let id: String       // UDID
    public let name: String     // "iPhone 16 Pro Max"
    public let state: SimulatorState
    public let runtime: String  // "com.apple.CoreSimulator.SimRuntime.iOS-18-2"

    public var isBooted: Bool       // state == .booted
    public var displayRuntime: String  // "iOS 18.2"
}
```

### SimulatorState

```swift
public enum SimulatorState: String, Codable {
    case booted = "Booted"
    case shutdown = "Shutdown"
    case shuttingDown = "Shutting Down"
    case creating = "Creating"

    public var isBooted: Bool
    public var isAvailable: Bool  // booted or shutdown
}
```

### Affordances

Built-in affordances are state-aware. Plugins extend them via `AffordanceRegistry`:

| State | Built-in | Plugin (ASC Pro) |
|-------|----------|-----------------|
| `shutdown` | `boot`, `listSimulators` | — |
| `booted` | `shutdown`, `listSimulators` | `stream` |

---

## File Map

### Sources

```
Sources/
├── Domain/Simulators/
│   ├── Simulator.swift
│   ├── SimulatorState.swift
│   └── SimulatorRepository.swift
├── Domain/Shared/
│   └── AffordanceRegistry.swift
├── Infrastructure/Simulators/
│   └── SimctlSimulatorRepository.swift
└── ASCCommand/Commands/Simulators/
    ├── SimulatorsCommand.swift
    ├── SimulatorsList.swift
    ├── SimulatorsBoot.swift
    └── SimulatorsShutdown.swift
```

### Tests

```
Tests/
├── DomainTests/Simulators/
│   └── SimulatorTests.swift
└── ASCCommandTests/Commands/Simulators/
    ├── SimulatorsListTests.swift
    ├── SimulatorsBootTests.swift
    └── SimulatorsShutdownTests.swift
```

---

## Testing

```bash
swift test --filter 'Simulator'
```

---

## Prerequisites

- **Xcode** — provides `xcrun simctl` for simulator management
