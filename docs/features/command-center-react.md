# Command Center — React Refactor Design Doc

## Overview

Refactor `apps/asc-web/command-center` from vanilla HTML/JS/CSS to **React + Vite + TypeScript** using a vertical-slice ("cake pattern") architecture where each domain feature is self-contained. The goal is to reduce cognitive load, enable rich domain design, and make plugin extensibility a first-class concern.

**What changes:** The `command-center/` frontend only.
**What stays:** Swift/Hummingbird backend, REST API, `console/` app, `shared/` data layer (migrated to TypeScript).

---

## Motivation

### Problems with the current vanilla JS approach

| Problem | Impact |
|---------|--------|
| Manual DOM manipulation in each page file | Hard to compose, easy to break, no reuse |
| No type safety — domain models are plain objects | Bugs from typos, missing fields, wrong types |
| Adding a page touches 4+ files (HTML sidebar, navigation.js, page file, data-provider routing) | High friction for new features and plugins |
| Plugin UI is ad-hoc script injection (`<script>` tags) | Plugins can't contribute pages, widgets, or sidebar items cleanly |
| Flat file structure mixes concerns | Must jump between multiple directories to understand one feature |

### Why React + Vite + TypeScript

- **Component model mirrors Swift domain models** — each `App`, `Version`, `Build` becomes a typed component with props matching the Swift struct fields
- **Plugin extensibility via dynamic imports** — plugins register pages/widgets/sidebar items through a typed API, loaded lazily
- **TypeScript interfaces mirror Swift models** — catches field mismatches at compile time
- **Vite HMR** — instant feedback during development
- **Vertical slices** — one folder per domain concept, everything you need in one place

### Why NOT Electron / Node.js

- Swift/Hummingbird backend is tightly coupled to `appstoreconnect-swift-sdk` and CLI subprocess execution — replacing it would be a rewrite with no benefit
- `ascbar` (SwiftUI menu bar app) already covers native desktop
- Browser-based approach works well with existing `asc web` command

---

## Architecture

### System Context

```
┌──────────────────────────────────────────────────────────────────┐
│                    Browser (React + Vite + TypeScript)            │
│                                                                    │
│  ┌────────────┐  ┌──────────────┐  ┌───────────────────────────┐ │
│  │ Core Slices │  │ Plugin Slices│  │ Plugin Widgets (slots)    │ │
│  │ app/ build/ │  │ (dynamic)    │  │ <PluginSlot name="..."/>  │ │
│  └─────┬──────┘  └──────┬───────┘  └───────────┬───────────────┘ │
│        │                 │                       │                  │
│  ┌─────▼─────────────────▼───────────────────────▼────────────┐   │
│  │                 Plugin Registry                             │   │
│  │   registerPage() · registerWidget() · registerSidebar()     │   │
│  └─────────────────────────┬──────────────────────────────────┘   │
│                             │                                      │
│  ┌─────────────────────────▼──────────────────────────────────┐   │
│  │               Per-Slice Infrastructure                      │   │
│  │   Feature.api.ts (REST) · Feature.mock.ts (offline)         │   │
│  └─────────────────────────┬──────────────────────────────────┘   │
│                             │                                      │
│  ┌─────────────────────────▼──────────────────────────────────┐   │
│  │               shared/api-client.ts                          │   │
│  │   Base fetch wrapper · error handling · auth headers         │   │
│  └─────────────────────────┬──────────────────────────────────┘   │
│                             │                                      │
└─────────────────────────────┼──────────────────────────────────────┘
                              │ HTTP/HTTPS (8420/8421)
┌─────────────────────────────▼──────────────────────────────────────┐
│            Existing Swift/Hummingbird Backend (unchanged)           │
│  /api/v1/*  REST    │  /api/plugins  │  /api/run  │  /api/files    │
└────────────────────────────────────────────────────────────────────┘
```

### Dependency Rules

```
pages/        →  components/  →  Feature.hooks.ts  →  infrastructure/
(route-level)    (reusable)      (domain logic)       (api/mock)
     │                │               │                     │
     └────────────────┴───────────────┴─────────────────────┘
                              │
                        shared/ (kernel)
```

