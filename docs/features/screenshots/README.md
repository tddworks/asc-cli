---
description: List and create screenshot sets and upload screenshots for an App Store version localization. Use when adding or checking App Store screenshots for a version.
---

# Screenshots

Screenshot sets (one per display type, e.g. iPhone 6.7") and the screenshots inside them, for one App Store version localization.
Every flag: [screenshot-sets](../../commands.md#asc-screenshot-sets) · [screenshots](../../commands.md#asc-screenshots).

## Quick start

```bash
asc screenshot-sets list --localization-id <LOCALIZATION_ID> --output table
asc screenshot-sets create --localization-id <LOCALIZATION_ID> --display-type APP_IPHONE_67
asc screenshots upload --set-id <SET_ID> --file ./screens/iphone_hero.png
```

## Workflows

### Upload screenshots for a new version

```bash
# 1. Find your app
asc apps list --output table

# 2. Find the version
asc versions list --app-id <APP_ID> --output table

# 3. List localizations for the version
asc version-localizations list --version-id <VERSION_ID> --output table

# 4. List screenshot sets for a localization
asc screenshot-sets list --localization-id <LOCALIZATION_ID> --output table

# 5. Create a set if needed
asc screenshot-sets create --localization-id <LOCALIZATION_ID> --display-type APP_IPHONE_67

# 6. Upload screenshots
asc screenshots upload --set-id <SET_ID> --file ./screens/screen01.png

# 7. Verify upload
asc screenshots list --set-id <SET_ID> --output table
```

Each response includes `affordances` with the follow-up commands (e.g. a set carries `listScreenshots` and `listScreenshotSets`), so an agent can walk the hierarchy without knowing the command tree.

Screenshot sets as a table:

```
ID                    Display Type              Device   Count
--------------------  ------------------------  -------  -----
set-aaa               iPhone 6.7"               iPhone   5
set-bbb               iPad Pro 12.9" (3rd gen)  iPad     3
set-ccc               Mac                       mac      0
```

Screenshots as a table, showing delivery state:

```
ID        File Name         Size     Dimensions    State
--------  ----------------  -------  ------------  ---------------
img-001   screen_01.png     2.8 MB   2796 × 1290   Complete
img-002   screen_02.png     2.4 MB   2796 × 1290   Complete
img-003   pending.png       0 B      -             Awaiting Upload
```

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/version-localizations/:localizationId/screenshot-sets` | `asc screenshot-sets list --localization-id` |
| GET | `/api/v1/screenshot-sets/:setId/screenshots` | `asc screenshots list --set-id` |

Creating sets and uploading are CLI-only.

## Gotchas

- Apple deprecated screenshot sets and screenshots in API 4.5.1. They keep working, but new work belongs in the [asset library](../asset-library/README.md): upload once, place on many localizations.
- `--display-type` takes the App Store Connect raw value (e.g. `APP_IPHONE_67`, `APP_IPAD_PRO_3GEN_129`, `APP_DESKTOP`, `APP_APPLE_VISION_PRO`), not the human-readable name shown in tables.
- `screenshots upload` runs Apple's three-step flow for you: reserve, upload the binary, then commit. A screenshot is only ready for submission when its state is `COMPLETE`; other states are `AWAITING_UPLOAD`, `UPLOAD_COMPLETE` and `FAILED`.
- A set's `screenshotsCount` is 0 when it is empty; the set still exists.
- There are no delete or reorder commands for screenshots or sets.

## See also

[version-localizations](../version-localizations/README.md) · [app-shots](../app-shots/README.md) · [app-previews](../app-previews/README.md)
