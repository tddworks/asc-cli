# Power & Performance Metrics

Download power and performance metrics and diagnostics logs to monitor app performance indicators such as launch time, hang rate, disk writes, memory use, and battery life.

## CLI Usage

### `asc perf-metrics list`

List performance metrics for an app or a specific build.

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | One of app-id/build-id | App ID to fetch metrics for |
| `--build-id` | One of app-id/build-id | Build ID to fetch metrics for |
| `--metric-type` | No | Filter: HANG, LAUNCH, MEMORY, DISK, BATTERY, TERMINATION, ANIMATION |
| `--output` | No | Output format: json (default), table, markdown |
| `--pretty` | No | Pretty-print JSON output |

```bash
# App-level metrics (aggregated across versions)
asc perf-metrics list --app-id 123456789

# Build-specific metrics
asc perf-metrics list --build-id build-abc --metric-type LAUNCH

# Pretty JSON
asc perf-metrics list --app-id 123456789 --metric-type HANG --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "id": "123456789-LAUNCH-launchTime",
      "parentId": "123456789",
      "parentType": "app",
      "platform": "IOS",
      "category": "LAUNCH",
      "metricIdentifier": "launchTime",
      "unit": "s",
      "latestValue": 1.5,
      "latestVersion": "2.0",
      "goalValue": 1.0,
      "affordances": {
        "listAppMetrics": "asc perf-metrics list --app-id 123456789"
      }
    }
  ]
}
```

**Table output:**
```
ID                              Category  Metric      Value  Unit  Goal
123456789-LAUNCH-launchTime     LAUNCH    launchTime  1.5    s     1.0
123456789-HANG-hangRate         HANG      hangRate    0.02   %     -
```

### `asc diagnostics list`

List diagnostic signatures for a build. Signatures represent recurring issues (hangs, disk writes, slow launches) ranked by weight (percentage of occurrences).

| Flag | Required | Description |
|------|----------|-------------|
| `--build-id` | Yes | Build ID |
| `--diagnostic-type` | No | Filter: DISK_WRITES, HANGS, LAUNCHES |
| `--output` | No | Output format: json (default), table, markdown |
| `--pretty` | No | Pretty-print JSON output |

```bash
# All diagnostics for a build
asc diagnostics list --build-id build-abc

# Only hang diagnostics
asc diagnostics list --build-id build-abc --diagnostic-type HANGS --pretty
```

**JSON output:**
```json
{
  "data": [
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
  ]
}
```

### `asc diagnostic-logs list`

List diagnostic logs (call stacks and metadata) for a specific signature.

| Flag | Required | Description |
|------|----------|-------------|
| `--signature-id` | Yes | Diagnostic signature ID |
| `--output` | No | Output format: json (default), table, markdown |
| `--pretty` | No | Pretty-print JSON output |

```bash
asc diagnostic-logs list --signature-id sig-1 --pretty
```

**JSON output:**
```json
{
  "data": [
    {
      "id": "sig-1-0-0",
      "signatureId": "sig-1",
      "bundleId": "com.example.app",
      "appVersion": "2.0",
      "buildVersion": "100",
      "osVersion": "iOS 17.0",
      "deviceType": "iPhone15,2",
      "event": "hang",
      "callStackSummary": "main > UIKit > layoutSubviews",
      "affordances": {
        "listLogs": "asc diagnostic-logs list --signature-id sig-1"
      }
    }
  ]
}
```

## Typical Workflow

