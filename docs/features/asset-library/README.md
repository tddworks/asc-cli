---
description: Upload screenshots, previews and marketing images once into an app's asset library, then place and order them on version and treatment localizations. Use when adding store media with App Store Connect API 4.5.1+.
---

# App Asset Library

Apple's replacement for screenshot sets and preview sets: each app has one library, you upload an image or video into it once, and a **placement** puts it into one slot (a placement type such as `APP_SCREENSHOT` plus a placement group such as `IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE`) on one localization. One asset can back many placements. Every flag: [command reference](../../commands.md#asc-asset-library).

## Quick start

```bash
asc asset-library get --app-id 1234567890 --pretty                      # → library id
asc asset-placement-groups list --placement-type APP_SCREENSHOT --feature APP_STORE_VERSIONS --pretty
asc asset-images upload --library-id lib-1 --file home-6-9.png --reference-name "Home" --wait
asc asset-placements create --localization-id loc-1 --image-id img-1 \
  --placement-type APP_SCREENSHOT --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE
```

## Workflows

### Find the slot you need

Placement groups, their accepted sizes and their limits come from App Store Connect's reference data, one row per placement type, group and feature:

```bash
asc asset-placement-groups list --placement-type APP_SCREENSHOT --feature APP_STORE_VERSIONS
```

```json
{
  "id": "IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE",
  "placementType": "APP_SCREENSHOT",
  "platform": "IPHONE_APP_STORE",
  "displayClass": "IPHONE_DYNAMIC_ISLAND_LARGE_DISPLAY",
  "feature": "APP_STORE_VERSIONS",
  "sizes": ["1290x2796", "2796x1290"],
  "maxCount": 10,
  "affordances": {
    "place": "asc asset-placements create --image-id <image-id> --localization-id <localization-id> --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE --placement-type APP_SCREENSHOT"
  }
}
```

Resize your file to one of `sizes` before uploading; App Store Connect matches it to a spec during processing and reports it as `specId`.

### Upload → wait → place → reorder

```bash
# 1. Upload (reserve, send the parts, commit). --wait polls until processing finishes.
asc asset-images upload --library-id lib-1 --file home-6-9.png --wait
asc asset-images upload --library-id lib-1 --file search-6-9.png --wait

# Without --wait, follow the image's `refresh` affordance until `state` is PREPARE_FOR_SUBMISSION:
asc asset-images list --library-id lib-1 --image-id img-1

# 2. Place each image (the image's `place` affordance pre-fills most of this)
asc asset-placements create --localization-id loc-1 --image-id img-1 \
  --placement-type APP_SCREENSHOT --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE
asc asset-placements create --localization-id loc-1 --image-id img-2 \
  --placement-type APP_SCREENSHOT --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE

# 3. See the display order (position is 1-based within each type + group)
asc asset-placements list --localization-id loc-1 --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE

# 4. Reorder one group; prints the group in its new order
asc asset-placements reorder --localization-id loc-1 \
  --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE --placement-ids pl-2,pl-1
```

App previews work the same way with `asc asset-videos upload` (add `--preview-frame-time-code 00:00:03:00` to choose the poster frame), `--video-id` and `--placement-type APP_PREVIEW`.

### Product page optimization treatments

Use `--treatment-localization-id` instead of `--localization-id` to list, place and reorder on a treatment localization from `asc experiment-treatment-localizations list`:

```bash
asc asset-placements create --treatment-localization-id tl-1 --image-id img-1 \
  --placement-type APP_SCREENSHOT --placement-group IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE
```

### Where is an asset used?

```bash
asc asset-placements list --image-id img-1      # or --video-id vid-1
```

Each placement names its `surface` (`APP_STORE_VERSION_LOCALIZATION`, `EXPERIMENT_TREATMENT_LOCALIZATION`, `CUSTOM_PRODUCT_PAGE_LOCALIZATION`, `EVENT_LOCALIZATION`) and `localizationId`.

### Rename, archive, delete

