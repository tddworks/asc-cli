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
├── vitest.config.ts
├── tsconfig.json
├── index.html                              # Vite entry HTML (minimal)
│
├── src/                                    # Production code
│   ├── main.tsx                            # ReactDOM.createRoot + App
│   ├── App.tsx                             # Router + PluginContext + ThemeProvider
│   │
│   │── ── ── ── Domain Slices ── ── ── ──
│   │
│   ├── app/                                # 🍰 App
│   │   ├── App.ts                          # class App — rich domain model
│   │   ├── App.hooks.ts                    # useApps(), useApp(id) — thin lifecycle
│   │   ├── infrastructure/
│   │   │   ├── App.api.ts                  # GET /api/v1/apps — hydrates App class
│   │   │   └── App.mock.ts                 # Static mock data
│   │   ├── components/
│   │   │   └── AppCard.tsx                 # Reusable card (used by dashboard)
│   │   └── pages/
│   │       ├── AppList.tsx                 # Route: /apps
│   │       └── AppDetail.tsx              # Route: /apps/:id
│   │
│   ├── version/                            # 🍰 Version
│   │   ├── Version.ts                      # class Version — state machine, semantic booleans
│   │   ├── Version.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── Version.api.ts
│   │   │   └── Version.mock.ts
│   │   ├── components/
│   │   │   ├── VersionBadge.tsx
│   │   │   └── VersionRow.tsx
│   │   └── pages/
│   │       ├── VersionList.tsx
│   │       └── VersionDetail.tsx
│   │
│   ├── build/                              # 🍰 Build
│   │   ├── Build.ts
│   │   ├── Build.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── Build.api.ts
│   │   │   └── Build.mock.ts
│   │   ├── components/
│   │   │   └── BuildRow.tsx
│   │   └── pages/
│   │       └── BuildList.tsx
│   │
│   ├── screenshot/                         # 🍰 Screenshot
│   │   ├── Screenshot.ts
│   │   ├── Screenshot.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── Screenshot.api.ts
│   │   │   └── Screenshot.mock.ts
│   │   ├── components/
│   │   │   └── ScreenshotGrid.tsx
│   │   └── pages/
│   │       └── ScreenshotManager.tsx
│   │
│   ├── review/                             # 🍰 Review
│   │   ├── Review.ts
│   │   ├── Review.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── Review.api.ts
│   │   │   └── Review.mock.ts
│   │   ├── components/
│   │   │   └── ReviewCard.tsx
│   │   └── pages/
│   │       └── ReviewList.tsx
│   │
│   ├── testflight/                         # 🍰 TestFlight
│   │   ├── BetaGroup.ts
│   │   ├── BetaTester.ts
│   │   ├── TestFlight.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── TestFlight.api.ts
│   │   │   └── TestFlight.mock.ts
│   │   ├── components/
│   │   │   ├── BetaGroupCard.tsx
│   │   │   └── TesterRow.tsx
│   │   └── pages/
│   │       └── TestFlightPage.tsx
│   │
│   ├── code-signing/                       # 🍰 Code Signing
│   │   ├── Certificate.ts
│   │   ├── Profile.ts
│   │   ├── BundleID.ts
│   │   ├── Device.ts
│   │   ├── CodeSigning.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── CodeSigning.api.ts
│   │   │   └── CodeSigning.mock.ts
│   │   ├── components/
│   │   │   └── CertificateRow.tsx
│   │   └── pages/
│   │       └── CodeSigningPage.tsx
│   │
│   ├── submission/                         # 🍰 Submission
│   │   ├── Submission.ts
│   │   ├── Submission.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── Submission.api.ts
│   │   │   └── Submission.mock.ts
│   │   └── pages/
│   │       └── SubmissionPage.tsx
│   │
│   ├── xcode-cloud/                        # 🍰 Xcode Cloud
│   │   ├── CiWorkflow.ts
│   │   ├── CiBuildRun.ts
│   │   ├── XcodeCloud.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── XcodeCloud.api.ts
│   │   │   └── XcodeCloud.mock.ts
│   │   ├── components/
│   │   │   └── WorkflowCard.tsx
│   │   └── pages/
│   │       └── XcodeCloudPage.tsx
│   │
│   ├── report/                             # 🍰 Reports
│   │   ├── Report.ts
│   │   ├── Report.hooks.ts
│   │   ├── infrastructure/
│   │   │   ├── Report.api.ts
│   │   │   └── Report.mock.ts
│   │   └── pages/
│   │       └── ReportsPage.tsx
│   │
│   ├── dashboard/                          # 🍰 Dashboard (cross-cutting)
│   │   ├── Dashboard.hooks.ts              # Aggregates from app/, build/, review/
│   │   └── pages/
│   │       └── DashboardPage.tsx           # Imports AppCard, BuildRow from siblings
│   │
│   │── ── ── ── Plugin System ── ── ── ──
│   │
│   ├── plugin/                             # 🍰 Plugin System
│   │   ├── Plugin.ts                       # PluginRegistration, PluginPage, PluginWidget
│   │   ├── PluginRegistry.ts               # Singleton: register/query extensions
│   │   ├── PluginLoader.ts                 # Discover from /api/plugins, dynamic import
│   │   ├── PluginContext.tsx                # React context providing registry
│   │   ├── infrastructure/
│   │   │   └── Plugin.api.ts               # GET /api/plugins
│   │   ├── components/
│   │   │   └── PluginSlot.tsx              # <PluginSlot name="dashboard.top" />
│   │   └── pages/
│   │       └── PluginsPage.tsx             # Install/uninstall/marketplace
│   │
│   │── ── ── ── Shared Kernel ── ── ── ──
│   │
│   └── shared/                             # Cross-cutting (used by every slice)
│       ├── api-client.ts                   # fetch wrapper, base URL, error handling
│       ├── affordances.ts                  # AffordanceProviding type
│       ├── types.ts                        # PaginatedResponse, OutputFormat
│       ├── components/
│       │   ├── AffordanceBar.tsx            # Renders affordances as action buttons
│       │   ├── DataTable.tsx                # Generic sortable table
│       │   ├── Toast.tsx
│       │   ├── Modal.tsx
│       │   ├── ThemeToggle.tsx
│       │   └── ModeIndicator.tsx
│       └── layout/
│           ├── Sidebar.tsx                 # Core items + dynamic plugin items
│           ├── PageLayout.tsx
│           └── Header.tsx
│
└── tests/                                  # Tests — mirrors src/ structure
    ├── app/
    │   ├── App.test.ts                     # Domain tests (pure, no React)
    │   └── AppCard.test.tsx                # Component test
    ├── version/
    │   ├── Version.test.ts                 # Semantic booleans, capability checks
    │   └── VersionBadge.test.tsx           # Component rendering
    ├── build/
    │   └── Build.test.ts
    ├── screenshot/
    │   └── Screenshot.test.ts
    ├── review/
    │   └── Review.test.ts
    ├── testflight/
    │   └── TestFlight.test.ts
    ├── code-signing/
    │   └── CodeSigning.test.ts
    ├── submission/
    │   └── Submission.test.ts
    ├── xcode-cloud/
    │   └── XcodeCloud.test.ts
    ├── report/
    │   └── Report.test.ts
    ├── plugin/
    │   └── PluginRegistry.test.ts          # Registry logic tests
    └── shared/
        └── AffordanceBar.test.tsx          # Shared component tests
