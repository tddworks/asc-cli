# Web Server Architecture — Swift + Hummingbird

## Overview

The ASC web server (`asc web-server`) is a Swift HTTP/WebSocket server built on [Hummingbird 2.21.1](https://github.com/hummingbird-project/hummingbird). It serves as the API bridge between the browser UI (hosted on `asccli.app`) and the CLI. Single binary, zero external dependencies.

Plugins extend the server with additional routes, commands, and affordances. See [Plugin Architecture](plugin-ui-architecture.md).

## Architecture

```
Browser (asccli.app)  ←──HTTP/WS──→  Swift Server (localhost:8420)
  HTML/JS/CSS only                     Hummingbird + plugin routes
```

```
┌──────────────────────────────────────────────────────────────┐
│  ASCCommand                                                   │
│  └── WebServerCommand.swift    CLI entry, command runner      │
├──────────────────────────────────────────────────────────────┤
│  Infrastructure/Web                                           │
│  ├── ASCWebServer.swift        Hummingbird app, routes,       │
│  │                             plugin loading, HTTPS           │
│  ├── CORSMiddleware.swift      Cross-origin for asccli.app    │
│  └── SelfSignedCert.swift      HTTPS cert generation          │
├──────────────────────────────────────────────────────────────┤
│  ASCPlugin                                                    │
│  ├── ASCPlugin.swift           @objc plugin protocol          │
│  └── PluginLoader.swift        Scans ~/.asc/plugins/          │
├──────────────────────────────────────────────────────────────┤
│  Domain                                                       │
│  └── AffordanceRegistry.swift  Plugin affordance extension    │
└──────────────────────────────────────────────────────────────┘
```

## API Endpoints

### Built-in (free)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/run` | Execute any asc CLI command |
| `GET` | `/api/sim/devices` | List simulators with affordances |
| `GET` | `/api/plugins` | List installed plugins + UI scripts |
| `GET` | `/api/plugins/{slug}/*` | Serve plugin UI static files |

### Plugin-provided (e.g. ASC Pro)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/sim/tap` | Tap at coordinates |
| `POST` | `/api/sim/swipe` | Swipe gesture |
| `POST` | `/api/sim/type` | Type text |
| `POST` | `/api/sim/button` | Hardware button |
| `POST` | `/api/sim/gesture` | Preset gesture |
| `GET` | `/api/sim/screenshot` | Capture screenshot |
| `GET` | `/api/sim/describe` | UI accessibility tree |
| `WS` | `/api/sim/ws?udid=X` | WebSocket stream + input |

## Plugin System

Plugins are `.plugin` bundles in `~/.asc/plugins/`:

```
ASCPro.plugin/
├── manifest.json      # name, server dylib path, UI scripts
├── ASCPro.dylib       # Mach-O dylib (dynamic_lookup, ~300KB)
└── ui/
    └── sim-stream.js  # Browser UI loaded dynamically
```

The server discovers plugins at startup:
1. Reads `manifest.json` from each `.plugin` bundle
2. Loads dylib via `dlopen` → calls `ascPlugin()` entry point
3. Plugin registers routes on the Hummingbird router (via raw pointer)
4. Plugin registers affordances via `AffordanceRegistry`
5. Server serves plugin UI scripts at `/api/plugins/{slug}/*`

The dylib uses `dynamic_lookup` linking — symbols resolve from the host process at runtime. No duplicate frameworks, ~300KB dylib size.

## HTTPS Support

Self-signed cert generated at `~/.asc/server.{key,crt}` and trusted in macOS Keychain. HTTPS on port 8421 (HTTP+1) for mixed-content support when the browser UI is on `asccli.app` (HTTPS).

## Command Execution

`/api/run` executes CLI commands via subprocess:
```
POST /api/run {"command": "asc apps list --pretty"}
→ spawns asc subprocess
→ returns {"stdout": "...", "stderr": "", "exit_code": 0}
```

## File Map

```
Sources/
├── ASCPlugin/
│   ├── ASCPlugin.swift           # @objc protocol, ASCRouter typealias
│   └── PluginLoader.swift        # .plugin/.framework/.dylib discovery
├── Infrastructure/Web/
│   ├── ASCWebServer.swift        # Hummingbird server, plugin loading
│   ├── CORSMiddleware.swift      # CORS for asccli.app → localhost
│   └── SelfSignedCert.swift      # HTTPS cert management
├── Domain/Shared/
│   └── AffordanceRegistry.swift  # Plugin affordance extension
└── ASCCommand/Commands/Web/
    └── WebServerCommand.swift    # CLI entry point
```
