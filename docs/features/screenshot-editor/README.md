---
description: Design App Store screenshots (background, device bezel, text) in a browser editor, export a ZIP, and import it into a version's asset library in one command. Use when composing screenshots visually and importing them.
---

# Screenshot Editor

A browser-based screenshot compositor. Design screenshots (background + device bezel + text layers) in a visual editor, export a ZIP, then upload it to App Store Connect with `asc screenshots import`. Every flag: [command reference](../../commands.md#asc-screenshots).

## Quick start

```bash
open homepage/editor/index.html          # design, then click Export ZIP
asc screenshots import --version-id <VERSION_ID> --from ./screenshots.zip --to-library --dry-run
asc screenshots import --version-id <VERSION_ID> --from ./screenshots.zip --to-library
```

## Workflows

### Design and upload screenshots

```bash
# 1. Find your app and version
asc apps list --output table
asc versions list --app-id <APP_ID> --output table

# 2. Design screenshots in the visual editor (no server required)
open homepage/editor/index.html
#    → compose screenshots for en-US, ja, zh-Hans
#    → click Export ZIP → saves screenshots.zip

# 3. Preview, then import into the asset library
asc screenshots import --version-id <VERSION_ID> --from ./screenshots.zip --to-library --dry-run
asc screenshots import --version-id <VERSION_ID> --from ./screenshots.zip --to-library

# 4. Verify
asc asset-placements list --localization-id <LOC_ID> --output table
```

### Import into the asset library (`--to-library`)

Each screenshot's exact pixel size picks its placement group among the `APP_SCREENSHOT` groups for `APP_STORE_VERSIONS` (`asc asset-placement-groups list`). Then import adds locales the version is missing, uploads each distinct file once, waits for processing, places the screenshots per locale and orders each group in manifest order. It prints one result per locale and group, and exits non-zero unless every group is `placed` (`planned` on `--dry-run`, which changes nothing).

```json
{"data":[{"affordances":{"listPlacements":"asc asset-placements list --localization-id loc-1"},"locale":"en-US","localizationId":"loc-1","placementGroup":"IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE","placements":[{"file":"en-US/1.png","imageId":"img-1","placementId":"pl-1","position":1}],"status":"placed"}]}
```

| `status` | Meaning / next step |
|---|---|
| `planned` / `placed` | dry run / done |
| `conflict` | the localization already has screenshots in the group (`existingPlacementIds`); rerun with `--existing replace` (the `replace` affordance) or `--existing append` |
| `ambiguous` | the size fits several groups (`candidates`); rerun with `--placement-group <one of them>` |
| `noMatchingGroup` | no screenshot group accepts the size; see the `listPlacementGroups` affordance |
| `overLimit` | more screenshots than the group's `maxCount` (existing ones count with `append`) |
| `failed` | `message` says why (processing failed, still processing, App Store Connect refused); other groups carry on |

Not yet supported: app previews, product page optimization treatments, iMessage screenshots, skipping files already in the library from an earlier run, and making `--to-library` the default.

### Into screenshot sets (deprecated)

Without `--to-library`, import uses screenshot sets, which App Store Connect API 4.5.1 deprecates (a note says so on stderr). For each locale in the manifest it finds or creates the localization and the set for `displayType`, then uploads each PNG in `order` sequence; check with `asc screenshot-sets list --localization-id <LOC_ID>`.

### Using the editor

The editor has three panels: localizations and screenshot slots on the left, the canvas in the middle, the inspector (canvas size, device frame, screenshot image, background, text layers, Export ZIP) on the right.

- **Locale tabs**: each localization has independent screenshots and device settings.
- **Screenshot slots**: up to 10 per locale.
- **Canvas drag**: moves the bezel and screenshot together.
- **Text layers**: drag to reposition; edit content, size, color, weight and alignment in the inspector.
- **Zoom slider**: visual only; export always uses full output resolution.

### Export ZIP format

```
screenshots.zip
├── manifest.json
├── en-US/
│   ├── 1.png
│   └── 2.png
└── ja/
    └── 1.png
```

```json
{
  "version": "1.0",
  "exportedAt": "2026-02-23T10:00:00Z",
  "localizations": {
    "en-US": {
      "displayType": "APP_IPHONE_67",
      "screenshots": [
        {
          "order": 1,
          "file": "en-US/1.png",
          "device": "iPhone 16 Pro - Natural Titanium - Portrait",
          "background": { "type": "gradient", "colors": ["#1a1a2e", "#0f3460"], "angle": 135 },
          "texts": [
            { "content": "Track Everything", "x": 50, "y": 15, "fontSize": 52,
              "fontWeight": "bold", "color": "#ffffff", "align": "center" }
          ]
        }
      ]
    }
  }
}
```

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| POST | `/api/v1/versions/:versionId/screenshots/import?to-library=true&existing=&dry-run=true&placement-group=` | `screenshots import --to-library` (body = the ZIP bytes; `placement-group` repeatable) |

Only `to-library=true` is served. The response has the same `data` array, with `_links` instead of `affordances`; it returns when every group is done.

## Gotchas

- `asc screenshots import` reads only `displayType` (screenshot sets only), `file` and `order`; `device`, `background` and `texts` are editor metadata kept for re-editing.
- `file` paths are relative to the ZIP root.
- Version must be editable (e.g. `PREPARE_FOR_SUBMISSION`); import refuses before uploading anything otherwise.
- Identical files are uploaded once per run only; importing the same ZIP again uploads them again.
- `--existing replace` deletes the group's editable screenshots first, then places the new ones; if a later step fails, the group is left without them.
- 2048x2732 / 2732x2048 fit both `IPAD_129_PROFILE` and `IPAD_13_PROFILE`, and 3840x2160 fits `TV_PROFILE` and `VISION_PRO_PROFILE`: pass `--placement-group` (repeatable) to choose.
- Processing is polled every 2 s for up to 3 minutes; a screenshot still processing after that fails its groups — place it later with `asc asset-placements create`.

## See also

[Design notes](design.md) (editor internals, device frames, JS modules) · [asset-library](../asset-library/README.md) · [screenshots](../screenshots/README.md) · [app-shots](../app-shots/README.md)