- **Slices import from `shared/`** — never the reverse
- **Slices import `components/` from sibling slices** — e.g. `dashboard/` imports `app/components/AppCard`
- **`pages/` are never imported by other slices** — only referenced by the router
- **`infrastructure/` is only consumed by hooks** — components never call API directly

---

## Directory Structure

```
apps/asc-web/command-center/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── index.html                              # Vite entry HTML (minimal)
│
└── src/
    ├── main.tsx                            # ReactDOM.createRoot + App
    ├── App.tsx                             # Router + PluginContext + ThemeProvider
    │
    │── ── ── ── Domain Slices ── ── ── ──
    │
    ├── app/                                # 🍰 App
    │   ├── App.ts                          # interface App, appAffordances()
    │   ├── App.hooks.ts                    # useApps(), useApp(id)
    │   ├── infrastructure/
    │   │   ├── App.api.ts                  # GET /api/v1/apps, /api/v1/apps/:id
    │   │   └── App.mock.ts                 # Static mock data
    │   ├── components/
    │   │   └── AppCard.tsx                 # Reusable card (used by dashboard)
    │   └── pages/
    │       ├── AppList.tsx                  # Route: /apps
    │       └── AppDetail.tsx               # Route: /apps/:id
    │
    ├── version/                            # 🍰 Version
    │   ├── Version.ts                      # interface Version, VersionState enum
    │   │                                   # semantic booleans: isLive, isEditable, isPending
    │   ├── Version.hooks.ts                # useVersions(appId), useVersionState()
    │   ├── infrastructure/
    │   │   ├── Version.api.ts              # GET /api/v1/apps/:appId/versions
    │   │   └── Version.mock.ts
    │   ├── components/
    │   │   ├── VersionBadge.tsx            # State badge with color
    │   │   └── VersionRow.tsx
    │   └── pages/
    │       ├── VersionList.tsx              # Route: /apps/:appId/versions
    │       └── VersionDetail.tsx           # Route: /versions/:id
    │
    ├── build/                              # 🍰 Build
    │   ├── Build.ts
    │   ├── Build.hooks.ts
    │   ├── infrastructure/
    │   │   ├── Build.api.ts
    │   │   └── Build.mock.ts
    │   ├── components/
    │   │   └── BuildRow.tsx
    │   └── pages/
    │       └── BuildList.tsx
    │
    ├── screenshot/                         # 🍰 Screenshot
    │   ├── Screenshot.ts                   # Screenshot, ScreenshotSet, DisplayType
    │   ├── Screenshot.hooks.ts
    │   ├── infrastructure/
    │   │   ├── Screenshot.api.ts
    │   │   └── Screenshot.mock.ts
    │   ├── components/
    │   │   └── ScreenshotGrid.tsx
    │   └── pages/
    │       └── ScreenshotManager.tsx
    │
    ├── review/                             # 🍰 Review
    │   ├── Review.ts
    │   ├── Review.hooks.ts
    │   ├── infrastructure/
    │   │   ├── Review.api.ts
    │   │   └── Review.mock.ts
    │   ├── components/
    │   │   └── ReviewCard.tsx
    │   └── pages/
    │       └── ReviewList.tsx
    │
    ├── testflight/                         # 🍰 TestFlight
    │   ├── BetaGroup.ts
    │   ├── BetaTester.ts
    │   ├── TestFlight.hooks.ts
    │   ├── infrastructure/
    │   │   ├── TestFlight.api.ts
    │   │   └── TestFlight.mock.ts
    │   ├── components/
    │   │   ├── BetaGroupCard.tsx
    │   │   └── TesterRow.tsx
    │   └── pages/
    │       └── TestFlightPage.tsx
    │
    ├── code-signing/                       # 🍰 Code Signing
    │   ├── Certificate.ts
    │   ├── Profile.ts
    │   ├── BundleID.ts
    │   ├── Device.ts
    │   ├── CodeSigning.hooks.ts
    │   ├── infrastructure/
    │   │   ├── CodeSigning.api.ts
    │   │   └── CodeSigning.mock.ts
    │   ├── components/
    │   │   └── CertificateRow.tsx
    │   └── pages/
    │       └── CodeSigningPage.tsx
    │
    ├── submission/                         # 🍰 Submission
    │   ├── Submission.ts
    │   ├── Submission.hooks.ts
    │   ├── infrastructure/
    │   │   ├── Submission.api.ts
    │   │   └── Submission.mock.ts
    │   └── pages/
    │       └── SubmissionPage.tsx
    │
    ├── xcode-cloud/                        # 🍰 Xcode Cloud
    │   ├── CiWorkflow.ts
    │   ├── CiBuildRun.ts
    │   ├── XcodeCloud.hooks.ts
    │   ├── infrastructure/
    │   │   ├── XcodeCloud.api.ts
    │   │   └── XcodeCloud.mock.ts
    │   ├── components/
    │   │   └── WorkflowCard.tsx
    │   └── pages/
    │       └── XcodeCloudPage.tsx
    │
    ├── report/                             # 🍰 Reports
    │   ├── Report.ts
    │   ├── Report.hooks.ts
    │   ├── infrastructure/
    │   │   ├── Report.api.ts
    │   │   └── Report.mock.ts
    │   └── pages/
    │       └── ReportsPage.tsx
    │
    ├── dashboard/                          # 🍰 Dashboard (cross-cutting)
    │   ├── Dashboard.hooks.ts              # Aggregates from app/, build/, review/
    │   └── pages/
    │       └── DashboardPage.tsx           # Imports AppCard, BuildRow from siblings
    │
    │── ── ── ── Plugin System ── ── ── ──
    │
    ├── plugin/                             # 🍰 Plugin System
    │   ├── Plugin.ts                       # PluginRegistration, PluginPage, PluginWidget
    │   ├── PluginRegistry.ts               # Singleton: register/query extensions
    │   ├── PluginLoader.ts                 # Discover from /api/plugins, dynamic import
    │   ├── PluginContext.tsx                # React context providing registry
    │   ├── infrastructure/
    │   │   └── Plugin.api.ts               # GET /api/plugins
    │   ├── components/
    │   │   └── PluginSlot.tsx              # <PluginSlot name="dashboard.top" />
    │   └── pages/
    │       └── PluginsPage.tsx             # Install/uninstall/marketplace
    │
    │── ── ── ── Shared Kernel ── ── ── ──
    │
    └── shared/                             # Cross-cutting (used by every slice)
        ├── api-client.ts                   # fetch wrapper, base URL, error handling
        ├── affordances.ts                  # AffordanceProviding type
        ├── types.ts                        # PaginatedResponse, OutputFormat
        ├── components/
        │   ├── AffordanceBar.tsx            # Renders affordances as action buttons
        │   ├── DataTable.tsx                # Generic sortable table
        │   ├── Toast.tsx
        │   ├── Modal.tsx
        │   ├── ThemeToggle.tsx
        │   └── ModeIndicator.tsx
        └── layout/
            ├── Sidebar.tsx                 # Core items + dynamic plugin items
            ├── PageLayout.tsx
            └── Header.tsx
```

