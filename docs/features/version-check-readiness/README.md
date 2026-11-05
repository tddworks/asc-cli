---
description: Pre-flight check that reports whether an App Store version meets Apple's submission requirements. Use when gating a submit in CI or finding out what blocks a version from review.
---

# Version Check-Readiness

One command that aggregates Apple's known submission requirements into a readiness report, so CI can gate a submit instead of trying a blind one. Every flag: [command reference](../../commands.md#asc-versions).

## Quick start
```bash
asc versions list --app-id <APP_ID> --output table        # find the PREPARE_FOR_SUBMISSION version
asc versions check-readiness --version-id <VERSION_ID> --pretty
asc versions submit --version-id <VERSION_ID>              # only once isReadyToSubmit is true
```

## Workflows

### Fix whatever the report flags
```bash
asc versions check-readiness --version-id <VERSION_ID> --pretty

# buildCheck.linked == false → link a build
asc versions set-build --version-id <VERSION_ID> --build-id <BUILD_ID>

# pricingCheck.pass == false → give the app a price schedule (see app-pricing)
asc apps prices set --app-id <APP_ID> --base-territory <TERRITORY> --price-point-id <PRICE_POINT_ID>

# localizationCheck.pass == false → add description and screenshots to the primary locale
asc version-localizations list --version-id <VERSION_ID>

# re-run until ready, then submit
asc versions check-readiness --version-id <VERSION_ID> --pretty
asc versions submit --version-id <VERSION_ID>
```

A ready report (trimmed):

```json
{
  "id": "ver-1",
  "appId": "1234567890",
  "versionString": "2.1.0",
  "state": "PREPARE_FOR_SUBMISSION",
  "isReadyToSubmit": true,
  "stateCheck": { "pass": true },
  "ageRatingCheck": { "pass": true },
  "buildCheck": { "linked": true, "valid": true, "notExpired": true, "buildVersion": "2.1.0 (102)", "pass": true },
  "pricingCheck": { "pass": true },
  "localizationCheck": {
    "pass": true,
    "localizations": [
      { "locale": "en-US", "isPrimary": true, "hasDescription": true, "hasKeywords": true,
        "hasSupportUrl": true, "hasWhatsNew": true, "screenshotSetCount": 3, "pass": true }
    ]
  },
  "reviewContactCheck": { "pass": true },
  "affordances": {
    "checkReadiness": "asc versions check-readiness --version-id ver-1",
    "listLocalizations": "asc version-localizations list --version-id ver-1",
    "submit": "asc versions submit --version-id ver-1"
  }
}
```

When no build is linked, `buildCheck` is `{ "linked": false, "valid": false, "notExpired": false, "pass": false }`, `isReadyToSubmit` is `false` and the `submit` affordance is absent.

### CI gate
```bash
#!/bin/bash
set -e

RESULT=$(asc versions check-readiness --version-id "$VERSION_ID")
IS_READY=$(echo "$RESULT" | jq -r '.data[0].isReadyToSubmit')

if [ "$IS_READY" = "true" ]; then
  echo "Version is ready. Submitting..."
  asc versions submit --version-id "$VERSION_ID"
else
  echo "Version is NOT ready. Issues:"
  echo "$RESULT" | jq '.data[0] | {stateCheck, buildCheck, pricingCheck, localizationCheck, ageRatingCheck}'
  exit 1
fi
```

An agent can instead run the `submit` affordance straight from the response: `eval "$(echo "$RESULT" | jq -r '.data[0].affordances.submit')"`.

## Check severity

| Check | Field | Severity | Blocks submission? |
|-------|-------|----------|--------------------|
| Version state is editable | `stateCheck` | MUST FIX | Yes |
| Build linked, valid, not expired | `buildCheck` | MUST FIX | Yes |
| App price schedule configured | `pricingCheck` | MUST FIX | Yes |
| Primary locale has description + screenshots | `localizationCheck` | MUST FIX | Yes |
| Every age rating question is answered | `ageRatingCheck` | MUST FIX | Yes |
| Review contact info (email + phone) | `reviewContactCheck` | SHOULD FIX | No |
| Secondary locale description + screenshots | `localizationCheck.localizations[isPrimary=false].pass` | SHOULD FIX | No (Apple rejects post-submit) |

`isReadyToSubmit = stateCheck.pass && buildCheck.pass && pricingCheck.pass && localizationCheck.pass && ageRatingCheck.pass`

## REST
No REST route today; `check-readiness` is CLI-only.

## Gotchas
- `affordances.submit` only appears when `isReadyToSubmit` is `true`; `checkReadiness` and `listLocalizations` are always present. Every `AppStoreVersion` also carries a `checkReadiness` affordance.
- `reviewContactCheck` failing does not block submission; it is a warning.
- `localizationCheck.pass` depends only on the app's primary locale (`primaryLocale`, or the first localization returned when that is unset): it needs a description and at least one screenshot set that contains screenshots. A secondary locale with no screenshots shows `pass: false` but the version is still ready.
- `localizationCheck.pass` is `false` when the version has no localizations at all.
- `pricingCheck` is `false` whenever the app's price schedule can't be read, not only when it is missing.
- `ageRatingCheck` names unanswered questions by the attribute name Apple uses in its refusals (`socialMedia`), read from the app info going to review. `socialMediaAgeRestricted` only counts when `socialMedia` is `true`. Answer them with `asc age-rating update`.
- A passing check doesn't guarantee Apple accepts the version: it can add required answers at any time. `asc versions submit` prints each reason Apple gives for a refusal, and retrying after a refusal reuses the same draft.

## See also
[app-pricing](../app-pricing/README.md) · [version-review-detail](../version-review-detail/README.md) · [review-submissions](../review-submissions/README.md) · [submit-with-products](../submit-with-products/README.md)
