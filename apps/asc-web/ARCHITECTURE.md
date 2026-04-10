# ASC Web Apps — Architecture Guide

Two web apps served from the Hummingbird (Swift) backend:

- **Command Center** — interactive manager UI (React + TypeScript + Vite)
- **Console** — CLI reference & learning tool (vanilla JS)

Both share CSS and are served by the same `asc web` process.

---

## Directory Structure

```
apps/asc-web/
├── command-center/              # React app (new)
│   ├── package.json             # Dependencies & scripts
│   ├── vite.config.ts           # Vite build + dev proxy to backend
│   ├── vitest.config.ts         # Test runner config
│   ├── tsconfig.json            # TypeScript config
│   ├── index-react.html         # Vite entry HTML (uses existing CSS)
│   ├── index.html               # Legacy vanilla JS app (still works)
│   ├── css/                     # Shared CSS (theme, base, layout, components, utilities)
│   ├── js/                      # Legacy vanilla JS (preserved during migration)
│   ├── src/                     # React source — vertical slices
│   │   ├── main.tsx             # React entry point
│   │   ├── App.tsx              # Root: providers + router + layout
│   │   ├── app/                 # 🍰 App domain slice
│   │   ├── version/             # 🍰 Version domain slice
│   │   ├── build/               # 🍰 Build domain slice
│   │   ├── review/              # 🍰 Review domain slice
│   │   ├── testflight/          # 🍰 TestFlight domain slice
│   │   ├── code-signing/        # 🍰 Code Signing domain slice
│   │   ├── submission/          # 🍰 Submission domain slice
│   │   ├── xcode-cloud/         # 🍰 Xcode Cloud domain slice
│   │   ├── report/              # 🍰 Reports domain slice
│   │   ├── simulator/           # 🍰 Simulator domain slice
│   │   ├── user/                # 🍰 Users domain slice
│   │   ├── iris/                # 🍰 Iris (Private API) slice
│   │   ├── iap/                 # 🍰 In-App Purchases slice
│   │   ├── subscription/        # 🍰 Subscriptions slice
│   │   ├── screenshot/          # 🍰 Screenshots slice
│   │   ├── app-info/            # 🍰 App Info slice
│   │   ├── dashboard/           # 🍰 Dashboard (cross-cutting)
│   │   ├── plugin/              # Plugin system (registry, loader, slots)
│   │   └── shared/              # Shared kernel (api-client, components, layout)
│   └── tests/                   # Tests — mirrors src/ slices
│       ├── app/                 # App domain + component tests
│       ├── version/             # Version domain + component tests
│       ├── build/               # Build domain tests
│       ├── review/              # Review domain tests
│       ├── testflight/          # TestFlight domain tests
│       ├── code-signing/        # Code Signing domain tests
│       ├── submission/          # Submission domain tests
│       ├── xcode-cloud/         # Xcode Cloud domain tests
│       ├── plugin/              # Plugin registry tests
│       └── shared/              # AffordanceBar component tests
├── console/                     # CLI reference tool (vanilla JS, unchanged)
│   ├── index.html
│   ├── css/
│   └── js/
└── shared/                      # Shared assets (logos, favicons)
    ├── infrastructure/          # Legacy data-provider (vanilla JS)
    ├── domain/                  # Legacy affordances/enrichers
    └── static/                  # Logos, favicons
```

---

## Cake Pattern (Vertical Slices)

Every domain feature is a self-contained slice:

```
src/feature/
├── Feature.ts                 # Rich domain model class
│                              #   Semantic booleans (isLive, isEditable)
│                              #   Capability checks from affordances (canSubmit)
│                              #   static fromJSON() factory
├── Feature.hooks.ts           # React hooks — thin lifecycle wrapper
│                              #   useFeatures(), useFeature(id)
├── infrastructure/
│   ├── Feature.api.ts         # REST API calls → hydrates model class
│   └── Feature.mock.ts        # Offline/demo mock data
├── components/
│   └── FeatureCard.tsx        # Reusable components (importable by other slices)
└── pages/
    └── FeaturePage.tsx        # Route-level page (only referenced by router)
```

