# Web Apps

Two browser-based interfaces for ASC CLI — a **Dashboard** for visual management and a **Console** for terminal-style command execution. Both work on GitHub Pages (mock/offline mode) and connect to a local API proxy for live CLI access.

## Quick Start

```bash
# Start the local API proxy
asc web-server

# Or with custom port
asc web-server --port 9000
```

Then open either web app:
- **Dashboard:** https://asccli.app/asc-web-management/
- **Console:** https://asccli.app/asc-web-console/

**Prerequisites:** Node.js (for the API proxy) and `asc` in your PATH.

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  GitHub Pages / Browser (file://)                    │
│                                                      │
│  ┌─────────────────────┐  ┌────────────────────────┐ │
│  │  asc-web-management │  │  asc-web-console       │ │
│  │  (Dashboard)        │  │  (Terminal)             │ │
│  └────────┬────────────┘  └────────┬───────────────┘ │
│           │ POST /api/run          │                  │
│           └──────────┬─────────────┘                  │
└──────────────────────┼────────────────────────────────┘
                       │
              ┌────────▼─────────┐
              │  asc web-server  │
              │  (API proxy)     │
              │  localhost:8420  │
              └────────┬─────────┘
                       │ execFile
              ┌────────▼─────────┐
              │  asc CLI binary  │
              └──────────────────┘
```

### Dual-mode Data Flow

Both web apps auto-detect the API proxy:

1. Try relative `/api/run` (works when served by `apps/server.js` locally)
2. Try `http://127.0.0.1:8420/api/run` (works on GitHub Pages with local proxy)
3. Fall back to **mock mode** (demo data, no CLI required)

---

## Web Apps

### Dashboard (`apps/asc-web-management/`)

A full visual management interface with:

- **Stats cards** — total features, CLI commands, categories, version
- **Feature group cards** — all categories with navigation links
- **Quick actions** — one-click execution of common commands
- **Feature pages** — commands grouped by resource prefix with color-coded action badges (green=read, blue=create, amber=update, red=delete, violet=upload/submit, cyan=download)
- **Mode indicator** — shows CLI (live) or Mock (demo) mode

Three-layer JS architecture mirroring the Swift backend:
- **Infrastructure** — `data-provider.js` (CLI/mock switching), `mock-data.js` (demo dataset)
- **Domain** — `affordances.js`, `enrichers.js`, `version-state.js`
- **Presentation** — page components, navigation, theme, modal, toast

### Console (`apps/asc-web-console/`)

A terminal-style interface with:

- **Sidebar navigation** — grouped feature access
- **Built-in terminal** — execute `asc` commands with smart output rendering
- **Command palette** — `Cmd+K` to search across all commands
- **JSON tables** — array responses rendered as interactive tables
- **Affordance buttons** — clickable CAEOAS commands for drill-down navigation
- **State color coding** — green (live), amber (pending), red (failed)

---

## API Proxy (`asc web-server`)

The `web-server` command starts a Node.js API proxy. The `apps/server.js` is embedded in the `asc` binary at build time via an SPM build plugin (`Plugins/EmbedServerJS/`), extracted to a temp directory at runtime.

### CLI Usage

```bash
asc web-server              # port 8420 (default)
asc web-server --port 9000  # custom port
```

### API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/run` | POST | Execute an `asc` command |

**Request:**
```json
POST /api/run
Content-Type: application/json

{ "command": "asc apps list --output json" }
```

**Response:**
```json
{
  "stdout": "[{\"id\": \"123\", \"name\": \"My App\"}]",
  "stderr": "",
  "exit_code": 0
}
```

### Security

- Only `asc` commands allowed (prefix check)
- Shell metacharacters blocked (`;|&$\`\\(){}[]!><`)
- `execFile` with arg list (no shell expansion)
- 30-second timeout per command
- `NO_COLOR=1` to strip ANSI codes
- CORS enabled for cross-origin access from GitHub Pages

---

## Local Development

For local development with static file serving (both apps):

```bash
# Full server with static files + API proxy
node apps/server.js

# Routes:
#   /management/  → Dashboard
#   /console/     → Console
#   /api/run      → CLI bridge
#   /             → Dashboard (default)
```

Or open `apps/asc-web-management/index.html` directly in a browser — it falls back to mock mode automatically.

---

## Smart Output Rendering (Console)

### Array → Table

```
┌────────┬──────────┬─────────────────┬──────────┐
│ id     │ name     │ bundleId        │ state    │
├────────┼──────────┼─────────────────┼──────────┤
│ 123456 │ My App   │ com.example.app │ READY... │
└────────┴──────────┴─────────────────┴──────────┘
2 records
```

### Affordances → Action Buttons

```
[listVersions] [createVersion] [submitForReview]
```

### State Color Coding

| Color | States |
|-------|--------|
| Green | `READY_FOR_SALE`, `ACTIVE`, `SUCCEEDED`, `VALID`, `COMPLETE` |
| Amber | `IN_REVIEW`, `PROCESSING`, `PENDING`, `RUNNING` |
| Red | `REJECTED`, `FAILED`, `EXPIRED`, `REVOKED`, `INVALID` |

---

## Keyboard Shortcuts (Console)

| Shortcut | Action |
|----------|--------|
| `Ctrl+\`` | Toggle terminal panel |
| `Cmd+K` / `Ctrl+K` | Open command palette |
| `ESC` | Close terminal or palette |
| `Enter` (terminal) | Execute command |
| `Arrow Up/Down` (terminal) | Navigate command history |

---

## File Map

```
apps/
├── server.js                        Unified Node.js server (local dev + embedded in binary)
├── asc-web-management/              Dashboard web app
│   ├── index.html
│   ├── css/                         Stylesheet modules
│   └── js/                          Three-layer JS (infrastructure/domain/presentation)
└── asc-web-console/                 Console web app
    └── index.html

Sources/ASCCommand/Commands/Web/
└── WebCommand.swift                 `asc web-server` command

Plugins/EmbedServerJS/
└── plugin.swift                     SPM build plugin (embeds server.js into Swift)

.github/workflows/deploy-homepage.yml  Copies apps/ to homepage/ for GitHub Pages
```

---

## Extending

### Adding commands to the Dashboard

Add entries to the navigation data in `apps/asc-web-management/js/presentation/navigation.js`.

### Adding commands to the Console

Add entries to the navigation data structure in `apps/asc-web-console/index.html`.

### Custom asc binary path

```bash
node apps/server.js --asc-bin /path/to/custom/asc
```
