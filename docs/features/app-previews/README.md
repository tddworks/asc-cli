---
description: Create App Store video preview sets per device type and upload preview videos. Use when adding or checking app preview videos on a version's product page.
---

# App Previews

Short video clips on the App Store product page, grouped into preview sets (one per device type) under a version localization. Every flag: [app-preview-sets](../../commands.md#asc-app-preview-sets) · [app-previews](../../commands.md#asc-app-previews).

## Quick start
```bash
asc app-preview-sets list --localization-id <LOC_ID> --pretty
asc app-preview-sets create --localization-id <LOC_ID> --preview-type IPHONE_67
asc app-previews upload --set-id <SET_ID> --file ./preview.mp4 --preview-frame-time-code 00:00:05
```

## Workflows

### Upload a preview and wait for encoding
```bash
# 1. Pick a version localization
LOCALE_ID=$(asc version-localizations list --version-id <version-id> | jq -r '.data[0].id')

# 2. Create a preview set for iPhone 6.7"
SET_ID=$(asc app-preview-sets create \
  --localization-id "$LOCALE_ID" \
  --preview-type IPHONE_67 \
  | jq -r '.data[0].id')

# 3. Upload the video
asc app-previews upload \
  --set-id "$SET_ID" \
  --file ./previews/iphone-preview.mp4 \
  --preview-frame-time-code 00:00:03 \
  --pretty

# 4. Check delivery state
asc app-previews list --set-id "$SET_ID" --pretty
```

A finished preview looks like this (null fields are omitted):

```json
{
  "data": [
    {
      "id": "prev-1",
      "setId": "set-1",
      "fileName": "preview.mp4",
      "fileSize": 10485760,
      "mimeType": "video/mp4",
      "assetDeliveryState": "COMPLETE",
      "videoDeliveryState": "COMPLETE",
      "affordances": {
        "listPreviews": "asc app-previews list --set-id set-1"
      }
    }
  ]
}
```

## Gotchas
- Apple deprecated preview sets and previews in API 4.5.1. They keep working, but new work belongs in the [asset library](../asset-library/README.md) (`asc asset-videos`).
- A preview has two states. `assetDeliveryState` tracks the upload (`AWAITING_UPLOAD`, `UPLOAD_COMPLETE`, `COMPLETE`, `FAILED`). `videoDeliveryState` tracks Apple's encoding and adds `PROCESSING`. The preview is ready only when `videoDeliveryState` is `COMPLETE`, and `videoURL` appears only after encoding.
- `upload` accepts `.mp4`, `.mov` and `.m4v`. It reserves a slot, uploads the chunks, then confirms with an MD5 checksum.
- `--preview-type` values have no `APP_` prefix, unlike screenshot display types: `IPHONE_67`, `IPHONE_61`, `IPHONE_65`, `IPHONE_58`, `IPHONE_55`, `IPHONE_47`, `IPHONE_40`, `IPHONE_35`, `IPAD_PRO_3GEN_129`, `IPAD_PRO_3GEN_11`, `IPAD_PRO_129`, `IPAD_105`, `IPAD_97`, `DESKTOP`, `APPLE_TV`, `APPLE_VISION_PRO`.
- There are no delete commands for previews or preview sets.
- Not exposed over REST.

## See also
[version-localizations](../version-localizations/README.md) · [screenshots](../screenshots/README.md)