```

### The Cake Pattern

Every domain slice follows the same internal structure:

```
src/feature/                       # Production code
├── Feature.ts                     #   Domain — WHAT it is (rich model class)
│                                  #   Class with semantic booleans
│                                  #   Capability checks derived from affordances
│                                  #   State enum + static fromJSON() factory
│
├── Feature.hooks.ts               #   React lifecycle — THIN wrapper
│                                  #   useFeatures(), useFeature(id)
│                                  #   Only manages loading/error/data state
│                                  #   No domain logic — the model owns that
│
├── infrastructure/
│   ├── Feature.api.ts             #   REST calls → hydrates into rich model class
│   └── Feature.mock.ts            #   Static data for offline/demo mode
│
├── components/
│   └── FeatureCard.tsx            #   Components ASK the model, never decide
│
└── pages/
    ├── FeatureList.tsx
    └── FeatureDetail.tsx

tests/feature/                     # Tests — mirrors src/, same slice name
├── Feature.test.ts                #   Domain: semantic booleans, capabilities, fromJSON
└── FeatureCard.test.tsx           #   Component: renders based on model state
```

**Rule:** `components/` are public exports. `pages/` are private to the slice.

---

## Rich Domain Model Design

### Design Principles

The domain model is a **rich class**, not an anemic data bag. The key distinction:

| Concern | Where it lives | Source of truth |
|---------|---------------|-----------------|
| **Affordances** (available actions) | API response → `this.affordances` | **Server** — knows full state, auth, permissions |
| **Semantic booleans** (`isLive`, `isEditable`) | Model class as getters | **Model** — UI display logic (badge colors, show/hide) |
| **Capability checks** (`canSubmit`, `canRelease`) | Model class, derived from affordances | **Model** — reads what server decided, exposes it cleanly |
| **State transitions** (`canTransitionTo`) | Model class | **Model** — knows the state machine |

The server is the **source of truth** for what you can do. The model is the **source of truth** for how to interpret state. The component just asks both.

### Version — Full Rich Domain Model

```typescript
// version/Version.ts

