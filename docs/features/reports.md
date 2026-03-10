# Sales & Finance Reports

Download sales and trends data and financial reports from App Store Connect.

## CLI Usage

### Sales Reports

```bash
asc sales-reports download \
  --vendor-number <number> \
  --report-type <type> \
  --sub-type <sub-type> \
  --frequency <frequency> \
  [--report-date <date>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--vendor-number` | Yes | Your vendor number from App Store Connect |
| `--report-type` | Yes | `SALES`, `PRE_ORDER`, `NEWSSTAND`, `SUBSCRIPTION`, `SUBSCRIPTION_EVENT`, `SUBSCRIBER`, `SUBSCRIPTION_OFFER_CODE_REDEMPTION`, `INSTALLS`, `FIRST_ANNUAL`, `WIN_BACK_ELIGIBILITY` |
| `--sub-type` | Yes | `SUMMARY`, `DETAILED`, `SUMMARY_INSTALL_TYPE`, `SUMMARY_TERRITORY`, `SUMMARY_CHANNEL` |
| `--frequency` | Yes | `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY` |
| `--report-date` | **DAILY: No; WEEKLY/MONTHLY/YEARLY: Yes** | Report date (e.g. `2024-01-15` for daily, `2024-03-02` for weekly — must be a Sunday, `2024-01` for monthly). Optional only for DAILY (omit to get latest). Required for all other frequencies. |
| `--output` | No | `json` (default), `table` |
| `--pretty` | No | Pretty-print JSON output |

**Examples:**

```bash
# Daily sales summary
asc sales-reports download \
  --vendor-number 123456 \
  --report-type SALES \
  --sub-type SUMMARY \
  --frequency DAILY \
  --report-date 2024-01-15

# Monthly subscription report
asc sales-reports download \
  --vendor-number 123456 \
  --report-type SUBSCRIPTION \
  --sub-type SUMMARY \
  --frequency MONTHLY \
  --report-date 2024-01

# Weekly installs report (--report-date required for WEEKLY)
asc sales-reports download \
  --vendor-number 123456 \
  --report-type INSTALLS \
  --sub-type SUMMARY \
  --frequency WEEKLY \
  --report-date 2024-01-07 \
  --output table
```

**JSON output:**

```json
{
  "data" : [
    {
      "Provider" : "APPLE",
      "Provider Country" : "US",
      "SKU" : "com.example.app",
      "Title" : "My App",
      "Units" : "10",
      "Developer Proceeds" : "6.99",
      "Currency of Proceeds" : "USD"
    }
  ]
}
```

**Table output:**

```
Currency of Proceeds  Developer Proceeds  Provider  Provider Country  SKU              Title   Units
--------------------  ------------------  --------  ----------------  ---------------  ------  -----
USD                   6.99                APPLE     US                com.example.app  My App  10
```

### Finance Reports

```bash
asc finance-reports download \
  --vendor-number <number> \
  --report-type <type> \
  --region-code <code> \
  --report-date <date>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--vendor-number` | Yes | Your vendor number from App Store Connect |
| `--report-type` | Yes | `FINANCIAL`, `FINANCE_DETAIL` |
| `--region-code` | Yes | Region code (e.g. `US`, `EU`, `JP`) |
| `--report-date` | Yes | Report date (e.g. `2024-01`) |
| `--output` | No | `json` (default), `table` |
| `--pretty` | No | Pretty-print JSON output |

**Examples:**

```bash
# Financial summary for US region
asc finance-reports download \
  --vendor-number 123456 \
  --report-type FINANCIAL \
  --region-code US \
  --report-date 2024-01

# Detailed finance report for EU
asc finance-reports download \
  --vendor-number 123456 \
  --report-type FINANCE_DETAIL \
  --region-code EU \
  --report-date 2024-01 \
  --pretty
```

## Typical Workflow