**Rules:**
- `components/` are public — other slices can import them
- `pages/` are private — only the router references them
- `infrastructure/` is consumed by hooks only — components never call API directly
- Slices import from `shared/` — never the reverse

---

## Rich Domain Models

Models are classes with semantic booleans and capability checks, not anemic data bags:

```typescript
export class Version {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly versionString: string,
    readonly state: VersionState,
    readonly platform: string,
    readonly affordances: Affordances,    // from API — not computed
  ) {}

  get isLive(): boolean { return this.state === VersionState.ReadyForSale; }
  get isEditable(): boolean { return this.state === VersionState.PrepareForSubmission; }
  get canSubmit(): boolean { return 'submitForReview' in this.affordances; }

  static fromJSON(json: Record<string, unknown>): Version { ... }
}
```

**Key design:**
- Affordances come from the API (`_links` in REST, normalized to `affordances` by `apiClient`)
- Semantic booleans live on the model — components just ask `v.isLive`, never decide
- `fromJSON()` hydrates from REST API JSON with safe fallbacks

---

## REST API Integration

The React app talks to the Swift/Hummingbird backend via REST API:

```
React app (Vite dev server, port 5173)
    │
    │  GET /api/v1/apps
    │  GET /api/v1/apps/:id/versions
    │  GET /api/v1/apps/:id/builds
    │  GET /api/v1/certificates
    │  GET /api/sim/devices
    │  POST /api/run  (for CLI commands)
    │
    ▼ Vite proxy → http://localhost:8420
    │
Swift/Hummingbird backend (asc web, port 8420)
```

**Auto-detection:** On mount, the app probes `GET /api/v1`. If the backend responds, mode switches to `rest` automatically. Otherwise falls back to mock data.

**`_links` normalization:** The REST API returns HATEOAS `_links`:
```json
{ "id": "...", "_links": { "listVersions": { "href": "/api/v1/...", "method": "GET" } } }
```
`apiClient.get()` runs `normalizeLinks()` which converts `_links` to flat `affordances`:
```json
{ "id": "...", "affordances": { "listVersions": "/api/v1/..." } }
```
All domain models use the simple `(json.affordances as Affordances) ?? {}` — no special handling needed.

---

## Plugin System

Plugins extend the UI with pages, sidebar items, and widgets:

```typescript
// Plugin registration API
interface PluginRegistration {
  id: string;
  name: string;
  version: string;
  pages?: PluginPage[];           // New routes
  sidebarItems?: PluginSidebarItem[]; // Sidebar links
  widgets?: PluginWidget[];       // Injected into named slots
}
```

- **PluginRegistry** — central registry, query pages/widgets/sidebar items
- **PluginLoader** — discovers plugins from `GET /api/plugins`, dynamic imports
- **PluginSlot** — `<PluginSlot name="dashboard.top" />` renders registered widgets
- **PluginContext** — React context providing the registry to the tree

Plugin authors follow the same cake pattern as core developers.

---

## Build, Test, Deploy

### Prerequisites

```bash
node >= 18          # For Vite + React
swift >= 5.9        # For the backend (asc web)
```

### Development

```bash
# Terminal 1: Start the Swift backend
swift run asc web

# Terminal 2: Start the React dev server (with hot reload)
cd apps/asc-web/command-center
npm install          # First time only
npm run dev          # Starts Vite on port 5173, proxies /api → localhost:8420

# Open http://localhost:5173/index-react.html
```

The Vite dev server auto-detects the backend. If `asc web` is running, data loads from the real API. If not, mock data is used.

### Testing

