---
name: asc-iap
description: |
  Manage In-App Purchases (IAPs) using the `asc` CLI tool.
  Use this skill when:
  (1) Listing IAPs: "asc iap list --app-id ID"
  (2) Creating IAPs: "asc iap create --type consumable|non-consumable|non-renewing-subscription"
  (3) IAP localizations: "asc iap-localizations create/list"
  (4) Submitting IAP: "asc iap submit --iap-id ID"
  (5) IAP pricing: "asc iap price-points list", "asc iap prices set"
  (6) IAP offer codes: "asc iap-offer-codes list/create/update"
  (7) IAP custom codes: "asc iap-offer-code-custom-codes list/create/update"
  (8) IAP one-time codes: "asc iap-offer-code-one-time-codes list/create/update"
  (9) User says "create in-app purchase", "list IAPs", "submit IAP", "IAP offer code", "custom code", "one-time codes"
---

# asc In-App Purchases

Manage IAPs via the `asc` CLI.

## List IAPs

```bash
asc iap list --app-id <APP_ID> [--limit N] [--pretty]
```

## Create IAP

```bash
asc iap create \
  --app-id <APP_ID> \
  --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" \
  --type consumable
```

**`--type`** values: `consumable`, `non-consumable`, `non-renewing-subscription`

## Submit IAP for Review

```bash
asc iap submit --iap-id <IAP_ID>
```

State must be `READY_TO_SUBMIT`. The `submit` affordance appears on `InAppPurchase` only when `state == READY_TO_SUBMIT`.

## IAP Price Points

```bash
# List available price tiers (optionally filtered by territory)
asc iap price-points list --iap-id <IAP_ID> [--territory USA]

# Set price schedule (base territory; Apple auto-prices all other territories)
asc iap prices set \
  --iap-id <IAP_ID> \
  --base-territory USA \
  --price-point-id <PRICE_POINT_ID>
```

Each price point result includes a `setPrice` affordance with the ready-to-run `prices set` command.

## IAP Localizations

```bash
# List
asc iap-localizations list --iap-id <IAP_ID>

# Create
asc iap-localizations create \
  --iap-id <IAP_ID> \
  --locale en-US \
  --name "Gold Coins" \
  [--description "In-game currency"]
```

## IAP Offer Codes

Manage offer codes for in-app purchases. Offer codes let you distribute promotional codes to customers.

### List Offer Codes

```bash
asc iap-offer-codes list --iap-id <IAP_ID> [--pretty]
```

### Create Offer Code

```bash
asc iap-offer-codes create \
  --iap-id <IAP_ID> \
  --name "FREEGEMS" \
  --eligibility NON_SPENDER \
  --eligibility CHURNED_SPENDER
```

**`--eligibility`** (repeatable): `NON_SPENDER`, `ACTIVE_SPENDER`, `CHURNED_SPENDER`

### Update Offer Code (activate/deactivate)

```bash
asc iap-offer-codes update --offer-code-id <ID> --active false
```

### Custom Codes

Custom codes are specific redeemable strings (e.g. "FREEGEMS100") tied to an offer code.

```bash
# List
asc iap-offer-code-custom-codes list --offer-code-id <ID>

# Create
asc iap-offer-code-custom-codes create \
  --offer-code-id <ID> \
  --custom-code "FREEGEMS100" \
  --number-of-codes 500 \
  [--expiration-date 2026-12-31]

# Deactivate
asc iap-offer-code-custom-codes update --custom-code-id <ID> --active false
```

### One-Time Use Codes

Generated code batches — Apple creates unique codes for distribution.

```bash
# List
asc iap-offer-code-one-time-codes list --offer-code-id <ID>

# Create
asc iap-offer-code-one-time-codes create \
  --offer-code-id <ID> \
  --number-of-codes 3000 \
  --expiration-date 2026-06-30

# Deactivate
asc iap-offer-code-one-time-codes update --one-time-code-id <ID> --active false
```

## CAEOAS Affordances

Every IAP response embeds ready-to-run follow-up commands:

```json
{
  "affordances": {
    "listLocalizations":  "asc iap-localizations list --iap-id <ID>",
    "createLocalization": "asc iap-localizations create --iap-id <ID> --locale en-US --name <name>",
    "listOfferCodes":     "asc iap-offer-codes list --iap-id <ID>",
    "listPricePoints":    "asc iap price-points list --iap-id <ID>",
    "submit":             "asc iap submit --iap-id <ID>"
  }
}
```

`submit` only appears when `state == READY_TO_SUBMIT`. Each price point includes `setPrice` only when territory is known.

**IAP Offer Code affordances:**
```json
{
  "affordances": {
    "listOfferCodes":  "asc iap-offer-codes list --iap-id <ID>",
    "listCustomCodes": "asc iap-offer-code-custom-codes list --offer-code-id <ID>",
    "listOneTimeCodes":"asc iap-offer-code-one-time-codes list --offer-code-id <ID>",
    "deactivate":      "asc iap-offer-codes update --offer-code-id <ID> --active false"
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

# 1. Create a consumable IAP
IAP_ID=$(asc iap create \
  --app-id "$APP_ID" \
  --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" \
  --type consumable \
  | jq -r '.data[0].id')

# 2. Add localizations
asc iap-localizations create --iap-id "$IAP_ID" --locale en-US --name "Gold Coins" --description "In-game currency"
asc iap-localizations create --iap-id "$IAP_ID" --locale zh-Hans --name "金币"

# 3. Set pricing and submit
PRICE_ID=$(asc iap price-points list --iap-id "$IAP_ID" --territory USA \
  | jq -r '.data[] | select(.customerPrice == "0.99") | .id')
asc iap prices set --iap-id "$IAP_ID" --base-territory USA --price-point-id "$PRICE_ID"
asc iap submit --iap-id "$IAP_ID"

# 4. Create an offer code with custom codes
OC_ID=$(asc iap-offer-codes create \
  --iap-id "$IAP_ID" \
  --name "LAUNCH_PROMO" \
  --eligibility NON_SPENDER \
  --eligibility CHURNED_SPENDER \
  | jq -r '.data[0].id')

asc iap-offer-code-custom-codes create \
  --offer-code-id "$OC_ID" \
  --custom-code "LAUNCH2026" \
  --number-of-codes 1000 \
  --expiration-date 2026-12-31

# 5. Or generate one-time use codes
asc iap-offer-code-one-time-codes create \
  --offer-code-id "$OC_ID" \
  --number-of-codes 5000 \
  --expiration-date 2026-12-31
```

## State Semantics

`InAppPurchaseState` exposes semantic booleans:

| Boolean | True when state is |
|---|---|
| `isEditable` | `MISSING_METADATA`, `REJECTED`, `DEVELOPER_ACTION_NEEDED` |
| `isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` / `isLive` | `APPROVED` |

`IAPCustomerEligibility` values: `NON_SPENDER`, `ACTIVE_SPENDER`, `CHURNED_SPENDER`

Nil optional fields (`description`, `state`, `totalNumberOfCodes`) are omitted from JSON output.