```bash
# 1. Download yesterday's sales data
asc sales-reports download \
  --vendor-number 123456 \
  --report-type SALES \
  --sub-type SUMMARY \
  --frequency DAILY \
  --report-date 2024-01-15 \
  --pretty

# 2. Check monthly subscription metrics
asc sales-reports download \
  --vendor-number 123456 \
  --report-type SUBSCRIPTION \
  --sub-type SUMMARY \
  --frequency MONTHLY \
  --report-date 2024-01 \
  --pretty

# 3. Download financial report for proceeds
asc finance-reports download \
  --vendor-number 123456 \
  --report-type FINANCIAL \
  --region-code US \
  --report-date 2024-01 \
  --pretty
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  ASCCommand                                             │
│  ┌───────────────────┐  ┌────────────────────────────┐  │
│  │ SalesReportsCmd   │  │ FinanceReportsCmd          │  │
│  │  └─ download      │  │  └─ download               │  │
│  └───────────────────┘  └────────────────────────────┘  │
│         │  ReportOutputHelper (TSV → JSON/table)        │
├─────────┼───────────────────────────────────────────────┤
│  Domain │                                               │
│  ┌──────┴──────────────────────────────────────────┐    │
│  │ ReportRepository (@Mockable)                    │    │
│  │  downloadSalesReport() -> [[String: String]]    │    │
│  │  downloadFinanceReport() -> [[String: String]]  │    │
│  ├─────────────────────────────────────────────────┤    │
│  │ SalesReportType (10)  SalesReportSubType (5)    │    │
│  │ ReportFrequency (4)   FinanceReportType (2)     │    │
│  └─────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│  Infrastructure                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ SDKReportRepository                             │    │
│  │  1. client.request(salesReports.get(...))       │    │
│  │  2. Data.gunzipped() → TSV string               │    │
│  │  3. TSVParser.parse() → [[String: String]]      │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

Reports are gzip-compressed TSV downloads (not JSON), so Infrastructure decompresses and parses before returning structured data.

## Domain Models

### `SalesReportType` (enum, 10 cases)

`SALES`, `PRE_ORDER`, `NEWSSTAND`, `SUBSCRIPTION`, `SUBSCRIPTION_EVENT`, `SUBSCRIBER`, `SUBSCRIPTION_OFFER_CODE_REDEMPTION`, `INSTALLS`, `FIRST_ANNUAL`, `WIN_BACK_ELIGIBILITY`

### `SalesReportSubType` (enum, 5 cases)

`SUMMARY`, `DETAILED`, `SUMMARY_INSTALL_TYPE`, `SUMMARY_TERRITORY`, `SUMMARY_CHANNEL`

### `ReportFrequency` (enum, 4 cases)

`DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`

### `FinanceReportType` (enum, 2 cases)

`FINANCIAL`, `FINANCE_DETAIL`

### `ReportRepository` (protocol)

```swift
@Mockable
public protocol ReportRepository: Sendable {
    func downloadSalesReport(
        vendorNumber: String,
        reportType: SalesReportType,
        subType: SalesReportSubType,
        frequency: ReportFrequency,
        reportDate: String?
    ) async throws -> [[String: String]]

