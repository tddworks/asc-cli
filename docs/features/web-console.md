# Web Console

A browser-based dashboard for managing all ASC CLI features. Provides a visual interface with a built-in terminal for executing `asc` commands directly, smart JSON rendering with interactive tables, and clickable CAEOAS affordances.

## Quick Start

```bash
# 1. Start the dev server
python3 apps/asc-web/server.py

# 2. Open in browser
open http://127.0.0.1:8420

# Custom port
python3 apps/asc-web/server.py 9000
```

**Prerequisites:** Python 3 (stdlib only, no pip install needed) and `asc` in your PATH.

---

## Features

### Dashboard

The main dashboard shows:
- **Stats cards** — total features, CLI commands, categories, version
- **Feature group cards** — all 14 categories with navigation links
- **Quick actions** — one-click execution of common commands (apps list, auth check, builds list, sales report)

### Sidebar Navigation

7 groups covering all 68 CLI commands:

| Group | Features |
|-------|----------|
| App Management | Apps, Versions, Localizations, Screenshots, Previews, App Info, App Clips |
| Distribution | Builds, TestFlight, Reviews, Beta Review |
| Monetization | In-App Purchases, Subscriptions, Offer Codes, Reports |
| Development | Code Signing, Xcode Cloud, Game Center, Performance |
| Tools | App Shots, Availability |
| Settings | Authentication, Users & Teams, Plugins, Skills |

### Feature Pages

Each feature page shows:
- Commands grouped by resource prefix
- Color-coded action badges (green=read, blue=create, amber=update, red=delete, violet=upload/submit, cyan=download)
- **Copy** button — copies command to clipboard
- **Run** button — opens terminal and executes immediately

### Built-in Terminal

A bottom-drawer terminal panel for executing `asc` commands:

```
Ctrl+`          Toggle terminal open/close
Enter           Execute command
Arrow Up/Down   Command history navigation
```

**Smart output rendering:**
- JSON arrays → interactive tables with sortable columns
- State fields → color-coded (green=live/active, amber=pending, red=failed)
- CAEOAS affordances → clickable buttons that run the next command
- Single objects → key-value layout
- Plain text → preserved as-is

### Command Palette

```
Cmd+K (or Ctrl+K)   Open command palette
Type to filter       Searches across all 68 commands
Enter                Execute top match
ESC                  Close
```

---

## Architecture

```
apps/asc-web/
├── index.html     Single-page app (HTML + Tailwind CSS + vanilla JS)
└── server.py      Python dev server (stdlib http.server + subprocess)
```

### Frontend (`index.html`)

Self-contained SPA with no build step:
- **Tailwind CSS** via CDN for styling
- **IBM Plex Sans** (body) + **JetBrains Mono** (code) typography
- Dark theme with slate-950 background, brand-500 blue accents
- Client-side routing via JS state management
- All 68 commands defined in the `NAV` data structure

### Backend (`server.py`)

Lightweight Python server using only stdlib modules:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Serves `index.html` |
| `/api/run` | POST | Executes an `asc` command and returns output |

**API request:**
```json
POST /api/run
Content-Type: application/json

{ "command": "asc apps list --output json" }
```

**API response:**
```json
{
  "stdout": "[{\"id\": \"123\", \"name\": \"My App\", ...}]",
  "stderr": "",
  "exit_code": 0
}
```

**Security measures:**
- Only `asc` commands allowed (prefix check)
- Shell metacharacters blocked (`;|&$\`\\(){}[]!><`)
- Direct `subprocess.run` with arg list (no shell=True)
- 30-second timeout per command
- `NO_COLOR=1` env var to strip ANSI codes

---

## Smart Output Rendering

The terminal parses JSON responses and renders them contextually:

### Array → Table

When `asc` returns a JSON array of objects, the terminal renders an interactive table:

```
┌────────┬──────────┬─────────────────┬──────────┐
│ id     │ name     │ bundleId        │ state    │
├────────┼──────────┼─────────────────┼──────────┤
│ 123456 │ My App   │ com.example.app │ READY... │
└────────┴──────────┴─────────────────┴──────────┘
2 records
```

Priority columns: `id`, `name`, `appName`, `bundleId`, `state`, `platform`, `version`, `locale`, `type`, `status` (max 8 columns shown).

### Affordances → Action Buttons

CAEOAS affordances from `asc` responses render as clickable buttons:

```
[listVersions] [createVersion] [submitForReview]
```

Clicking an affordance button immediately executes that command in the terminal — enabling drill-down navigation through the App Store Connect resource hierarchy without typing.

### State Color Coding

| Color | States |
|-------|--------|
| Green | `READY_FOR_SALE`, `ACTIVE`, `SUCCEEDED`, `VALID`, `COMPLETE` |
| Amber | `IN_REVIEW`, `PROCESSING`, `PENDING`, `RUNNING` |
| Red | `REJECTED`, `FAILED`, `EXPIRED`, `REVOKED`, `INVALID` |

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+\`` | Toggle terminal panel |
| `Cmd+K` / `Ctrl+K` | Open command palette |
| `ESC` | Close terminal or palette |
| `Enter` (terminal) | Execute command |
| `Arrow Up/Down` (terminal) | Navigate command history |
| `Enter` (palette) | Execute top search result |

---

## Design System

| Property | Value |
|----------|-------|
| Background | `#070d1a` (slate-950) |
| Sidebar | `#0c1222` (slate-925) |
| Brand accent | `#3b82f6` (brand-500) |
| Body font | IBM Plex Sans |
| Code font | JetBrains Mono |
| Border | `slate-800/60` |
| Card | `slate-900/60` with `slate-800/60` border |

---

## File Map

```
apps/asc-web/
├── index.html              Frontend SPA
└── server.py               Python dev server
```

---

## Extending

### Adding new commands

Add entries to the `NAV` array in `index.html`:

```javascript
{ id: 'myfeature', label: 'My Feature', icon: 'box', cmds: ['my-feature list','my-feature create'] }
```

### Adding new icons

Add SVG path data to the `ICONS` object. Icons use 24x24 viewBox with stroke-based rendering (Lucide-style).

### Custom port

```bash
python3 apps/asc-web/server.py 9000
```

### Connecting to a remote `asc` binary

Edit `ASC_BIN` in `server.py` to point to a custom path:

```python
ASC_BIN = "/path/to/custom/asc"
```
