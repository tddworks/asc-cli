---
name: asc-subscriptions
description: |
  Manage auto-renewable subscriptions using the `asc` CLI tool.
  Use this skill when:
  (1) Subscription groups: "asc subscription-groups list|create"
  (2) Subscriptions: "asc subscriptions list|create|submit"
  (3) Subscription localizations: "asc subscription-localizations list|create"
  (4) Introductory offers: "asc subscription-offers list|create" (FREE_TRIAL, PAY_AS_YOU_GO, PAY_UP_FRONT)
  (5) Offer codes: "asc subscription-offer-codes list/create/update"
  (6) Custom codes: "asc subscription-offer-code-custom-codes list/create/update"
  (7) One-time codes: "asc subscription-offer-code-one-time-codes list/create/update"
  (8) User says "subscription group", "subscription tier", "subscription offer code", "custom code", "one-time codes", "free trial", "promo code"
---

# asc Subscriptions

Manage auto-renewable subscription groups, tiers, and localizations via the `asc` CLI.

## Subscription Groups

```bash
# List
asc subscription-groups list --app-id <APP_ID>

# Create
asc subscription-groups create \
  --app-id <APP_ID> \
  --reference-name "Premium Plans"
```

## Subscriptions

```bash
# List
asc subscriptions list --group-id <GROUP_ID>

# Create
asc subscriptions create \
  --group-id <GROUP_ID> \
  --name "Monthly Premium" \
  --product-id "com.app.monthly" \
  --period ONE_MONTH \
  [--family-sharable] \
  [--group-level 1]
```

**`--period`** values: `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`

## Subscription Localizations

```bash
# List
asc subscription-localizations list --subscription-id <SUBSCRIPTION_ID>

# Create
asc subscription-localizations create \
  --subscription-id <SUBSCRIPTION_ID> \
  --locale en-US \
  --name "Monthly Premium" \
  [--description "Full access, billed monthly"]
```

## Subscription Introductory Offers

```bash
# List
asc subscription-offers list --subscription-id <SUBSCRIPTION_ID>

# Create free trial
asc subscription-offers create \
  --subscription-id <SUBSCRIPTION_ID> \
  --duration ONE_MONTH \
  --mode FREE_TRIAL \
  --periods 1

# Create paid intro offer (price point required for PAY_AS_YOU_GO / PAY_UP_FRONT)
asc subscription-offers create \
  --subscription-id <SUBSCRIPTION_ID> \
  --duration THREE_MONTHS \
  --mode PAY_AS_YOU_GO \
  --periods 3 \
  --territory USA \
  --price-point-id <PRICE_POINT_ID>
```

**`--duration`** values: `THREE_DAYS`, `ONE_WEEK`, `TWO_WEEKS`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`

**`--mode`** values: `FREE_TRIAL`, `PAY_AS_YOU_GO`, `PAY_UP_FRONT` — paid modes require `--price-point-id`

## Subscription Offer Codes

Manage offer codes for subscriptions. Offer codes let you distribute promotional codes with specific eligibility rules and offer terms.

### List Offer Codes

```bash
asc subscription-offer-codes list --subscription-id <SUBSCRIPTION_ID> [--pretty]
```

### Create Offer Code

```bash
asc subscription-offer-codes create \
  --subscription-id <SUBSCRIPTION_ID> \
  --name "SUMMER2026" \
  --duration ONE_MONTH \
  --mode FREE_TRIAL \
  --periods 1 \
  --eligibility NEW \
  --eligibility LAPSED \
  --offer-eligibility STACKABLE
```

**`--eligibility`** (repeatable): `NEW`, `LAPSED`, `WIN_BACK`, `PAID_SUBSCRIBER`
**`--offer-eligibility`**: `STACKABLE`, `INTRODUCTORY`, `SUBSCRIPTION_OFFER`
**`--duration`**: same values as introductory offers
**`--mode`**: `FREE_TRIAL`, `PAY_AS_YOU_GO`, `PAY_UP_FRONT`

### Update Offer Code (activate/deactivate)

```bash
asc subscription-offer-codes update --offer-code-id <ID> --active false
```

### Custom Codes

Custom codes are specific redeemable strings (e.g. "SUMMER2026") tied to an offer code.

```bash
# List
asc subscription-offer-code-custom-codes list --offer-code-id <ID>

# Create
asc subscription-offer-code-custom-codes create \
  --offer-code-id <ID> \
  --custom-code "SUMMER2026" \
  --number-of-codes 1000 \
  [--expiration-date 2026-12-31]

# Deactivate
asc subscription-offer-code-custom-codes update --custom-code-id <ID> --active false
```

### One-Time Use Codes

Generated code batches — Apple creates unique codes for distribution.

```bash
# List
asc subscription-offer-code-one-time-codes list --offer-code-id <ID>