    func downloadFinanceReport(
        vendorNumber: String,
        reportType: FinanceReportType,
        regionCode: String,
        reportDate: String
    ) async throws -> [[String: String]]
}
```

Reports return `[[String: String]]` — arrays of dictionaries where keys are TSV column headers. Columns vary by report type (50+ schemas), so dynamic dictionaries are used instead of fixed structs.

## File Map

### Sources

```
Sources/
├── Domain/Reports/
│   ├── SalesReportFilter.swift        # SalesReportType, SalesReportSubType, ReportFrequency
│   ├── FinanceReportFilter.swift      # FinanceReportType
│   ├── ReportRepository.swift         # @Mockable protocol (sales + finance)
│   └── Analytics/
│       ├── AnalyticsFilter.swift              # AnalyticsAccessType, AnalyticsCategory, AnalyticsGranularity
│       ├── AnalyticsReportRequest.swift       # Request model + AffordanceProviding
│       ├── AnalyticsReport.swift              # Report model + AffordanceProviding
│       ├── AnalyticsReportInstance.swift       # Instance model + AffordanceProviding
│       ├── AnalyticsReportSegment.swift        # Segment model + AffordanceProviding
│       └── AnalyticsReportRepository.swift     # @Mockable protocol (6 methods)
├── Infrastructure/
│   ├── Reports/
│   │   ├── SDKReportRepository.swift           # Gzip download + TSV parse
│   │   ├── TSVParser.swift                     # Tab-separated values parser
│   │   └── Analytics/
│   │       └── SDKAnalyticsReportRepository.swift  # Analytics SDK adapter
│   └── Client/
│       └── DataExtensions.swift                # Data.gunzipped() via zlib
└── ASCCommand/Commands/
    ├── Reports/
    │   ├── SalesReportsCommand.swift       # Parent: asc sales-reports
    │   ├── SalesReportsDownload.swift      # asc sales-reports download
    │   ├── FinanceReportsCommand.swift     # Parent: asc finance-reports
    │   ├── FinanceReportsDownload.swift    # asc finance-reports download
    │   └── ReportOutputHelper.swift        # JSON/table formatting
    └── AnalyticsReports/
        ├── AnalyticsReportsCommand.swift       # Parent: asc analytics-reports
        ├── AnalyticsReportsRequest.swift       # asc analytics-reports request
        ├── AnalyticsReportsList.swift          # asc analytics-reports list
        ├── AnalyticsReportsDelete.swift        # asc analytics-reports delete
        ├── AnalyticsReportsReportsList.swift   # asc analytics-reports reports
        ├── AnalyticsReportsInstancesList.swift # asc analytics-reports instances
        └── AnalyticsReportsSegmentsList.swift  # asc analytics-reports segments
```

### Tests

```
Tests/
├── DomainTests/Reports/
│   ├── ReportFilterTests.swift                     # Enum raw values + CLI init (26 tests)
│   └── AnalyticsReportTests.swift                  # Analytics models + affordances (34 tests)
├── InfrastructureTests/Reports/
│   ├── SDKReportRepositoryTests.swift              # Gzip, TSV parsing (11 tests)
│   └── SDKAnalyticsReportRepositoryTests.swift     # Analytics parent ID injection (7 tests)
└── ASCCommandTests/Commands/
    ├── Reports/
    │   ├── SalesReportsDownloadTests.swift          # JSON + table output (4 tests)
    │   └── FinanceReportsDownloadTests.swift        # JSON + table output (2 tests)
    └── AnalyticsReports/
        └── AnalyticsReportsTests.swift              # All 6 commands (6 tests)