### The Cake Pattern

Every domain slice follows the same internal structure:

```
feature/
├── Feature.ts                 # Domain — WHAT it is
│                              #   TypeScript interface mirroring Swift struct
│                              #   Affordance generator function
│                              #   State enum with semantic booleans
│
├── Feature.hooks.ts           # Domain — HOW to use it in React
│                              #   useFeatures(), useFeature(id)
│                              #   Manages loading/error/data state
│                              #   Calls infrastructure internally
│
├── infrastructure/            # HOW to get/send data
│   ├── Feature.api.ts         #   REST calls to Hummingbird backend
│   └── Feature.mock.ts        #   Static data for offline/demo mode
│
├── components/                # Reusable pieces (importable by other slices)
│   └── FeatureCard.tsx        #   e.g. AppCard used by dashboard/
│
└── pages/                     # Route-level (only referenced by router)
    ├── FeatureList.tsx
    └── FeatureDetail.tsx
```

**Rule:** `components/` are public exports. `pages/` are private to the slice.

---

## Domain Model Design

### TypeScript ↔ Swift Model Parity

Each TypeScript interface mirrors its Swift counterpart, including `parentId` and affordances:

```typescript
// app/App.ts
export interface App {
  id: string;
  name: string;
  bundleId: string;
  sku: string;
  primaryLocale: string;
  contentRightsDeclaration?: string;
  isAvailableInNewTerritories: boolean;
  affordances: Record<string, string>;
}

export function appAffordances(app: App): Record<string, string> {
  return {
    getVersions: `asc versions list --app-id ${app.id}`,
    getBuilds: `asc builds list --app-id ${app.id}`,
    getReviews: `asc reviews list --app-id ${app.id}`,
    getTestFlight: `asc beta-groups list --app-id ${app.id}`,
  };
}
```