```bash
# 1. Find your app
asc apps list

# 2. Check app-level performance metrics
asc perf-metrics list --app-id 123456789 --pretty

# 3. Filter to specific metric type
asc perf-metrics list --app-id 123456789 --metric-type HANG --pretty

# 4. Check a specific build's metrics
asc builds list --app-id 123456789
asc perf-metrics list --build-id build-abc --pretty

# 5. Investigate diagnostic signatures for a build
asc diagnostics list --build-id build-abc --pretty

# 6. Drill into a specific signature's call stacks
asc diagnostic-logs list --signature-id sig-1 --pretty
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  ASCCommand                                                       │
│  ├── PerfMetricsCommand                                           │
│  │   └── PerfMetricsList  --app-id | --build-id [--metric-type]   │
│  ├── DiagnosticsCommand                                           │
│  │   └── DiagnosticsList  --build-id [--diagnostic-type]          │
│  └── DiagnosticLogsCommand                                        │
│      └── DiagnosticLogsList  --signature-id                       │
├──────────────────────────────────────────────────────────────────┤
│  Infrastructure                                                    │
│  ├── SDKPerfMetricsRepository                                     │
│  │   └── flattens XcodeMetrics → [PerformanceMetric]              │
│  └── SDKDiagnosticsRepository                                     │
│      └── maps DiagnosticSignaturesResponse → [DiagnosticSignature]│
│      └── maps DiagnosticLogs → [DiagnosticLogEntry]               │
├──────────────────────────────────────────────────────────────────┤
│  Domain                                                            │
│  ├── PerformanceMetric + PerformanceMetricCategory                │
│  ├── PerfMetricsRepository (@Mockable)                            │
│  ├── DiagnosticSignatureInfo + DiagnosticType                     │
│  ├── DiagnosticLogEntry                                           │
│  └── DiagnosticsRepository (@Mockable)                            │
└──────────────────────────────────────────────────────────────────┘
```

All layers follow unidirectional dependency: `ASCCommand → Infrastructure → Domain`.

## Domain Models

### `PerformanceMetric`

Flattened representation of one metric from the deeply nested `XcodeMetrics` API response.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Synthetic: `{parentId}-{category}-{metricIdentifier}` |
| `parentId` | `String` | App ID or Build ID (injected by infrastructure) |
| `parentType` | `PerfMetricParentType` | `.app` or `.build` |
| `platform` | `String?` | e.g. `"IOS"` |
| `category` | `PerformanceMetricCategory` | HANG, LAUNCH, MEMORY, DISK, BATTERY, TERMINATION, ANIMATION |
| `metricIdentifier` | `String` | e.g. `"launchTime"`, `"peakMemory"` |
| `unit` | `String?` | e.g. `"s"`, `"MB"` |
| `latestValue` | `Double?` | Most recent data point value |
| `latestVersion` | `String?` | App version of latest data point |
| `goalValue` | `Double?` | Apple's recommended goal |

**Affordances:**
- When `parentType == .app`: `listAppMetrics` → `asc perf-metrics list --app-id {parentId}`
- When `parentType == .build`: `listBuildMetrics` → `asc perf-metrics list --build-id {parentId}`

### `DiagnosticSignatureInfo`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Signature ID from API |
| `buildId` | `String` | Parent build ID (injected) |
| `diagnosticType` | `DiagnosticType` | DISK_WRITES, HANGS, LAUNCHES |
| `signature` | `String` | Human-readable signature description |
| `weight` | `Double` | Percentage of occurrences (0-100) |
| `insightDirection` | `String?` | `"UP"`, `"DOWN"`, or `"UNDEFINED"` |

**Affordances:** `listLogs`, `listSignatures`

### `DiagnosticLogEntry`

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Synthetic: `{signatureId}-{productIndex}-{logIndex}` |
| `signatureId` | `String` | Parent signature ID (injected) |
| `bundleId` | `String?` | App bundle identifier |
| `appVersion` | `String?` | App version |
| `buildVersion` | `String?` | Build number |
| `osVersion` | `String?` | OS version |
| `deviceType` | `String?` | Device model identifier |
| `event` | `String?` | Event type (e.g. `"hang"`) |
| `callStackSummary` | `String?` | Top 5 frames, joined with ` > ` |

**Affordances:** `listLogs`

## File Map

### Sources

```
Sources/
├── Domain/Apps/Performance/
│   ├── PerfPowerMetric.swift              # PerformanceMetric, PerformanceMetricCategory, PerfMetricParentType
│   ├── PerfMetricsRepository.swift        # @Mockable protocol
│   ├── DiagnosticSignatureInfo.swift      # DiagnosticSignatureInfo, DiagnosticType
│   ├── DiagnosticLogEntry.swift           # DiagnosticLogEntry
│   └── DiagnosticsRepository.swift        # @Mockable protocol
├── Infrastructure/Apps/Performance/
│   ├── SDKPerfMetricsRepository.swift     # Flattens XcodeMetrics → [PerformanceMetric]
│   └── SDKDiagnosticsRepository.swift     # Maps signatures + logs
└── ASCCommand/Commands/Performance/
    ├── PerfMetricsCommand.swift           # asc perf-metrics list
    ├── DiagnosticsCommand.swift           # asc diagnostics list
    └── DiagnosticLogsCommand.swift        # asc diagnostic-logs list
```

