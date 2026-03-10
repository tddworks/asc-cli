---
name: asc-reports
description: |
  Download sales, trends, financial, and analytics reports from App Store Connect using the `asc` CLI tool.
  Use this skill when:
  (1) Downloading sales reports: "asc sales-reports download --vendor-number ... --report-type SALES ..."
  (2) Downloading finance reports: "asc finance-reports download --vendor-number ... --report-type FINANCIAL ..."
  (3) Analytics reports: "asc analytics-reports request/list/reports/instances/segments"
  (4) Checking app sales, revenue, downloads, subscriptions, proceeds, or analytics
  (5) User says "download my sales report", "show sales data", "get financial report", "check my app revenue", "how many downloads", "subscription metrics", "app analytics", "app usage data", "engagement metrics"
---

# asc Sales & Finance Reports

Download sales and trends data and financial reports from App Store Connect. See [commands.md](references/commands.md) for detailed flag reference and valid enum values.

## Commands

### Download a sales report

```bash
asc sales-reports download \
  [--vendor-number <VENDOR_NUMBER>] \
  --report-type SALES \
  --sub-type SUMMARY \
  --frequency DAILY \
  [--report-date 2024-01-15] \
  [--output json|table] \
  [--pretty]
```

`--vendor-number` is **auto-resolved from the active account** if saved via `asc auth login --vendor-number` or `asc auth update --vendor-number`. Explicit `--vendor-number` overrides the stored value. `--report-date` is optional **only for DAILY** frequency — omit to get the latest available daily report. For WEEKLY, MONTHLY, and YEARLY frequencies, `--report-date` is **mandatory** (Apple returns `PARAMETER_ERROR.INVALID` without it).

### Download a finance report

```bash
asc finance-reports download \
  [--vendor-number <VENDOR_NUMBER>] \
  --report-type FINANCIAL \
  --region-code US \
  --report-date 2024-01 \
  [--output json|table] \
  [--pretty]
```

`--vendor-number` is auto-resolved from the active account if saved. All other flags are required for finance reports (including `--report-date`).

## Report Types Quick Reference

| Sales Report Type | Description |
|-------------------|-------------|
| `SALES` | App and in-app purchase sales |
| `PRE_ORDER` | Pre-order data |
| `SUBSCRIPTION` | Auto-renewable subscription activity |
| `SUBSCRIPTION_EVENT` | Subscription lifecycle events |
| `SUBSCRIBER` | Active subscriber counts |
| `INSTALLS` | First-time downloads |
| `FIRST_ANNUAL` | First annual subscription renewals |
| `WIN_BACK_ELIGIBILITY` | Win-back offer eligible users |

| Finance Report Type | Description |
|---------------------|-------------|
| `FINANCIAL` | Financial summary with proceeds |
| `FINANCE_DETAIL` | Detailed financial breakdown |

## Output Format

Reports return dynamic TSV data from Apple, parsed into JSON arrays. Column names vary by report type.

```json
{
  "data" : [
    {
      "Provider" : "APPLE",
      "SKU" : "com.example.app",
      "Title" : "My App",
      "Units" : "10",
      "Developer Proceeds" : "6.99",
      "Currency of Proceeds" : "USD"
    }
  ]
}
```

Use `--output table` for a tabular view of the same data.

## Typical Workflow

```bash
# 0. Save vendor number once (found in App Store Connect → Payments and Financial Reports)
asc auth update --vendor-number 88012345

# 1. Get daily sales summary (vendor number auto-resolved)
asc sales-reports download \
  --report-type SALES \
  --sub-type SUMMARY \
  --frequency DAILY \
  --report-date 2024-01-15 \
  --pretty

# 2. Check monthly subscription metrics
asc sales-reports download \
  --report-type SUBSCRIPTION \
  --sub-type SUMMARY \
  --frequency MONTHLY \
  --report-date 2024-01 \
  --pretty

# 3. Download financial report for US proceeds
asc finance-reports download \
  --report-type FINANCIAL \
  --region-code US \
  --report-date 2024-01 \
  --pretty
```

## Important Notes

- **Vendor number auto-resolution**: Save it once with `asc auth update --vendor-number <number>` or `asc auth login --vendor-number <number>`. All report commands auto-resolve from the active account. Use `--vendor-number` to override.
- The vendor number can be found in App Store Connect under "Sales and Trends" → "Payments and Financial Reports"
- Reports are gzip-compressed TSV from Apple's API — the CLI handles decompression and parsing automatically
- `--report-date` is only optional for DAILY frequency; WEEKLY, MONTHLY, and YEARLY **require** it. Weekly dates must be a Sunday.
- Not all report type + sub-type + frequency combinations are valid; Apple returns an error for unsupported combinations
- Finance reports require `--region-code` (e.g. `US`, `EU`, `JP`, `AU`) and `--report-date`
- Daily reports are typically available after a 1-day delay; monthly reports after the month ends

## Analytics Reports

Multi-step workflow for app engagement, commerce, usage, framework, and performance analytics.

### Commands

```bash
# Create a report request
asc analytics-reports request --app-id <id> --access-type ONE_TIME_SNAPSHOT|ONGOING

# List existing requests
asc analytics-reports list --app-id <id> [--access-type ONGOING]

# Delete a request
asc analytics-reports delete --request-id <id>

# List reports by category
asc analytics-reports reports --request-id <id> [--category APP_USAGE|APP_STORE_ENGAGEMENT|COMMERCE|FRAMEWORK_USAGE|PERFORMANCE]

# List instances by granularity
asc analytics-reports instances --report-id <id> [--granularity DAILY|WEEKLY|MONTHLY]

# Get download URLs
asc analytics-reports segments --instance-id <id>
```

### Analytics Workflow

```bash
# 1. Request analytics
asc analytics-reports request --app-id 6450000000 --access-type ONE_TIME_SNAPSHOT --pretty

# 2. List commerce reports
asc analytics-reports reports --request-id req-abc --category COMMERCE --pretty

# 3. Get daily instances
asc analytics-reports instances --report-id rpt-xyz --granularity DAILY --pretty

# 4. Get download URLs
asc analytics-reports segments --instance-id inst-123 --pretty
```

Analytics responses include CAEOAS affordances guiding the agent through each step of the hierarchy.

## Reference

See [commands.md](references/commands.md) for the full list of valid enum values for each flag.