```typescript
// version/Version.ts
export interface Version {
  id: string;
  appId: string;                        // parentId — injected by backend
  versionString: string;
  state: VersionState;
  platform: string;
  affordances: Record<string, string>;
}

export enum VersionState {
  ReadyForSale = "READY_FOR_SALE",
  PrepareForSubmission = "PREPARE_FOR_SUBMISSION",
  WaitingForReview = "WAITING_FOR_REVIEW",
  InReview = "IN_REVIEW",
  Rejected = "REJECTED",
  DeveloperRejected = "DEVELOPER_REJECTED",
  PendingDeveloperRelease = "PENDING_DEVELOPER_RELEASE",
  // ...
}

// Semantic booleans — mirrors Swift's VersionState extensions
export function isLive(state: VersionState): boolean {
  return state === VersionState.ReadyForSale;
}

export function isEditable(state: VersionState): boolean {
  return state === VersionState.PrepareForSubmission;
}

export function isPending(state: VersionState): boolean {
  return [
    VersionState.WaitingForReview,
    VersionState.InReview,
    VersionState.PendingDeveloperRelease,
  ].includes(state);
}
```

### Hooks Encapsulate Domain Logic

```typescript
// version/Version.hooks.ts
import { useState, useEffect } from 'react';
import type { Version } from './Version';
import { fetchVersions } from './infrastructure/Version.api';
import { mockVersions } from './infrastructure/Version.mock';
import { useDataMode } from '../shared/api-client';

export function useVersions(appId: string) {
  const [versions, setVersions] = useState<Version[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    const fetcher = mode === 'mock' ? mockVersions : fetchVersions;
    fetcher(appId)
      .then(setVersions)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [appId, mode]);

  return { versions, loading, error };
}
```

### Infrastructure — API Layer

```typescript
// version/infrastructure/Version.api.ts
import { apiClient } from '../../shared/api-client';
import type { Version } from '../Version';

export async function fetchVersions(appId: string): Promise<Version[]> {
  const response = await apiClient.get<{ data: Version[] }>(
    `/api/v1/apps/${appId}/versions`
  );
  return response.data;
}

export async function fetchVersion(versionId: string): Promise<Version> {
  const response = await apiClient.get<{ data: Version }>(
    `/api/v1/versions/${versionId}`
  );
  return response.data;
}
```

### Infrastructure — Mock Layer

```typescript
// version/infrastructure/Version.mock.ts
import type { Version } from '../Version';
import { VersionState } from '../Version';

export async function mockVersions(appId: string): Promise<Version[]> {
  return [
    {
      id: "v-1",
      appId,
      versionString: "1.2.0",
      state: VersionState.PrepareForSubmission,
      platform: "IOS",
      affordances: {
        getLocalizations: `asc version-localizations list --version-id v-1`,
        submitForReview: `asc versions submit --id v-1`,
      },
    },
    {
      id: "v-2",
      appId,
      versionString: "1.1.0",
      state: VersionState.ReadyForSale,
      platform: "IOS",
      affordances: {
        getLocalizations: `asc version-localizations list --version-id v-2`,
      },
    },
  ];
}
```

---

## Plugin System Design

### Plugin Registration API

