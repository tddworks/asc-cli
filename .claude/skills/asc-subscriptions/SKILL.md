---
name: asc-subscriptions
description: |
  Manage auto-renewable subscriptions using the `asc` CLI tool.
  Use this skill when:
  (1) Listing subscription groups: "asc subscription-groups list --app-id ID"
  (2) Creating a subscription group: "asc subscription-groups create --app-id ID --reference-name 'Premium'"
  (3) Listing subscriptions: "asc subscriptions list --group-id ID"
  (4) Creating a subscription: "asc subscriptions create --group-id ID --period ONE_MONTH"
  (5) Listing subscription localizations: "asc subscription-localizations list --subscription-id ID"
  (6) Adding subscription localizations: "asc subscription-localizations create --subscription-id ID --locale en-US --name 'Monthly'"
  (7) User says "add subscription tier", "create subscription group", "manage subscriptions", "localize subscription", "subscription plans"
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
    "listLocalizations":  "asc subscription-localizations list --subscription-id <ID>",
    "createLocalization": "asc subscription-localizations create --subscription-id <ID> --locale en-US --name <name>"
  }
}
```

## Typical Workflow

```bash
APP_ID="A123456789"

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
```

## State Semantics

`SubscriptionState` exposes semantic booleans:

| Boolean | True when state is |
|---|---|
| `isEditable` | `MISSING_METADATA`, `REJECTED`, `DEVELOPER_ACTION_NEEDED` |
| `isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` / `isLive` | `APPROVED` |

Nil optional fields (`description`, `state`, `groupLevel`) are omitted from JSON output.