export enum VersionState {
  ReadyForSale = "READY_FOR_SALE",
  PrepareForSubmission = "PREPARE_FOR_SUBMISSION",
  WaitingForReview = "WAITING_FOR_REVIEW",
  InReview = "IN_REVIEW",
  Rejected = "REJECTED",
  DeveloperRejected = "DEVELOPER_REJECTED",
  PendingDeveloperRelease = "PENDING_DEVELOPER_RELEASE",
}

export class Version {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly versionString: string,
    readonly state: VersionState,
    readonly platform: string,
    readonly affordances: Record<string, string>,  // from API — not computed
  ) {}

  // ── Semantic Booleans — the model KNOWS its own state ──

  get isLive(): boolean {
    return this.state === VersionState.ReadyForSale;
  }

  get isEditable(): boolean {
    return this.state === VersionState.PrepareForSubmission;
  }

  get isPending(): boolean {
    return [
      VersionState.WaitingForReview,
      VersionState.InReview,
    ].includes(this.state);
  }

  get isRejected(): boolean {
    return this.state === VersionState.Rejected;
  }

  // ── Capability Checks — derived from server affordances ──
  // The server decided what's possible. The model just exposes it.

  get canSubmit(): boolean {
    return "submitForReview" in this.affordances;
  }

  get canRelease(): boolean {
    return "releaseVersion" in this.affordances;
  }

  get canEdit(): boolean {
    return "updateVersion" in this.affordances;
  }

  // ── Domain Knowledge — state machine ──

  canTransitionTo(target: VersionState): boolean {
    const transitions: Partial<Record<VersionState, VersionState[]>> = {
      [VersionState.PrepareForSubmission]: [VersionState.WaitingForReview],
      [VersionState.Rejected]: [VersionState.PrepareForSubmission],
      [VersionState.PendingDeveloperRelease]: [VersionState.ReadyForSale],
    };
    return transitions[this.state]?.includes(target) ?? false;
  }

  // ── Factory — hydrates from API JSON ──

  static fromJSON(json: Record<string, unknown>): Version {
    return new Version(
      json.id as string,
      json.appId as string,
      json.versionString as string,
      json.state as VersionState,
      json.platform as string,
      (json.affordances as Record<string, string>) ?? {},
    );
  }
}
```

### App — Rich Domain Model

```typescript
// app/App.ts

export class App {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly bundleId: string,
    readonly sku: string,
    readonly primaryLocale: string,
    readonly isAvailableInNewTerritories: boolean,
    readonly affordances: Record<string, string>,  // from API
    readonly contentRightsDeclaration?: string,
  ) {}

  // ── Semantic Booleans ──

  get hasContentRights(): boolean {
    return this.contentRightsDeclaration !== undefined;
  }

  // ── Capability Checks — from server affordances ──

  get canViewVersions(): boolean {
    return "getVersions" in this.affordances;
  }

  get canViewBuilds(): boolean {
    return "getBuilds" in this.affordances;
  }

  // ── Display ──

  get displayName(): string {
    return `${this.name} (${this.bundleId})`;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): App {
    return new App(
      json.id as string,
      json.name as string,
      json.bundleId as string,
      json.sku as string,
      json.primaryLocale as string,
      json.isAvailableInNewTerritories as boolean,
      (json.affordances as Record<string, string>) ?? {},
      json.contentRightsDeclaration as string | undefined,
    );
  }
}
```

### How Components Use Rich Models

Components **ask** the model. They never decide.

```tsx
// version/components/VersionRow.tsx

