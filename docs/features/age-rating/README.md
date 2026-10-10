---
description: Read and update an app's age rating declaration (content descriptors, kids age band, regional overrides). Use when answering the age rating questionnaire or changing the store age rating.
---

# Age Rating

Read and update the age rating declaration that determines the store-displayed rating (e.g. "4+", "12+", "17+"). Every flag: [command reference](../../commands.md#asc-age-rating).

## Quick start
```bash
asc app-infos list --app-id <APP_ID> --output table
asc age-rating get --app-info-id <APP_INFO_ID> --pretty
asc age-rating update --declaration-id <DECLARATION_ID> --violence-realistic NONE --gambling false
```

## Workflows

### Answer the questionnaire
```bash
# 1. Find the AppInfo ID for your app
asc app-infos list --app-id <APP_ID> --output table

# 2. Get the current declaration — note its "id" (the declaration ID)
asc age-rating get --app-info-id <APP_INFO_ID> --pretty

# 3. Update only the fields you want to change
asc age-rating update --declaration-id <DECLARATION_ID> \
  --violence-realistic NONE \
  --gambling false \
  --advertising false

# 4. Verify
asc age-rating get --app-info-id <APP_INFO_ID> --pretty
```

The response omits fields that have never been set:

```json
{
  "data": [
    {
      "id": "decl-xyz789",
      "appInfoId": "info-abc123",
      "isAdvertising": false,
      "violenceRealistic": "NONE",
      "ageRatingOverride": "NONE",
      "affordances": {
        "update": "asc age-rating update --declaration-id decl-xyz789",
        "getAgeRating": "asc age-rating get --app-info-id info-abc123"
      }
    }
  ]
}
```

### Kids category or a rating override
```bash
# Mark the app as a kids app (ages 9-11)
asc age-rating update --declaration-id decl-xyz789 --kids-age-band NINE_TO_ELEVEN

# Force an 18+ rating
asc age-rating update --declaration-id decl-xyz789 --age-rating-override EIGHTEEN_PLUS
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/app-infos/:appInfoId/age-rating` | `asc age-rating get --app-info-id` |
| GET | `/api/v1/age-rating/:appInfoId` | same (older flat path) |
| PATCH | `/api/v1/age-rating/:declarationId` | `asc age-rating update --declaration-id` |

The PATCH body uses the JSON field names from the response (e.g. `{"isGambling": false, "violenceRealistic": "NONE"}`), not the CLI flag names.

## Gotchas
- The declaration belongs to an `AppInfo`, not to the app or a version, so `get` takes `--app-info-id` while `update` takes the declaration's own `id`.
- `update` is a partial PATCH: only the flags you pass change.
- Intensity flags accept `NONE`, `INFREQUENT_OR_MILD`, `FREQUENT_OR_INTENSE`, `INFREQUENT`, `FREQUENT`; boolean flags take `true`/`false`.
- `--age-rating-override` values are `NONE`, `NINE_PLUS`, `THIRTEEN_PLUS`, `SIXTEEN_PLUS`, `EIGHTEEN_PLUS`, `UNRATED`; Korea has its own `--korea-age-rating-override` (`NONE`, `ALL`, `TWELVE_PLUS`, `FIFTEEN_PLUS`, `NINETEEN_PLUS`). Korea's GRAC classification number goes in `--grac-rating-classification-number` (REST body key `gracRatingClassificationNumber`).
- `--kids-age-band` values are `FIVE_AND_UNDER`, `SIX_TO_EIGHT`, `NINE_TO_ELEVEN`.
- `ageRatingOverride` maps to Apple's non-deprecated `ageRatingOverrideV2` field.

## See also
[app-info-localizations](../app-info-localizations/README.md)
