# Plugin Market

Browse, install, and manage dylib plugins that extend the ASC CLI and web server.

Plugins are listed in the **[tddworks/asc-registry](https://github.com/tddworks/asc-registry)** registry. Developers submit PRs to add their plugins.

## Registry — `tddworks/asc-registry`

The plugin marketplace is powered by a single `registry.json` file hosted at:

```
https://raw.githubusercontent.com/tddworks/asc-registry/main/registry.json
```

### registry.json format

```json
{
  "plugins": [
    {
      "id": "asc-pro",
      "name": "ASC Pro",
      "version": "1.0",
      "description": "Simulator streaming, interaction & tunnel sharing",
      "author": "tddworks",
      "repositoryURL": "https://github.com/tddworks/asc-registry",
      "downloadURL": "https://github.com/tddworks/asc-registry/releases/latest/download/ASCPro.plugin.zip",
      "categories": ["simulators", "streaming"]
    }
  ]
}
```

### Field reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique plugin identifier (used in `asc plugins install --name <id>`) |
| `name` | Yes | Human-readable display name |
| `version` | Yes | Current version string |
| `description` | Yes | Short description of what the plugin does |
| `author` | No | Author or organization name |
| `repositoryURL` | No | Link to source code |
| `downloadURL` | Yes | Direct URL to `.plugin.zip` bundle (typically a GitHub release asset) |
| `categories` | No | Tags for search filtering (e.g. `["simulators", "streaming"]`) |

### Submitting a plugin

1. Build your plugin as a `.plugin` bundle (dylib + manifest.json + ui/)
2. Publish a `.plugin.zip` release asset on your GitHub repo
3. Fork [tddworks/asc-registry](https://github.com/tddworks/asc-registry)
4. Add your plugin entry to `registry.json`
5. Open a PR — once merged, your plugin appears in `asc plugins market list`

### Plugin bundle structure

The `.plugin.zip` must extract to a `<Name>.plugin/` directory:

```
ASCPro.plugin/
├── manifest.json              # {"name": "ASC Pro", "version": "1.0", "server": "ASCPro.dylib", "ui": ["ui/sim-stream.js"]}
├── ASCPro.dylib               # compiled dynamic library
└── ui/
    └── sim-stream.js          # web UI scripts (optional)
```

---

## CLI Usage

### `asc plugins list`

List installed dylib plugins.

```bash
asc plugins list --pretty
```

```json
{
  "data" : [
    {
      "affordances" : {
        "browseMarket" : "asc plugins market list",
        "uninstall" : "asc plugins uninstall --name ASCPro"
      },
      "id" : "asc-pro",
      "name" : "ASC Pro",
      "slug" : "ASCPro",
      "uiScripts" : ["ui/sim-stream.js"],
      "version" : "1.0"
    }
  ]
}
```

### `asc plugins market list`

Browse all available plugins from the registry.

```bash
asc plugins market list --pretty
```

```json
{
  "data" : [
    {
      "affordances" : {
        "install" : "asc plugins install --name asc-pro",
        "listMarket" : "asc plugins market list",
        "viewRepository" : "https://github.com/tddworks/asc-pro"
      },
      "author" : "tddworks",
      "categories" : ["simulators", "streaming"],
      "description" : "Simulator streaming, interaction & tunnel sharing",
      "downloadURL" : "https://github.com/tddworks/asc-pro/releases/latest/download/ASCPro.plugin.zip",
      "id" : "asc-pro",
      "isInstalled" : false,
      "name" : "ASC Pro",
      "repositoryURL" : "https://github.com/tddworks/asc-pro",
      "version" : "1.0"
    }
  ]
}
```

### `asc plugins market search --query <text>`

Search marketplace by keyword (matches name, description, categories).

```bash
asc plugins market search --query sim --pretty
```

### `asc plugins install --name <name>`

Download and install a plugin from the marketplace.

```bash
asc plugins install --name asc-pro
```

Downloads the `.plugin.zip` from `downloadURL`, extracts to `~/.asc/plugins/`.

### `asc plugins uninstall --name <name>`

Remove an installed plugin bundle.

```bash
asc plugins uninstall --name ASCPro
```

---

## Typical Workflow

```bash
# Browse the marketplace
asc plugins market list

# Search for simulator plugins
asc plugins market search --query sim

# Install a plugin
asc plugins install --name asc-pro

# Verify installation
asc plugins list

# Uninstall when done
asc plugins uninstall --name ASCPro
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  ASCCommand                                                      │
│    PluginsCommand → PluginsList, PluginsInstall, PluginsUninstall│
│    PluginsMarket → MarketList, MarketSearch                      │
│    Web UI: pages/plugins.js (Installed + Marketplace tabs)       │
├─────────────────────────────────────────────────────────────────┤
│  Infrastructure                                                  │
│    PluginMarketRepository (composes [PluginSource])               │
│      listInstalled() → PluginLoader.discover() → [Plugin]        │
│      listAvailable() → sources.fetchPlugins() → [MarketPlugin]   │
│      install(name:) → download zip + unzip to ~/.asc/plugins/    │
│      uninstall(name:) → rm ~/.asc/plugins/<name>.plugin/         │
│                                                                   │
│    GitHubPluginSource                                             │
│      → fetches registry.json from tddworks/asc-registry       │
│      → parses into [MarketPlugin]                                 │
├─────────────────────────────────────────────────────────────────┤
│  Domain                                                          │
│    Plugin — installed dylib plugin (id, name, version, slug)     │
│    MarketPlugin — marketplace listing (id, name, downloadURL)    │
│    PluginSource — @Mockable protocol for registry sources        │
│    PluginRepository — @Mockable protocol                         │
└─────────────────────────────────────────────────────────────────┘
```

### Adding more sources

Implement `PluginSource` and add to the sources array in `ClientFactory`:

```swift
public func makePluginRepository() -> any PluginRepository {
    PluginMarketRepository(sources: [
        GitHubPluginSource(owner: "tddworks", repo: "asc-cli-plugins"),
        MyCustomSource(),  // any PluginSource implementation
    ])
}
```

---

## Domain Models

### Plugin (installed)

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Same as slug |
| `name` | String | Display name from manifest |
| `version` | String | Plugin version |
| `slug` | String | URL-safe directory name |
| `uiScripts` | [String] | UI script paths for web app |

**Affordances:** `uninstall`, `browseMarket`

### MarketPlugin (marketplace)

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Plugin identifier |
| `name` | String | Display name |
| `version` | String | Latest version |
| `description` | String | Plugin description |
| `author` | String? | Author name |
| `repositoryURL` | String? | Source code URL |
| `downloadURL` | String | Download URL for .plugin.zip |
| `categories` | [String] | Category tags |
| `isInstalled` | Bool | Whether locally installed |

**Affordances (state-aware):** `install` (not installed), `uninstall` (installed), `viewRepository` (has URL), `listMarket`

---

## File Map

```
Sources/
├── Domain/Plugins/
│   ├── Plugin.swift              — installed dylib plugin model
│   ├── MarketPlugin.swift        — marketplace listing model
│   ├── PluginSource.swift        — @Mockable protocol for sources
│   └── PluginRepository.swift    — @Mockable protocol
├── Infrastructure/Plugins/
│   ├── PluginMarketRepository.swift — composes sources + PluginLoader
│   └── GitHubPluginSource.swift     — fetches registry.json from GitHub
└── ASCCommand/Commands/Plugins/
    ├── PluginsCommand.swift       — parent command
    ├── PluginsList.swift          — asc plugins list
    ├── PluginsInstall.swift       — asc plugins install
    ├── PluginsUninstall.swift     — asc plugins uninstall
    └── PluginsMarket.swift        — asc plugins market (list + search)

Tests/
├── DomainTests/Plugins/
│   ├── PluginTests.swift          — Plugin model + affordances
│   ├── MarketPluginTests.swift    — MarketPlugin model + affordances
│   └── PluginSourceTests.swift    — PluginSource protocol tests
├── InfrastructureTests/Plugins/
│   └── GitHubPluginSourceTests.swift — registry JSON parsing
└── ASCCommandTests/Commands/Plugins/
    ├── PluginsListTests.swift     — list command output
    └── PluginsMarketTests.swift   — market list + search output

apps/asc-web/command-center/
├── js/presentation/pages/plugins.js — Installed + Marketplace tabs
├── js/presentation/navigation.js    — page registration
└── index.html                        — sidebar nav item
```

## Testing

```bash
swift test --filter 'PluginTests|MarketPluginTests|PluginsListTests|PluginsMarketTests|PluginSourceTests|GitHubPluginSourceTests'
```
