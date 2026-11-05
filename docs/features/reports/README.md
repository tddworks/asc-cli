---
description: Download sales, finance and analytics reports from App Store Connect, and roll daily sales into a summary. Use when you need downloads, proceeds or usage data for an app.
---

# Sales, Finance & Analytics Reports

Sales and trends data, financial reports, and the multi-step analytics report flow. Every flag: [sales-reports](../../commands.md#asc-sales-reports), [finance-reports](../../commands.md#asc-finance-reports), [analytics-reports](../../commands.md#asc-analytics-reports).

## Quick start

```bash
asc auth update --vendor-number 88012345   # once; found in ASC → Payments and Financial Reports
asc sales-reports download --report-type SALES --sub-type SUMMARY --frequency DAILY --report-date 2024-01-15 --pretty
asc sales-reports summary --from 2026-05-13 --to 2026-05-18 --pretty
```

## Workflows

### Download sales reports

```bash
# Monthly subscription report
asc sales-reports download --report-type SUBSCRIPTION --sub-type SUMMARY \
  --frequency MONTHLY --report-date 2024-01

# Weekly sales report as a table
asc sales-reports download --report-type SALES --sub-type SUMMARY \
  --frequency WEEKLY --report-date 2024-01-07 --output table
```

Each row is the report's TSV columns as keys, so fields vary by report type:

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

Report types: `SALES`, `PRE_ORDER`, `NEWSSTAND`, `SUBSCRIPTION`, `SUBSCRIPTION_EVENT`, `SUBSCRIBER`, `SUBSCRIPTION_OFFER_CODE_REDEMPTION`, `INSTALLS`, `FIRST_ANNUAL`, `WIN_BACK_ELIGIBILITY`. Sub-types: `SUMMARY`, `DETAILED`, `SUMMARY_INSTALL_TYPE`, `SUMMARY_TERRITORY`, `SUMMARY_CHANNEL`.

### Summarize a date range

`summary` aggregates daily Sales reports into one rollup:

```bash
asc sales-reports summary --from 2026-05-13 --to 2026-05-18 --pretty
# {
#   "customerSpend" : { "CNY" : 48 },
#   "days" : 6,
#   "downloads" : 58,
#   "from" : "2026-05-13",
#   "inAppPurchases" : 9,
#   "payers" : 1,
#   "proceeds" : { "USD" : 41.94 },
#   "to" : "2026-05-18",
#   "updates" : 12
# }
```

| Metric | How it's counted |
|---|---|
| `downloads` | Sum of `Units` where `Product Type Identifier` starts with `1` (iOS) or `F` (macOS); excludes `3F` (Apple Watch redownloads), `7*` (updates), `IA*` (in-app purchases) |
| `updates` | Sum of `Units` where PTI starts with `7` |
| `inAppPurchases` | Sum of `Units` where PTI starts with `IA` |
| `payers` | Distinct SKUs where `Customer Price > 0` |
| `customerSpend` | `Customer Currency` → sum of `Customer Price × Units` |
| `proceeds` | `Currency of Proceeds` → sum of `Developer Proceeds × Units` (your actual payout) |

### Download finance reports

```bash
asc finance-reports download --report-type FINANCIAL --region-code US --report-date 2024-01
asc finance-reports download --report-type FINANCE_DETAIL --region-code EU --report-date 2024-01 --pretty
```

### Analytics reports

Analytics use a request → report → instance → segment chain and return JSON (not TSV):

```bash
# 1. Request analytics for an app (or ONGOING)
asc analytics-reports request --app-id 6450000000 --access-type ONE_TIME_SNAPSHOT --pretty

# 2. List reports for the request, optionally by category
asc analytics-reports reports --request-id req-abc --category COMMERCE --pretty

# 3. List instances, optionally by granularity (DAILY, WEEKLY, MONTHLY)
asc analytics-reports instances --report-id rpt-xyz --granularity DAILY --pretty

# 4. Get segments, which carry the URLs to download the raw data
asc analytics-reports segments --instance-id inst-123 --pretty

# Manage requests
asc analytics-reports list --app-id 6450000000 --access-type ONGOING
asc analytics-reports delete --request-id req-abc
```

Categories: `APP_USAGE`, `APP_STORE_ENGAGEMENT`, `COMMERCE`, `FRAMEWORK_USAGE`, `PERFORMANCE`. Each object's affordances point to the next step (`listReports`, `listInstances`, `listSegments`).

## REST

Reports are CLI-only; `asc web-server` has no report routes yet.

## Gotchas

- `--vendor-number` is optional: it is auto-resolved from the active account (saved via `asc auth login --vendor-number` or `asc auth update --vendor-number`). An explicit value overrides it.
- `--report-date` is optional only for `DAILY` (omit it to get the latest). `WEEKLY`, `MONTHLY` and `YEARLY` require it. Weekly dates must be a Sunday (e.g. `2024-01-07`); monthly dates look like `2024-01`.
- `--version` sets the report schema version (e.g. `1_4` for `SALES/SUMMARY/DAILY`); omit it for Apple's default. An invalid value comes back as `PARAMETER_ERROR.INVALID` with the latest supported version.
- Sales and finance reports are gzip-compressed TSV from Apple; asc decompresses and parses them, so columns differ per report type.
- `customerSpend` and `proceeds` are kept per currency, because summing across currencies would be meaningless.
- Apple amends daily reports for up to 5 days. `summary` reads the same `/v1/salesReports` data as `download`, so the most recent day may not match the App Store Connect mobile app's Trends view (which uses an internal endpoint).
- `INSTALLS` is deprecated: since November 4, 2026 Apple no longer generates new reports of this type, but historical ones still download.

## See also

[asc-auth](../asc-auth/README.md)