import { Version } from '../Version';
import { AffordanceBar } from '../../shared/components/AffordanceBar';

export function VersionRow({ version }: { version: Version }) {
  return (
    <tr>
      <td>{version.versionString}</td>
      <td>{version.platform}</td>
      <td>
        {version.isLive && <Badge color="green">Live</Badge>}
        {version.isPending && <Badge color="yellow">Pending</Badge>}
        {version.isRejected && <Badge color="red">Rejected</Badge>}
        {version.isEditable && <Badge color="blue">Editable</Badge>}
      </td>
      <td>
        {version.canSubmit && <Button>Submit for Review</Button>}
        {version.canRelease && <Button>Release</Button>}
      </td>
      <td>
        <AffordanceBar affordances={version.affordances} />
      </td>
    </tr>
  );
}
```

### Hooks Are THIN — No Domain Logic

```typescript
// version/Version.hooks.ts

import { useState, useEffect } from 'react';
import { Version } from './Version';
import { fetchVersions } from './infrastructure/Version.api';
import { useDataMode } from '../shared/api-client';

export function useVersions(appId: string) {
  const [versions, setVersions] = useState<Version[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchVersions(appId, mode)
      .then(setVersions)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [appId, mode]);

  return { versions, loading, error };
}

// No useVersionState() — the model HAS that.
// No useVersionAffordances() — the model HAS that.
// The hook is ONLY a lifecycle wrapper.
```

### Infrastructure Hydrates Rich Models

```typescript
// version/infrastructure/Version.api.ts

import { Version } from '../Version';
import { apiClient } from '../../shared/api-client';