# Create
asc subscription-offer-code-one-time-codes create \
  --offer-code-id <ID> \
  --number-of-codes 5000 \
  --expiration-date 2026-12-31

# Deactivate
asc subscription-offer-code-one-time-codes update --one-time-code-id <ID> --active false
```

## CAEOAS Affordances

Every subscription group response embeds ready-to-run follow-up commands:

**SubscriptionGroup:**
```json
{
  "affordances": {
    "listSubscriptions":  "asc subscriptions list --group-id <ID>",
    "createSubscription": "asc subscriptions create --group-id <ID> --name <name> --product-id <id> --period ONE_MONTH"
  }
}
```

**Subscription:**
```json
{
  "affordances": {
    "createIntroductoryOffer": "asc subscription-offers create --subscription-id <ID> --duration ONE_MONTH --mode FREE_TRIAL --periods 1",
    "createLocalization":      "asc subscription-localizations create --subscription-id <ID> --locale en-US --name <name>",
    "listIntroductoryOffers":  "asc subscription-offers list --subscription-id <ID>",
    "listLocalizations":       "asc subscription-localizations list --subscription-id <ID>",
    "listOfferCodes":          "asc subscription-offer-codes list --subscription-id <ID>"
  }
}
```

**SubscriptionOfferCode:**
```json
{
  "affordances": {
    "listOfferCodes":   "asc subscription-offer-codes list --subscription-id <SUBSCRIPTION_ID>",
    "listCustomCodes":  "asc subscription-offer-code-custom-codes list --offer-code-id <ID>",
    "listOneTimeCodes": "asc subscription-offer-code-one-time-codes list --offer-code-id <ID>",
    "deactivate":       "asc subscription-offer-codes update --offer-code-id <ID> --active false"
  }
}
```

`deactivate` only appears when `isActive == true`.

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')
# If empty: ask user or run `asc apps list | jq -r '.data[0].id'`

# 1. Create a subscription group
GROUP_ID=$(asc subscription-groups create \
  --app-id "$APP_ID" \
  --reference-name "Premium Plans" \
  | jq -r '.data[0].id')

# 2. Create subscription tiers
MONTHLY_ID=$(asc subscriptions create \
  --group-id "$GROUP_ID" \
  --name "Monthly Premium" \
  --product-id "com.app.monthly" \
  --period ONE_MONTH \
  --group-level 1 \
  | jq -r '.data[0].id')

ANNUAL_ID=$(asc subscriptions create \
  --group-id "$GROUP_ID" \
  --name "Annual Premium" \
  --product-id "com.app.annual" \
  --period ONE_YEAR \
  --family-sharable \
  --group-level 2 \
  | jq -r '.data[0].id')

# 3. Add localizations
asc subscription-localizations create --subscription-id "$MONTHLY_ID" --locale en-US --name "Monthly Premium" --description "Full access, billed monthly"
asc subscription-localizations create --subscription-id "$ANNUAL_ID" --locale en-US --name "Annual Premium" --description "Full access, billed annually — save 30%"

# 4. Create an offer code with custom codes
OC_ID=$(asc subscription-offer-codes create \
  --subscription-id "$MONTHLY_ID" \
  --name "SUMMER2026" \
  --duration ONE_MONTH \
  --mode FREE_TRIAL \
  --periods 1 \
  --eligibility NEW \
  --eligibility LAPSED \
  --offer-eligibility STACKABLE \
  | jq -r '.data[0].id')

asc subscription-offer-code-custom-codes create \
  --offer-code-id "$OC_ID" \
  --custom-code "SUMMER2026" \
  --number-of-codes 1000 \
  --expiration-date 2026-12-31

# 5. Or generate one-time use codes
asc subscription-offer-code-one-time-codes create \
  --offer-code-id "$OC_ID" \
  --number-of-codes 5000 \
  --expiration-date 2026-12-31
```

## State Semantics

`SubscriptionState` exposes semantic booleans:

| Boolean | True when state is |
|---|---|
| `isEditable` | `MISSING_METADATA`, `REJECTED`, `DEVELOPER_ACTION_NEEDED` |
| `isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` / `isLive` | `APPROVED` |

`SubscriptionCustomerEligibility` values: `NEW`, `LAPSED`, `WIN_BACK`, `PAID_SUBSCRIBER`
`SubscriptionOfferEligibility` values: `STACKABLE`, `INTRODUCTORY`, `SUBSCRIPTION_OFFER`

Nil optional fields (`description`, `state`, `groupLevel`, `totalNumberOfCodes`) are omitted from JSON output.