```typescript
// plugin/Plugin.ts

/** What a plugin provides when it registers */
export interface PluginRegistration {
  id: string;
  name: string;
  version: string;

  /** New pages added to the router */
  pages?: PluginPage[];

  /** Items added to the sidebar navigation */
  sidebarItems?: PluginSidebarItem[];

  /** Widgets injected into named slots on existing pages */
  widgets?: PluginWidget[];
}

export interface PluginPage {
  /** Route path, e.g. "/discord" */
  path: string;
  title: string;
  icon?: string;
  /** Lazy-loaded component */
  component: () => Promise<{ default: React.ComponentType }>;
}

export interface PluginSidebarItem {
  id: string;
  label: string;
  icon?: string;
  /** Which sidebar section: "overview" | "release" | "infrastructure" | "plugins" */
  section: string;
  /** Route path this item navigates to */
  path: string;
}

export interface PluginWidget {
  /** Named slot: "dashboard.top", "dashboard.bottom", "app-detail.sidebar", etc. */
  slot: string;
  /** Lazy-loaded component */
  component: () => Promise<{ default: React.ComponentType }>;
  /** Lower number = renders first. Default: 100 */
  priority?: number;
}
```

### Plugin Registry (Singleton)

```typescript
// plugin/PluginRegistry.ts

class PluginRegistry {
  private plugins: Map<string, PluginRegistration> = new Map();

  register(plugin: PluginRegistration): void {
    this.plugins.set(plugin.id, plugin);
  }

  getPages(): PluginPage[] {
    return [...this.plugins.values()].flatMap(p => p.pages ?? []);
  }

  getSidebarItems(): PluginSidebarItem[] {
    return [...this.plugins.values()].flatMap(p => p.sidebarItems ?? []);
  }

  getWidgets(slot: string): PluginWidget[] {
    return [...this.plugins.values()]
      .flatMap(p => p.widgets ?? [])
      .filter(w => w.slot === slot)
      .sort((a, b) => (a.priority ?? 100) - (b.priority ?? 100));
  }
}

export const pluginRegistry = new PluginRegistry();
```

### Plugin Loader

```typescript
// plugin/PluginLoader.ts
import { apiClient } from '../shared/api-client';
import { pluginRegistry } from './PluginRegistry';

interface PluginManifest {
  name: string;
  slug: string;
  ui: string[];  // JS module URLs
}

export async function loadPlugins(): Promise<void> {
  const manifests = await apiClient.get<{ plugins: PluginManifest[] }>('/api/plugins');

  for (const manifest of manifests.plugins) {
    for (const scriptUrl of manifest.ui) {
      try {
        const module = await import(
          /* @vite-ignore */ `/api/plugins/${manifest.slug}/${scriptUrl}`
        );
        if (typeof module.registerPlugin === 'function') {
          const registration = module.registerPlugin();
          pluginRegistry.register(registration);
        }
      } catch (err) {
        console.warn(`Failed to load plugin ${manifest.name}:`, err);
      }
    }
  }
}
```

### Plugin Slot Component

```typescript
// plugin/components/PluginSlot.tsx
import { Suspense, lazy } from 'react';
import { usePluginRegistry } from '../PluginContext';

interface Props {
  name: string;  // e.g. "dashboard.top"
}

export function PluginSlot({ name }: Props) {
  const registry = usePluginRegistry();
  const widgets = registry.getWidgets(name);

  if (widgets.length === 0) return null;

  return (
    <div className="plugin-slot" data-slot={name}>
      {widgets.map((widget, i) => {
        const Component = lazy(widget.component);
        return (
          <Suspense key={i} fallback={<div className="plugin-loading" />}>
            <Component />
          </Suspense>
        );
      })}
    </div>
  );
}
```

### Example: Writing a Plugin

A plugin author creates a standalone package:

```
my-discord-plugin/
├── package.json
└── src/
    ├── index.ts              # Entry point
    ├── DiscordPage.tsx       # Custom page
    └── NotifyWidget.tsx      # Dashboard widget
```

```typescript
// my-discord-plugin/src/index.ts
import type { PluginRegistration } from '@asc-web/plugin';

export function registerPlugin(): PluginRegistration {
  return {
    id: 'discord-notify',
    name: 'Discord Notifications',
    version: '1.0.0',
    pages: [
      {
        path: '/discord',
        title: 'Discord',
        icon: 'message-circle',
        component: () => import('./DiscordPage'),
      },
    ],
    sidebarItems: [
      {
        id: 'discord',
        label: 'Discord',
        icon: 'message-circle',
        section: 'plugins',
        path: '/discord',
      },
    ],
    widgets: [
      {
        slot: 'dashboard.top',
        component: () => import('./NotifyWidget'),
        priority: 50,
      },
    ],
  };
}
```

