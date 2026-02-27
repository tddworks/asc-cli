---
name: asc-iap
description: |
  Manage In-App Purchases (IAPs) using the `asc` CLI tool.
  Use this skill when:
  (1) Listing IAPs for an app: "asc iap list --app-id ID"
  (2) Creating an IAP: "asc iap create --app-id ID --type consumable|non-consumable|non-renewing-subscription"
  (3) Adding IAP localizations: "asc iap-localizations create --iap-id ID --locale en-US --name 'Gold Coins'"
  (4) Submitting an IAP for review: "asc iap submit --iap-id ID"
  (5) Listing IAP price points: "asc iap price-points list --iap-id ID [--territory USA]"
  (6) Setting IAP pricing: "asc iap prices set --iap-id ID --base-territory USA --price-point-id ID"
  (7) User says "create in-app purchase", "list IAPs", "localize IAP", "submit IAP", "set IAP price"
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

## CAEOAS Affordances

Every IAP response embeds ready-to-run follow-up commands:

```json
{
  "affordances": {
    "listLocalizations":  "asc iap-localizations list --iap-id <ID>",
    "createLocalization": "asc iap-localizations create --iap-id <ID> --locale en-US --name <name>",
    "listPricePoints":    "asc iap price-points list --iap-id <ID>",
    "submit":             "asc iap submit --iap-id <ID>"
  }
}
```

`submit` only appears when `state == READY_TO_SUBMIT`. Each price point includes `setPrice` only when territory is known.

## Typical Workflow

```bash
APP_ID="A123456789"

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
```

## State Semantics

`InAppPurchaseState` exposes semantic booleans:

| Boolean | True when state is |
|---|---|
| `isEditable` | `MISSING_METADATA`, `REJECTED`, `DEVELOPER_ACTION_NEEDED` |
| `isPendingReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` / `isLive` | `APPROVED` |

Nil optional fields (`description`, `state`) are omitted from JSON output.