### Tests

```
Tests/
├── DomainTests/Apps/Performance/
│   ├── PerfPowerMetricTests.swift
│   ├── DiagnosticSignatureInfoTests.swift
│   └── DiagnosticLogEntryTests.swift
├── InfrastructureTests/Apps/Performance/
│   ├── SDKPerfMetricsRepositoryTests.swift
│   └── SDKDiagnosticsRepositoryTests.swift
└── ASCCommandTests/Commands/Performance/
    ├── PerfMetricsListTests.swift
    ├── DiagnosticsListTests.swift
    └── DiagnosticLogsListTests.swift
```

### Wiring Files

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | `makePerfMetricsRepository`, `makeDiagnosticsRepository` |
| `Sources/ASCCommand/ClientProvider.swift` | Static factory methods |
| `Sources/ASCCommand/ASC.swift` | Registered `PerfMetricsCommand`, `DiagnosticsCommand`, `DiagnosticLogsCommand` |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | `makePerfPowerMetric`, `makeDiagnosticSignatureInfo`, `makeDiagnosticLogEntry` |

## API Reference

| Endpoint | SDK Call | Repository Method |
|----------|---------|-------------------|
| `GET /v1/apps/{id}/perfPowerMetrics` | `APIEndpoint.v1.apps.id().perfPowerMetrics.get()` | `PerfMetricsRepository.listAppMetrics(appId:metricType:)` |
| `GET /v1/builds/{id}/perfPowerMetrics` | `APIEndpoint.v1.builds.id().perfPowerMetrics.get()` | `PerfMetricsRepository.listBuildMetrics(buildId:metricType:)` |
| `GET /v1/builds/{id}/diagnosticSignatures` | `APIEndpoint.v1.builds.id().diagnosticSignatures.get()` | `DiagnosticsRepository.listSignatures(buildId:diagnosticType:)` |
| `GET /v1/diagnosticSignatures/{id}/logs` | `APIEndpoint.v1.diagnosticSignatures.id().logs.get()` | `DiagnosticsRepository.listLogs(signatureId:)` |

## Testing

```bash
# All performance tests
swift test --filter 'PerformanceMetric|DiagnosticSignature|DiagnosticLogEntry|SDKPerfMetrics|SDKDiagnostics|PerfMetricsList|DiagnosticsList|DiagnosticLogsList'

# All tests
swift test
```

Representative test:
```swift
@Test func `listed app metrics show category, value, and affordances`() async throws {
    let mockRepo = MockPerfMetricsRepository()
    given(mockRepo).listAppMetrics(appId: .any, metricType: .any).willReturn([
        PerformanceMetric(
            id: "app-1-LAUNCH-launchTime", parentId: "app-1", parentType: .app,
            platform: "IOS", category: .launch, metricIdentifier: "launchTime",
            unit: "s", latestValue: 1.5, latestVersion: "2.0", goalValue: 1.0
        )
    ])
    let cmd = try PerfMetricsList.parse(["--app-id", "app-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)
    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "listAppMetrics" : "asc perf-metrics list --app-id app-1"
          },
          "category" : "LAUNCH",
          ...
        }
      ]
    }
    """)
}
```

## Extending

**Build-specific metrics in Build affordances:** Add `listPerfMetrics` affordance to the `Build` domain model to enable navigation from build lists.

**Insights endpoint:** The `XcodeMetrics` response includes `insights.trendingUp` and `insights.regressions` arrays. A future `asc perf-metrics insights --app-id <id>` command could surface these.

**Device filtering:** Both endpoints support `--device-type` filtering (e.g. `iPhone15,2`). Add `--device-type` option to `PerfMetricsList`.