export async function fetchVersions(appId: string, mode: string): Promise<Version[]> {
  if (mode === 'mock') {
    const { mockVersions } = await import('./Version.mock');
    return mockVersions(appId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(
    `/api/v1/apps/${appId}/versions`
  );
  return json.data.map(Version.fromJSON);  // ← hydrate into rich model
}
```

### The Responsibility Split

```
ANEMIC (wrong)                       RICH (correct)
──────────────                       ──────────────

  interface Version { }              class Version {
        │                              get isLive         ← semantic boolean
        ▼                              get canSubmit      ← reads affordances
  isLive(v) ← scattered               canTransitionTo()  ← state machine
  canSubmit(v) ← scattered            static fromJSON()  ← hydration
  affordances(v) ← scattered        }
        │                              │
        ▼                              ▼
  hook gathers logic                 hook is THIN (just fetch + loading)
        │                              │
        ▼                              ▼
  component decides                  component ASKS the model
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

import type { PluginRegistration, PluginPage, PluginSidebarItem, PluginWidget } from './Plugin';

export class PluginRegistry {
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

  getAll(): PluginRegistration[] {
    return [...this.plugins.values()];
  }

  has(id: string): boolean {
    return this.plugins.has(id);
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

```tsx
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

import { createContext, useContext } from 'react';

export type DataMode = 'rest' | 'mock';

const DataModeContext = createContext<DataMode>('rest');
export const DataModeProvider = DataModeContext.Provider;
export const useDataMode = () => useContext(DataModeContext);

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

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

```tsx
// shared/components/AffordanceBar.tsx
import { apiClient } from '../api-client';

interface Props {
  affordances: Record<string, string>;
}

export function AffordanceBar({ affordances }: Props) {
  const entries = Object.entries(affordances);
  if (entries.length === 0) return null;

  const handleClick = async (command: string) => {
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
  return key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase()).trim();
}
```

---

## Routing

React Router wires core pages and dynamically adds plugin pages:

```typescript
// App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Suspense, lazy } from 'react';
import { PluginProvider } from './plugin/PluginContext';
import { pluginRegistry } from './plugin/PluginRegistry';
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

## TDD Workflow

**Write tests first, then implement. Every test must fail (red) before writing implementation.**

### Tech Stack

| Tool | Purpose |
|------|---------|
| **Vitest** | Test runner — fast, Vite-native, same config |
| **React Testing Library** | Component tests — renders real DOM, tests behavior not internals |
| **jsdom** | DOM environment for Vitest |

```bash
# Run all tests
npx vitest

# Run tests for one slice
npx vitest version

# Watch mode
npx vitest --watch
```

### Test Layers

Each slice has up to 3 test layers, written in this order:

```
1. Domain tests    (Feature.test.ts)       — pure TypeScript, no React, no HTTP
2. Infrastructure  (tested via domain)     — fromJSON hydration tested in domain tests
3. Component tests (Component.test.tsx)    — React rendering, user interactions
```

### Layer 1: Domain Model Tests (Pure — No React)

Test the rich model class in isolation. No HTTP, no React, no DOM.

```typescript
// tests/version/Version.test.ts
import { describe, it, expect } from 'vitest';
import { Version, VersionState } from '../../src/version/Version';

describe('Version', () => {

  // ── Semantic Booleans ──

  it('is live when state is READY_FOR_SALE', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.ReadyForSale, 'IOS', {});
    expect(version.isLive).toBe(true);
    expect(version.isEditable).toBe(false);
    expect(version.isPending).toBe(false);
  });

  it('is editable when state is PREPARE_FOR_SUBMISSION', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});
    expect(version.isEditable).toBe(true);
    expect(version.isLive).toBe(false);
  });

  it('is pending when waiting for review', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.WaitingForReview, 'IOS', {});
    expect(version.isPending).toBe(true);
  });

  it('is pending when in review', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.InReview, 'IOS', {});
    expect(version.isPending).toBe(true);
  });

  // ── Capability Checks (from API affordances) ──

  it('can submit when server provides submitForReview affordance', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {
      submitForReview: 'asc versions submit --id v-1',
    });
    expect(version.canSubmit).toBe(true);
  });

  it('cannot submit when server does not provide submitForReview affordance', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});
    expect(version.canSubmit).toBe(false);
  });

  it('can release when server provides releaseVersion affordance', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.PendingDeveloperRelease, 'IOS', {
      releaseVersion: 'asc versions release --id v-1',
    });
    expect(version.canRelease).toBe(true);
  });

  // ── State Transitions ──

  it('can transition from prepare to waiting for review', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});
    expect(version.canTransitionTo(VersionState.WaitingForReview)).toBe(true);
    expect(version.canTransitionTo(VersionState.ReadyForSale)).toBe(false);
  });

  it('can transition from rejected back to prepare', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.Rejected, 'IOS', {});
    expect(version.canTransitionTo(VersionState.PrepareForSubmission)).toBe(true);
  });

  it('live version cannot transition anywhere', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.ReadyForSale, 'IOS', {});
    expect(version.canTransitionTo(VersionState.PrepareForSubmission)).toBe(false);
  });

  // ── Hydration ──

  it('hydrates from API JSON', () => {
    const json = {
      id: 'v-1',
      appId: 'app-1',
      versionString: '2.0',
      state: 'PREPARE_FOR_SUBMISSION',
      platform: 'IOS',
      affordances: { submitForReview: 'asc versions submit --id v-1' },
    };

    const version = Version.fromJSON(json);

    expect(version.id).toBe('v-1');
    expect(version.appId).toBe('app-1');
    expect(version.isEditable).toBe(true);
    expect(version.canSubmit).toBe(true);
  });

  it('hydrates with empty affordances when missing from JSON', () => {
    const json = {
      id: 'v-1',
      appId: 'app-1',
      versionString: '2.0',
      state: 'READY_FOR_SALE',
      platform: 'IOS',
    };

    const version = Version.fromJSON(json);

    expect(version.affordances).toEqual({});
    expect(version.canSubmit).toBe(false);
  });
});
```

### Layer 2: Plugin Registry Tests (Pure — No React)

```typescript
// tests/plugin/PluginRegistry.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { PluginRegistry } from '../../src/plugin/PluginRegistry';

describe('PluginRegistry', () => {
  let registry: PluginRegistry;

  beforeEach(() => {
    registry = new PluginRegistry();
  });

  it('registers a plugin and retrieves its pages', () => {
    registry.register({
      id: 'test-plugin',
      name: 'Test',
      version: '1.0.0',
      pages: [{ path: '/test', title: 'Test', component: () => Promise.resolve({ default: () => null }) }],
    });

    expect(registry.getPages()).toHaveLength(1);
    expect(registry.getPages()[0].path).toBe('/test');
  });

  it('returns widgets for a specific slot sorted by priority', () => {
    const widgetA = { slot: 'dashboard.top', component: () => Promise.resolve({ default: () => null }), priority: 50 };
    const widgetB = { slot: 'dashboard.top', component: () => Promise.resolve({ default: () => null }), priority: 10 };
    const widgetC = { slot: 'other.slot', component: () => Promise.resolve({ default: () => null }) };

    registry.register({ id: 'p1', name: 'P1', version: '1.0', widgets: [widgetA, widgetC] });
    registry.register({ id: 'p2', name: 'P2', version: '1.0', widgets: [widgetB] });

    const dashboardWidgets = registry.getWidgets('dashboard.top');
    expect(dashboardWidgets).toHaveLength(2);
    expect(dashboardWidgets[0].priority).toBe(10);   // B first (lower priority)
    expect(dashboardWidgets[1].priority).toBe(50);   // A second
  });

  it('returns empty array for slot with no widgets', () => {
    expect(registry.getWidgets('nonexistent')).toEqual([]);
  });

  it('aggregates sidebar items from all plugins', () => {
    registry.register({
      id: 'p1', name: 'P1', version: '1.0',
      sidebarItems: [{ id: 's1', label: 'Item 1', section: 'plugins', path: '/p1' }],
    });
    registry.register({
      id: 'p2', name: 'P2', version: '1.0',
      sidebarItems: [{ id: 's2', label: 'Item 2', section: 'plugins', path: '/p2' }],
    });

    expect(registry.getSidebarItems()).toHaveLength(2);
  });

  it('does not duplicate when registering same plugin id twice', () => {
    registry.register({ id: 'p1', name: 'P1', version: '1.0', pages: [{ path: '/a', title: 'A', component: () => Promise.resolve({ default: () => null }) }] });
    registry.register({ id: 'p1', name: 'P1 Updated', version: '2.0', pages: [{ path: '/b', title: 'B', component: () => Promise.resolve({ default: () => null }) }] });

    expect(registry.getAll()).toHaveLength(1);
    expect(registry.getPages()[0].path).toBe('/b');  // latest wins
  });
});
```

### Layer 3: Component Tests (React + DOM)

```tsx
// tests/version/VersionBadge.test.tsx
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { VersionBadge } from '../../src/version/components/VersionBadge';
import { Version, VersionState } from '../../src/version/Version';

describe('VersionBadge', () => {

  it('shows green Live badge for ready for sale version', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.ReadyForSale, 'IOS', {});

    render(<VersionBadge version={version} />);

    expect(screen.getByText('Live')).toBeInTheDocument();
  });

  it('shows Submit button when version can submit', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {
      submitForReview: 'asc versions submit --id v-1',
    });

    render(<VersionBadge version={version} />);

    expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
  });

  it('does not show Submit button when server omits affordance', () => {
    const version = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});

    render(<VersionBadge version={version} />);

    expect(screen.queryByRole('button', { name: /submit/i })).not.toBeInTheDocument();
  });
});
```

### Layer 4: AffordanceBar Tests

```tsx
// tests/shared/AffordanceBar.test.tsx
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AffordanceBar } from '../../src/shared/components/AffordanceBar';

describe('AffordanceBar', () => {

  it('renders nothing when affordances are empty', () => {
    const { container } = render(<AffordanceBar affordances={{}} />);
    expect(container.firstChild).toBeNull();
  });

  it('renders a button for each affordance', () => {
    render(<AffordanceBar affordances={{
      getVersions: 'asc versions list --app-id app-1',
      getBuilds: 'asc builds list --app-id app-1',
    }} />);

    expect(screen.getByText('Get Versions')).toBeInTheDocument();
    expect(screen.getByText('Get Builds')).toBeInTheDocument();
  });

  it('shows the full command as tooltip', () => {
    render(<AffordanceBar affordances={{
      submitForReview: 'asc versions submit --id v-1',
    }} />);

    expect(screen.getByTitle('asc versions submit --id v-1')).toBeInTheDocument();
  });
});
```

### TDD Cycle Per Slice

```
1. Write __tests__/Version.test.ts       → RED   (class doesn't exist)
2. Write Version.ts                      → GREEN (semantic booleans + capability checks pass)
3. Write __tests__/VersionBadge.test.tsx  → RED   (component doesn't exist)
4. Write components/VersionBadge.tsx      → GREEN (renders based on model)
5. Wire Version.hooks.ts                  → connects model to React lifecycle
6. Wire pages/VersionList.tsx             → page uses hook + components
7. npx vitest                             → ALL GREEN
```

### What Gets Tested Where

| What | Test file | React needed? |
|------|-----------|---------------|
| `isLive`, `isEditable`, `isPending` | `version/__tests__/Version.test.ts` | No |
| `canSubmit`, `canRelease` (from affordances) | `version/__tests__/Version.test.ts` | No |
| `canTransitionTo()` | `version/__tests__/Version.test.ts` | No |
| `fromJSON()` hydration | `version/__tests__/Version.test.ts` | No |
| Plugin registration, slot resolution | `plugin/__tests__/PluginRegistry.test.ts` | No |
| Badge renders correctly per state | `version/__tests__/VersionBadge.test.tsx` | Yes |
| Affordance buttons appear/disappear | `shared/__tests__/AffordanceBar.test.tsx` | Yes |
| Data fetching lifecycle | `Version.hooks.ts` | Tested via page integration |

**Most tests are pure TypeScript.** The rich domain model concentrates logic where it can be tested without React, DOM, or mocking. Component tests are thin — they just verify the component asks the model correctly.

---

## Migration Strategy

Progressive migration — React app runs alongside the existing vanilla JS during transition. Both are served by the same Hummingbird backend.

### Phase 1: Scaffold

- Set up Vite + React + TypeScript + Vitest project in `command-center/`
- Configure Vite proxy to forward `/api/*` to Hummingbird backend
- Implement `shared/` kernel: `api-client.ts`, `AffordanceBar`, layout components
- Implement `plugin/` slice: registry, loader, context, slot component
- Port the CSS theme (reuse existing CSS variables)
- **Tests:** `AffordanceBar.test.tsx`, `PluginRegistry.test.ts`

### Phase 2: First Slices

- TDD `app/` slice: `App.test.ts` → `App.ts` → `AppCard.test.tsx` → `AppCard.tsx` → hooks → pages
- TDD `dashboard/` slice
- Verify data flow: React → api-client → Hummingbird → REST API

### Phase 3: Remaining Slices

- TDD slices one by one in priority order:
  1. `version/` — most complex (state machine, semantic booleans, capability checks)
  2. `build/`
  3. `review/`
  4. `testflight/`
  5. `screenshot/`
  6. `code-signing/`
  7. `submission/`
  8. `xcode-cloud/`
  9. `report/`

### Phase 4: Cleanup

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
| **Vitest** | Test runner | Vite-native, fast, same config |
| **React Testing Library** | Component tests | Tests behavior, not implementation |
| **React Router 7** | Routing | Dynamic route registration for plugins |
| **CSS Modules** or **vanilla CSS** | Styling | Reuse existing CSS variables and theme system |

No state management library (Redux, Zustand) — hooks + context are sufficient. Each slice manages its own state via hooks. The domain model owns the logic.

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

To add a new domain slice (e.g. "In-App Purchases"):

1. **Write `IAP.test.ts`** — test semantic booleans, capability checks, fromJSON
2. **Write `IAP.ts`** — rich model class (make tests pass)
3. **Write `IAPRow.test.tsx`** — test component renders based on model
4. **Write `IAPRow.tsx`** — component that asks the model
5. `infrastructure/IAP.api.ts` — REST calls, hydrate via `IAP.fromJSON()`
6. `infrastructure/IAP.mock.ts` — mock data
7. `IAP.hooks.ts` — thin lifecycle wrapper
8. `pages/IAPPage.tsx` — route-level page
9. Register route in `App.tsx` + sidebar item in `Sidebar.tsx`
10. `npx vitest` — all green

One folder. Self-contained. Tests first.