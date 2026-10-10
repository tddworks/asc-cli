---
description: See what regressed in an app's latest version, read power and performance metrics against Apple's goals, and drill into diagnostic signatures and call stacks. Use when checking an app or build for performance regressions.
---

# Power & Performance Metrics

Download power and performance metrics and diagnostic logs for an app or a build. Every flag: [perf-overview](../../commands.md#asc-perf-overview), [perf-metrics](../../commands.md#asc-perf-metrics), [diagnostics](../../commands.md#asc-diagnostics), [diagnostic-logs](../../commands.md#asc-diagnostic-logs).

Drill-down: `perf-overview` (app at a glance) → `perf-metrics` (app or build) → `diagnostics` (signatures for a build) → `diagnostic-logs` (call stacks for a signature).

## Quick start

```bash
asc perf-overview get --app-id 123456789 --pretty
asc perf-metrics list --app-id 123456789 --metric-type HANG --pretty
asc diagnostics list --build-id build-abc --diagnostic-type HANGS --pretty
asc diagnostic-logs list --signature-id sig-1 --pretty
```

## Workflows

### Check the latest version at a glance

```bash
asc perf-overview get --app-id 123456789 --pretty
asc perf-overview get --app-id 123456789 --device-type iPhone --pretty
```

One call returns what Xcode Organizer shows for the app: `regressions` (metrics that got worse in `latestVersion`), `trendingUp` (metrics getting worse across versions), every `metrics` entry with its `latestValue` next to Apple's `goalValue`, and the top `hotspots` (kind `HANGS`, `LAUNCHES` or `DISK_WRITES`):

```json
{
  "id": "123456789",
  "appId": "123456789",
  "platform": "iOS",
  "latestVersion": "2.0",
  "hasRegressions": true,
  "hasHighImpactRegressions": true,
  "regressions": [
    { "category": "LAUNCH", "metric": "launchTime", "latestVersion": "2.0",
      "summary": "Launch time increased 20%", "isHighImpact": true }
  ],
  "trendingUp": [],
  "metrics": [
    { "category": "launch", "identifier": "launchTime", "displayName": "Launch Time",
      "unit": "s", "latestValue": 1.5, "latestVersion": "2.0", "goalValue": 1.0 }
  ],
  "hotspots": [
    { "kind": "HANGS", "signatureId": "sig-1", "signature": "main thread hang in -[UIView layoutSubviews]",
      "weight": 45.2, "count": 12, "sourceFile": "MainView.swift", "lineNumber": 42, "trend": "UP" }
  ],
  "affordances": {
    "getPerfOverview": "asc perf-overview get --app-id 123456789",
    "listAppMetrics": "asc perf-metrics list --app-id 123456789",
    "listBuilds": "asc builds list --app-id 123456789"
  }
}
```

A hotspot's `trend` is `UP` (happening more), `DOWN` (less) or `UNDEFINED`. An app without enough usage data gets empty arrays and `hasRegressions: false`. To dig into a hotspot, pick a build with `asc builds list` and continue below.

### Investigate a slow or hanging build

```bash
# 1. App-level metrics (aggregated across versions), optionally one type
asc perf-metrics list --app-id 123456789 --pretty
asc perf-metrics list --app-id 123456789 --metric-type HANG --pretty

# 2. A specific build's metrics
asc builds list --app-id 123456789
asc perf-metrics list --build-id build-abc --metric-type LAUNCH

# 3. Diagnostic signatures for that build (recurring issues ranked by weight)
asc diagnostics list --build-id build-abc --pretty

# 4. Call stacks for one signature
asc diagnostic-logs list --signature-id sig-1 --pretty
```

Metric types: `HANG`, `LAUNCH`, `MEMORY`, `DISK`, `BATTERY`, `TERMINATION`, `ANIMATION`, `STORAGE`. Diagnostic types: `DISK_WRITES`, `HANGS`, `LAUNCHES`.

### Reading the output

A metric compares the latest value against Apple's goal:

```json
{
  "id": "123456789-LAUNCH-launchTime",
  "parentId": "123456789",
  "parentType": "app",
  "category": "LAUNCH",
  "metricIdentifier": "launchTime",
  "unit": "s",
  "latestValue": 1.5,
  "latestVersion": "2.0",
  "goalValue": 1.0,
  "affordances": { "listAppMetrics": "asc perf-metrics list --app-id 123456789" }
}
```

App metrics carry `listAppMetrics`; build metrics carry `listBuildMetrics`.

A signature's `weight` is its share of occurrences (0–100); `insightDirection` is `UP`, `DOWN` or `UNDEFINED`:

```json
{
  "id": "sig-1",
  "buildId": "build-abc",
  "diagnosticType": "HANGS",
  "signature": "main thread hang in -[UIView layoutSubviews]",
  "weight": 45.2,
  "insightDirection": "UP",
  "affordances": {
    "listLogs": "asc diagnostic-logs list --signature-id sig-1",
    "listSignatures": "asc diagnostics list --build-id build-abc"
  }
}
```

Each log entry has device, OS and app version, and a `callStackSummary` of the top 5 frames joined with ` > ` (e.g. `main > UIKit > layoutSubviews`).

## REST

| CLI | REST |
|---|---|
| `asc perf-overview get --app-id <id> [--device-type <t>]` | `GET /api/v1/apps/<id>/perf-overview[?device-type=<t>]` |
| `asc perf-metrics list --app-id <id> [--metric-type <t>]` | `GET /api/v1/apps/<id>/perf-metrics[?metric-type=<t>]` |
| `asc perf-metrics list --build-id <id> [--metric-type <t>]` | `GET /api/v1/builds/<id>/perf-metrics[?metric-type=<t>]` |
| `asc diagnostics list --build-id <id> [--diagnostic-type <t>]` | `GET /api/v1/builds/<id>/diagnostics[?diagnostic-type=<t>]` |
| `asc diagnostic-logs list --signature-id <id>` | `GET /api/v1/diagnostics/<id>/logs` |

Every app's `_links` include `getPerfOverview`. Metrics link `listAppMetrics` or `listBuildMetrics`; a signature links `listLogs` and `listSignatures`; a log links `listLogs`.

## Gotchas

- `perf-metrics list` requires `--app-id` or `--build-id`; if both are given, `--build-id` is used.
- Diagnostics are per build only; there is no app-level `diagnostics list`.
- Metric and log IDs are synthetic (`{parentId}-{category}-{metric}`, `{signatureId}-{product}-{log}`); they are stable for display but are not Apple IDs.
- `--device-type` is passed to App Store Connect as-is; it echoes back as `deviceType`.

## See also

- [Builds upload](../builds-upload/README.md)