```bash
asc asset-images update --library-id lib-1 --image-id img-1 --reference-name "Home (Fall)"
asc asset-images update --library-id lib-1 --image-id img-1 --archived true    # approved assets only
asc asset-placements delete --placement-id pl-1                                # placements first…
asc asset-images delete --image-id img-1                                       # …then the asset
```

### Migrating from screenshot sets

| Before | Now |
|---|---|
| `asc screenshot-sets create --display-type APP_IPHONE_67` | nothing to create — pick a placement group from `asset-placement-groups list` |
| `asc screenshots upload --set-id …` per localization | `asc asset-images upload` once, then `asset-placements create` per localization |
| `asc app-previews upload --set-id …` | `asc asset-videos upload` + `asset-placements create --video-id … --placement-type APP_PREVIEW` |
| set order on upload | `asc asset-placements reorder` per group |

Migrate against a version in `PREPARE_FOR_SUBMISSION`, then verify with `asset-placements list --localization-id`. An interrupted migration leaves unplaced assets in the library; resume by creating the missing placements instead of re-uploading.

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/asset-library` | `asset-library get` |
| GET | `/api/v1/asset-placement-groups?placement-type=&feature=` | `asset-placement-groups list` |
| GET / POST | `/api/v1/asset-library/:libraryId/images?state=&category=&image-id=` | `asset-images list` / `upload` (POST body = file bytes; `?category=&reference-name=`) |
| GET / POST | `/api/v1/asset-library/:libraryId/videos?state=&category=&video-id=` | `asset-videos list` / `upload` (adds `?preview-frame-time-code=`) |
| PATCH / DELETE | `/api/v1/asset-images/:imageId`, `/api/v1/asset-videos/:videoId` | `update` (body `{"libraryId","referenceName","archived"}`) / `delete` |
| GET | `/api/v1/asset-images/:imageId/placements`, `/api/v1/asset-videos/:videoId/placements` | `asset-placements list --image-id` / `--video-id` |
| GET / POST | `/api/v1/version-localizations/:id/placements?placement-type=&placement-group=` | `asset-placements list` / `create` (body `{"imageId"\|"videoId","placementType","placementGroup"}`) |
| POST | `/api/v1/version-localizations/:id/placements/reorder` | `asset-placements reorder` (body `{"placementGroup","placementIds":[…]}`) |
| GET / POST | `/api/v1/experiment-treatment-localizations/:id/placements` (+ `/reorder`) | same, with `--treatment-localization-id` |
| DELETE | `/api/v1/asset-placements/:placementId` | `asset-placements delete` |

`upload --wait` has no REST equivalent; poll the list route with `?image-id=`.

## Gotchas

- Delete placements before the asset: deleting an asset that is still placed fails with `STATE_ERROR.ASSET_HAS_PLACEMENTS`.
- `--category` is fixed at upload. `APP_SCREENSHOT`/`APP_PREVIEW` accept `APP_SCREENSHOTS_AND_PREVIEWS`; creative slots (event cards, product page headers) accept `CREATIVE_ASSETS`.
- Group limits (`maxCount`) differ per feature — read them from `asset-placement-groups list --feature …` rather than assuming 10.
- Placements can only be created while the parent version (or treatment) is editable. The `place` affordance can't know that; App Store Connect answers `STATE_ERROR.INVALID_STATE`.
- A placement is fixed once created: to swap the asset, delete it, create a new one and reorder.
- `IPHONE_DUO` placement groups exist only in the asset library — there is no screenshot set display type for them.
- Images, videos, placements or groups in a state or type asc doesn't know yet are left out of lists rather than failing them; update asc to see them.
- `update` needs `--library-id` because App Store Connect's response doesn't say which library an asset belongs to.
- Custom product page and in-app event placements show up in `list --image-id`, but asc has no flags to place on those surfaces yet.

## See also

[screenshots (deprecated sets)](../screenshots/README.md) · [app-previews (deprecated sets)](../app-previews/README.md) · [version-localizations](../version-localizations/README.md) · [product-page-optimization](../product-page-optimization/README.md)