```bash
cd apps/asc-web/command-center

# Run all tests
npm test                          # or: npx vitest run

# Run tests for one slice
npx vitest run tests/version

# Watch mode (re-runs on file changes)
npm run test:watch                # or: npx vitest

# Type check
npx tsc -b --noEmit
```

**Test layers:**
- **Domain tests** (pure TypeScript, no React) — semantic booleans, capability checks, state transitions, `fromJSON` hydration
- **Component tests** (React Testing Library) — renders based on model state, affordance buttons
- **Plugin tests** (pure TypeScript) — registry, slot resolution

### Production Build

```bash
cd apps/asc-web/command-center

# Build optimized static assets
npm run build                     # Outputs to dist/

# Preview the production build locally
npm run preview
```

The build produces static HTML/JS/CSS in `command-center/dist/`. The Hummingbird backend serves these files — no Node.js runtime needed in production.

### Deployment

The `asc web` command serves both the React app and the console:

```
asc web  →  Hummingbird starts on port 8420
            ├── /api/*           → REST routes (Swift controllers)
            ├── /command-center/ → React build output (dist/) or dev files
            ├── /console/        → Console app (vanilla JS)
            └── /shared/         → Shared static assets
```

To deploy with the built React app:
1. Run `npm run build` in `command-center/`
2. The `dist/` output is served automatically by the Hummingbird static file middleware
3. Run `asc web` — navigating to `/command-center/` serves the production build

---

## How to Add a New Feature (React)

### Step 1: Create the slice

```bash
mkdir -p src/my-feature/{infrastructure,components,pages}
mkdir -p tests/my-feature
```

### Step 2: TDD — write domain test first

```typescript
// tests/my-feature/MyFeature.test.ts
import { describe, it, expect } from 'vitest';
import { MyFeature } from '../../src/my-feature/MyFeature.ts';

describe('MyFeature', () => {
  it('semantic boolean works', () => {
    const f = new MyFeature('id-1', 'app-1', 'active', {});
    expect(f.isActive).toBe(true);
  });

  it('hydrates from API JSON', () => {
    const f = MyFeature.fromJSON({ id: 'id-1', appId: 'app-1', state: 'active' });
    expect(f.isActive).toBe(true);
  });
});
```

### Step 3: Implement the domain model

```typescript
// src/my-feature/MyFeature.ts
import type { Affordances } from '../shared/types.ts';

export class MyFeature {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly state: string,
    readonly affordances: Affordances,
  ) {}

  get isActive(): boolean { return this.state === 'active'; }

  static fromJSON(json: Record<string, unknown>): MyFeature {
    return new MyFeature(
      (json.id as string) ?? '',
      (json.appId as string) ?? '',
      (json.state as string) ?? '',
      (json.affordances as Affordances) ?? {},
    );
  }
}
```

### Step 4: Infrastructure + hooks

```typescript
// src/my-feature/infrastructure/MyFeature.api.ts
import { MyFeature } from '../MyFeature.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchMyFeatures(appId: string, mode: DataMode): Promise<MyFeature[]> {
  if (mode === 'mock') {
    const { mockMyFeatures } = await import('./MyFeature.mock.ts');
    return mockMyFeatures(appId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(`/api/v1/apps/${appId}/my-features`);
  return json.data.map(MyFeature.fromJSON);
}

// src/my-feature/MyFeature.hooks.ts
import { useState, useEffect } from 'react';
import { MyFeature } from './MyFeature.ts';
import { fetchMyFeatures } from './infrastructure/MyFeature.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useMyFeatures(appId: string) {
  const [items, setItems] = useState<MyFeature[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchMyFeatures(appId, mode).then(setItems).catch(setError).finally(() => setLoading(false));
  }, [appId, mode]);

  return { items, loading, error };
}
```

### Step 5: Page component

