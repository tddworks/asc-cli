# Reports Command Reference

## asc sales-reports download

Download a sales report from App Store Connect.

### Required Flags

| Flag | Description |
|------|-------------|
| `--report-type` | Type of sales report (see values below) |
| `--sub-type` | Report sub-type (see values below) |
| `--frequency` | Reporting frequency (see values below) |

### Optional Flags

| Flag | Description |
|------|-------------|
| `--vendor-number` | Vendor number (auto-resolved from active account if saved via `asc auth update --vendor-number`) |

### Conditionally Required Flags

| Flag | Description |
|------|-------------|
| `--report-date` | Report date (e.g. `2024-01-15` for daily, `2024-03-01` for weekly, `2024-01` for monthly). **Optional for DAILY** (omit to get latest). **Required for WEEKLY, MONTHLY, and YEARLY** — Apple returns `PARAMETER_ERROR.INVALID` without it. Weekly dates must be a Sunday. |

### Optional Flags

| Flag | Description |
|------|-------------|
| `--output` | Output format: `json` (default), `table` |
| `--pretty` | Pretty-print JSON output |

### Report Type Values (`--report-type`)

| Value | Description |
|-------|-------------|
| `SALES` | App and in-app purchase sales data |
| `PRE_ORDER` | Pre-order metrics |
| `NEWSSTAND` | Newsstand subscription data |
| `SUBSCRIPTION` | Auto-renewable subscription activity |
| `SUBSCRIPTION_EVENT` | Subscription lifecycle events (trial start, cancel, etc.) |
| `SUBSCRIBER` | Active subscriber counts |
| `SUBSCRIPTION_OFFER_CODE_REDEMPTION` | Offer code redemption data |
| `INSTALLS` | First-time app downloads |
| `FIRST_ANNUAL` | First annual subscription renewal data |
| `WIN_BACK_ELIGIBILITY` | Users eligible for win-back offers |

### Report Sub-Type Values (`--sub-type`)

| Value | Description |
|-------|-------------|
| `SUMMARY` | Aggregated summary |
| `DETAILED` | Per-transaction detail |
| `SUMMARY_INSTALL_TYPE` | Summary grouped by install type |
| `SUMMARY_TERRITORY` | Summary grouped by territory/country |
| `SUMMARY_CHANNEL` | Summary grouped by channel |

### Frequency Values (`--frequency`)

| Value | Description |
|-------|-------------|
| `DAILY` | Daily report |
| `WEEKLY` | Weekly report |
| `MONTHLY` | Monthly report |
| `YEARLY` | Yearly report |

### Examples

```bash
# Daily sales summary (latest)
asc sales-reports download \
  --vendor-number 123456 \
  --report-type SALES \
  --sub-type SUMMARY \
  --frequency DAILY

# Monthly subscription report for January 2024
asc sales-reports download \
  --vendor-number 123456 \
  --report-type SUBSCRIPTION \
  --sub-type SUMMARY \
  --frequency MONTHLY \
  --report-date 2024-01 \
  --pretty

# Detailed installs by territory (--report-date required for WEEKLY)
asc sales-reports download \
  --vendor-number 123456 \
  --report-type INSTALLS \
  --sub-type SUMMARY_TERRITORY \
  --frequency WEEKLY \
  --report-date 2024-01-07 \
  --output table
```

---

## asc finance-reports download

Download a financial report from App Store Connect.

### Required Flags

| Flag | Description |
|------|-------------|
| `--report-type` | Type of finance report (see values below) |
| `--region-code` | Region code (e.g. `US`, `EU`, `JP`, `AU`) |
| `--report-date` | Report date (e.g. `2024-01`) |

### Optional Flags

| Flag | Description |
|------|-------------|
| `--vendor-number` | Vendor number (auto-resolved from active account if saved via `asc auth update --vendor-number`) |
| `--output` | Output format: `json` (default), `table` |
| `--pretty` | Pretty-print JSON output |

### Report Type Values (`--report-type`)

| Value | Description |
|-------|-------------|
| `FINANCIAL` | Financial summary with proceeds |
| `FINANCE_DETAIL` | Detailed financial breakdown by transaction |

### Examples

```bash
# US financial summary for January 2024
asc finance-reports download \
  --vendor-number 123456 \
  --report-type FINANCIAL \
  --region-code US \
  --report-date 2024-01 \
  --pretty

# Detailed EU finance report
asc finance-reports download \
  --vendor-number 123456 \
  --report-type FINANCE_DETAIL \
  --region-code EU \
  --report-date 2024-01 \
  --output table
```