```

### Wiring Files

| File | Change |
|------|--------|
| `ASC.swift` | Registers `SalesReportsCommand`, `FinanceReportsCommand`, `AnalyticsReportsCommand` |
| `ClientProvider.swift` | `makeReportRepository()`, `makeAnalyticsReportRepository()` |
| `ClientFactory.swift` | `makeReportRepository(...)`, `makeAnalyticsReportRepository(...)` |
| `MockRepositoryFactory.swift` | 4 analytics factory methods |

## API Reference

| Endpoint | SDK Call | Repository Method |
|----------|---------|-------------------|
| `GET /v1/salesReports` | `APIEndpoint.v1.salesReports.get(parameters:)` | `downloadSalesReport(...)` |
| `GET /v1/financeReports` | `APIEndpoint.v1.financeReports.get(parameters:)` | `downloadFinanceReport(...)` |

Sales and finance endpoints return gzip-compressed TSV data (`Request<Data>`). The SDK's `APIProvider.request()` returns raw `Data` when `T` is `Data` (line 343 of APIProvider.swift: `if let data = data as? T`). Analytics endpoints return standard JSON responses.

## Testing

```swift
@Test func `downloads sales report and outputs JSON with row data`() async throws {
    let mockRepo = MockReportRepository()
    given(mockRepo).downloadSalesReport(
        vendorNumber: .any, reportType: .any, subType: .any,
        frequency: .any, reportDate: .any
    ).willReturn([
        ["Provider": "APPLE", "SKU": "com.example", "Units": "10"]
    ])

    let cmd = try SalesReportsDownload.parse([
        "--vendor-number", "123", "--report-type", "SALES",
        "--sub-type", "SUMMARY", "--frequency", "DAILY", "--pretty",
    ])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "Provider" : "APPLE",
          "SKU" : "com.example",
          "Units" : "10"
        }
      ]
    }
    """)
}
```

```bash
swift test --filter 'ReportFilterTests|SDKReportRepository|SalesReportsDownloadTests|FinanceReportsDownloadTests'
```

## Analytics Reports

Analytics reports use a multi-step workflow with structured JSON responses (unlike sales/finance which return TSV).

### Resource Hierarchy

```
App → AnalyticsReportRequest → AnalyticsReport → AnalyticsReportInstance → AnalyticsReportSegment
         (create/list/delete)    (by category)      (by granularity)          (download URL)
```

### Commands

```bash
# 1. Create an analytics report request
asc analytics-reports request --app-id <id> --access-type ONE_TIME_SNAPSHOT|ONGOING

# 2. List existing requests
asc analytics-reports list --app-id <id> [--access-type ONGOING]

# 3. Delete a request
asc analytics-reports delete --request-id <id>

# 4. List reports for a request (filtered by category)
asc analytics-reports reports --request-id <id> [--category APP_USAGE|APP_STORE_ENGAGEMENT|COMMERCE|FRAMEWORK_USAGE|PERFORMANCE]

# 5. List report instances (filtered by granularity)
asc analytics-reports instances --report-id <id> [--granularity DAILY|WEEKLY|MONTHLY]

# 6. Get download URLs for segments
asc analytics-reports segments --instance-id <id>
```

### Analytics Domain Models

**`AnalyticsReportRequest`** — id, appId, accessType, isStoppedDueToInactivity?
- Affordances: `listReports`, `delete`, `listRequests`

**`AnalyticsReport`** — id, requestId, name?, category?
- Categories: `APP_USAGE`, `APP_STORE_ENGAGEMENT`, `COMMERCE`, `FRAMEWORK_USAGE`, `PERFORMANCE`
- Affordances: `listInstances`, `listReports`

**`AnalyticsReportInstance`** — id, reportId, granularity?, processingDate?
- Granularity: `DAILY`, `WEEKLY`, `MONTHLY`
- Affordances: `listSegments`, `listInstances`

**`AnalyticsReportSegment`** — id, instanceId, checksum?, sizeInBytes?, url?
- Affordances: `listSegments`

### Typical Analytics Workflow

```bash
# 1. Request analytics for an app
asc analytics-reports request --app-id 6450000000 --access-type ONE_TIME_SNAPSHOT --pretty

# 2. List available reports (filter to commerce)
asc analytics-reports reports --request-id req-abc --category COMMERCE --pretty

# 3. Get daily instances
asc analytics-reports instances --report-id rpt-xyz --granularity DAILY --pretty

# 4. Get download segments
asc analytics-reports segments --instance-id inst-123 --pretty
# → returns URLs to download the raw analytics data
```

### Analytics API Reference

| Endpoint | SDK Call | Repository Method |
|----------|---------|-------------------|
| `POST /v1/analyticsReportRequests` | `APIEndpoint.v1.analyticsReportRequests.post(body)` | `createRequest(...)` |
| `GET /v1/apps/{id}/analyticsReportRequests` | `APIEndpoint.v1.apps.id(appId).analyticsReportRequests.get(...)` | `listRequests(...)` |
| `DELETE /v1/analyticsReportRequests/{id}` | `APIEndpoint.v1.analyticsReportRequests.id(id).delete` | `deleteRequest(...)` |
| `GET /v1/analyticsReportRequests/{id}/reports` | `APIEndpoint.v1.analyticsReportRequests.id(id).reports.get(...)` | `listReports(...)` |
| `GET /v1/analyticsReports/{id}/instances` | `APIEndpoint.v1.analyticsReports.id(id).instances.get(...)` | `listInstances(...)` |
| `GET /v1/analyticsReportInstances/{id}/segments` | `APIEndpoint.v1.analyticsReportInstances.id(id).segments.get()` | `listSegments(...)` |

## Extending

### Save to File

Add `--save-to <path>` to write raw TSV to a file instead of parsing to JSON, useful for large reports or external processing.