```tsx
// src/my-feature/pages/MyFeaturePage.tsx
import { useMyFeatures } from '../MyFeature.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

export default function MyFeaturePage({ appId = 'app-1' }: { appId?: string }) {
  const { items, loading, error } = useMyFeatures(appId);
  if (loading) return <div className="spinner">Loading...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <div className="toolbar-left"><h3>My Feature</h3></div>
      </div>
      <div className="table-wrapper">
        <table>
          <thead><tr><th>ID</th><th>State</th><th>Actions</th></tr></thead>
          <tbody>
            {items.map((f) => (
              <tr key={f.id}>
                <td className="cell-mono">{f.id}</td>
                <td><span className={`status ${f.isActive ? 'live' : 'draft'}`}>{f.state}</span></td>
                <td><AffordanceBar affordances={f.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
```

### Step 6: Wire into App.tsx

```typescript
// src/App.tsx — add lazy import + route
const MyFeaturePage = lazy(() => import('./my-feature/pages/MyFeaturePage.tsx'));

// Inside <Routes>:
<Route path="/my-feature" element={<MyFeaturePage />} />
```

### Step 7: Add sidebar item

```typescript
// src/shared/layout/Sidebar.tsx — add to coreItems
{ path: '/my-feature', label: 'My Feature' }
```

### Step 8: Add header title mapping

```typescript
// src/shared/layout/Header.tsx — add to pageTitles
'/my-feature': 'My Feature',
```

---

## Console App (Vanilla JS)

The console app (`/console`) is unchanged. It's a CLI reference tool driven by `nav-data.js`:

- **Sidebar:** Built from `nav-data.js` groups/items
- **Search (Cmd+K):** Indexes all features + commands
- **Feature pages:** Auto-generated from NAV structure
- **Terminal:** Sends commands via DataProvider → `asc` CLI

To add a feature to the console, add an entry to `console/js/presentation/nav-data.js`.

---

## CSS Architecture

Both apps share the same CSS files in `command-center/css/`:

| File | Purpose |
|------|---------|
| `theme.css` | Design tokens (`:root` light, `[data-theme="dark"]` dark) |
| `base.css` | Reset, typography, theme toggle |
| `layout.css` | Sidebar (260px fixed), header (64px sticky), content area |
| `components.css` | Cards, tables, status badges, buttons, forms, modals, toast, timeline |
| `utilities.css` | Responsive breakpoints, helper classes |

Key classes: `.card`, `.toolbar`, `.table-wrapper`, `.status` (live/pending/review/rejected/processing/draft), `.btn` (primary/secondary/sm), `.platform-badge`, `.cell-mono`, `.cell-primary`, `.app-card`, `.stat-card`, `.dashboard-stats`, `.filter-btn`, `.form-group`, `.form-control`, `.detail-tabs`.

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| React 19 | UI framework |
| TypeScript 5 | Type safety — mirrors Swift domain models |
| Vite 6 | Build tool + HMR + API proxy |
| Vitest | Test runner (Vite-native) |
| React Testing Library | Component tests |
| React Router 7 | Client-side routing + dynamic plugin routes |
| Hummingbird (Swift) | HTTP backend serving REST API + static files |

No state management library — hooks + context are sufficient. Each slice manages its own state.

---

## Checklist: Adding a Feature

- [ ] `tests/my-feature/MyFeature.test.ts` — domain test (RED)
- [ ] `src/my-feature/MyFeature.ts` — rich model class (GREEN)
- [ ] `src/my-feature/infrastructure/MyFeature.mock.ts` — mock data
- [ ] `src/my-feature/infrastructure/MyFeature.api.ts` — REST + mock fetcher
- [ ] `src/my-feature/MyFeature.hooks.ts` — thin React hook
- [ ] `src/my-feature/pages/MyFeaturePage.tsx` — page component
- [ ] `src/App.tsx` — lazy import + route
- [ ] `src/shared/layout/Sidebar.tsx` — sidebar item
- [ ] `src/shared/layout/Header.tsx` — page title mapping
- [ ] `npx vitest run` — all tests pass
- [ ] `npx tsc -b --noEmit` — no type errors