The plugin author's mental model is identical to a core developer's — same cake, same files, same patterns.

---

## Shared Kernel

Only truly cross-cutting concerns live in `shared/`. If something is used by 1-2 slices, it stays in those slices.

### API Client

```typescript
// shared/api-client.ts
const BASE_URL = `https://localhost:8421`;

export const apiClient = {
  async get<T>(path: string): Promise<T> {
    const res = await fetch(`${BASE_URL}${path}`);
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json();
  },

  async post<T>(path: string, body: unknown): Promise<T> {
    const res = await fetch(`${BASE_URL}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json();
  },

  /** Execute a CLI command via the backend */
  async runCommand(command: string): Promise<{ stdout: string; stderr: string; exit_code: number }> {
    return this.post('/api/run', { command: `asc ${command}` });
  },
};
```

### Affordance Bar Component

```typescript
// shared/components/AffordanceBar.tsx
import { apiClient } from '../api-client';

interface Props {
  affordances: Record<string, string>;
}

export function AffordanceBar({ affordances }: Props) {
  const entries = Object.entries(affordances);
  if (entries.length === 0) return null;

  const handleClick = async (command: string) => {
    // If it's an "asc ..." command, execute via backend
    if (command.startsWith('asc ')) {
      const result = await apiClient.runCommand(command.replace(/^asc /, ''));
      // Toast or navigate based on result
    }
  };

  return (
    <div className="affordance-bar">
      {entries.map(([label, command]) => (
        <button
          key={label}
          className="affordance-btn"
          onClick={() => handleClick(command)}
          title={command}
        >
          {formatLabel(label)}
        </button>
      ))}
    </div>
  );
}

function formatLabel(key: string): string {
  // "getVersions" → "Get Versions"
  return key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase()).trim();
}
```

---

## Routing

React Router wires core pages and dynamically adds plugin pages:

```typescript
// App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { PluginProvider } from './plugin/PluginContext';
import { Sidebar } from './shared/layout/Sidebar';
import { PageLayout } from './shared/layout/PageLayout';

// Core page imports (lazy)
const DashboardPage = lazy(() => import('./dashboard/pages/DashboardPage'));
const AppList = lazy(() => import('./app/pages/AppList'));
const AppDetail = lazy(() => import('./app/pages/AppDetail'));
const VersionList = lazy(() => import('./version/pages/VersionList'));
const BuildList = lazy(() => import('./build/pages/BuildList'));
const ReviewList = lazy(() => import('./review/pages/ReviewList'));
const TestFlightPage = lazy(() => import('./testflight/pages/TestFlightPage'));
const ScreenshotManager = lazy(() => import('./screenshot/pages/ScreenshotManager'));
const CodeSigningPage = lazy(() => import('./code-signing/pages/CodeSigningPage'));
const SubmissionPage = lazy(() => import('./submission/pages/SubmissionPage'));
const XcodeCloudPage = lazy(() => import('./xcode-cloud/pages/XcodeCloudPage'));
const ReportsPage = lazy(() => import('./report/pages/ReportsPage'));
const PluginsPage = lazy(() => import('./plugin/pages/PluginsPage'));

export function App() {
  const pluginPages = pluginRegistry.getPages();

  return (
    <BrowserRouter>
      <PluginProvider>
        <Sidebar />
        <PageLayout>
          <Suspense fallback={<LoadingSpinner />}>
            <Routes>
              {/* Core routes */}
              <Route path="/" element={<DashboardPage />} />
              <Route path="/apps" element={<AppList />} />
              <Route path="/apps/:appId" element={<AppDetail />} />
              <Route path="/apps/:appId/versions" element={<VersionList />} />
              <Route path="/builds" element={<BuildList />} />
              <Route path="/reviews" element={<ReviewList />} />
              <Route path="/testflight" element={<TestFlightPage />} />
              <Route path="/screenshots" element={<ScreenshotManager />} />
              <Route path="/code-signing" element={<CodeSigningPage />} />
              <Route path="/submissions" element={<SubmissionPage />} />
              <Route path="/xcode-cloud" element={<XcodeCloudPage />} />
              <Route path="/reports" element={<ReportsPage />} />
              <Route path="/plugins" element={<PluginsPage />} />

              {/* Plugin routes — dynamically registered */}
              {pluginPages.map(page => (
                <Route
                  key={page.path}
                  path={page.path}
                  element={
                    <Suspense fallback={<LoadingSpinner />}>
                      <LazyPluginPage loader={page.component} />
                    </Suspense>
                  }
                />
              ))}
            </Routes>
          </Suspense>
        </PageLayout>
      </PluginProvider>
    </BrowserRouter>
  );
}
```

---

## Migration Strategy

Progressive migration — React app runs alongside the existing vanilla JS during transition. Both are served by the same Hummingbird backend.

### Phase 1: Scaffold (Week 1)

- Set up Vite + React + TypeScript project in `command-center/`
- Configure Vite proxy to forward `/api/*` to Hummingbird backend
- Implement `shared/` kernel: `api-client.ts`, `AffordanceBar`, layout components
- Implement `plugin/` slice: registry, loader, context, slot component
- Port the CSS theme (reuse existing CSS variables)

### Phase 2: First Slices (Week 2)

- Implement `app/` slice end-to-end (model, hooks, api, mock, components, pages)
- Implement `dashboard/` slice
- Verify data flow: React → api-client → Hummingbird → REST API

### Phase 3: Remaining Slices (Week 3-4)

- Port slices one by one in priority order:
  1. `version/` — most complex (state machine, semantic booleans, affordances)
  2. `build/`
  3. `review/`
  4. `testflight/`
  5. `screenshot/`
  6. `code-signing/`
  7. `submission/`
  8. `xcode-cloud/`
  9. `report/`

### Phase 4: Cleanup (Week 5)

- Remove old vanilla JS files
- Update `ASCWebServer.swift` static file serving to point to Vite build output
- Update ARCHITECTURE.md

### What stays unchanged

- `apps/asc-web/console/` — unchanged (separate app)
- `Sources/Infrastructure/Web/` — unchanged (same REST API)
- `Sources/ASCCommand/Commands/Web/` — unchanged (same controllers)
- `Sources/ASCPlugin/` — unchanged (same plugin loading, manifest format)

---

## Tech Stack

| Tool | Purpose | Why |
|------|---------|-----|
| **React 19** | UI framework | Component model, ecosystem, plugin lazy loading |
| **TypeScript 5** | Type safety | Mirrors Swift domain models at compile time |
| **Vite 6** | Build tool | Fast HMR, ESM-native, simple config |
| **React Router 7** | Routing | Dynamic route registration for plugins |
| **CSS Modules** or **vanilla CSS** | Styling | Reuse existing CSS variables and theme system |

No state management library (Redux, Zustand) — hooks + context are sufficient for this app's complexity. Each slice manages its own state via hooks.

---

## Serving in Production

Vite builds to static assets. The Hummingbird server serves them:

```
asc web  →  Hummingbird starts
            ├── /api/*           → REST routes (existing)
            ├── /command-center/ → Vite build output (dist/)
            └── /console/        → Existing vanilla JS (unchanged)
```

The `ASCWebServer.swift` static file middleware already serves from `apps/asc-web/`. After build, the compiled React app lands in `command-center/dist/` and is served as static files — no Node.js runtime needed.

---

## Adding a New Feature (Checklist)

To add a new domain feature (e.g. "In-App Purchases"):

1. Create `src/iap/` directory
2. `IAP.ts` — define `InAppPurchase` interface + affordances
3. `IAP.hooks.ts` — `useInAppPurchases(appId)`
4. `infrastructure/IAP.api.ts` — REST calls
5. `infrastructure/IAP.mock.ts` — mock data
6. `components/IAPRow.tsx` — reusable component
7. `pages/IAPPage.tsx` — route-level page
8. Register route in `App.tsx`
9. Add sidebar item in `Sidebar.tsx`

That's it. One folder, self-contained, no cross-file coordination.

---

## Open Questions

1. **CSS approach** — Reuse existing CSS files directly, or migrate to CSS Modules for per-component scoping?
2. **Testing** — Vitest for unit tests? React Testing Library for component tests?
3. **Monorepo** — Should plugins be packages in a monorepo (pnpm workspaces), or standalone repos?