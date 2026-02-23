# asc CLI Command Reference

## Global Flags

```
--output <json|table|markdown>   Output format (default: json)
--pretty                         Pretty-print JSON
--timeout <duration>             e.g. 30s, 2m
```

---

## apps

### list
```bash
asc apps list
```
Returns all apps. Each app has affordances for `listVersions`.

---

## versions

### list
```bash
asc versions list --app-id <id>
```
Returns versions per platform. Key fields:
- `state`: e.g. `PREPARE_FOR_SUBMISSION`, `READY_FOR_SALE`, `IN_REVIEW`
- `platform`: `IOS`, `MAC_OS`, `TV_OS`
- `affordances.submitForReview` — present only when state is editable

### create
```bash
asc versions create --app-id <id> --version <1.2.0> --platform IOS
```

### submit
```bash
asc versions submit --version-id <id>
```
Orchestrates 4 API calls: fetch version → create submission → add item → set submitted.
Requires version to be in `PREPARE_FOR_SUBMISSION` with all required content present.

---

## localizations

### list
```bash
asc localizations list --version-id <id>
```

### create
```bash
asc localizations create --version-id <id> --locale en-US
asc localizations create --version-id <id> --locale zh-Hans
```

Common locales: `en-US`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, `de`, `fr`

---

## screenshot-sets

### list
```bash
asc screenshot-sets list --localization-id <id>
```
Returns sets grouped by display type (`APP_IPHONE_67`, `APP_IPAD_PRO_3GEN_129`, etc.)

### create
```bash
asc screenshot-sets create --localization-id <id> --display-type APP_IPHONE_67
```

Common display types:
- `APP_IPHONE_67` — iPhone 6.7"
- `APP_IPHONE_65` — iPhone 6.5"
- `APP_IPHONE_61` — iPhone 6.1"
- `APP_IPHONE_55` — iPhone 5.5"
- `APP_IPAD_PRO_3GEN_129` — iPad Pro 12.9" (3rd gen+)
- `APP_IPAD_PRO_129` — iPad Pro 12.9" (1st/2nd gen)

---

## screenshots

### list
```bash
asc screenshots list --set-id <id>
```

### upload
```bash
asc screenshots upload --set-id <id> --file ./path/to/screenshot.png
```
Supports PNG and JPEG. File must match display type dimensions.

### import
```bash
asc screenshots import --version-id <id> --from <path/to/export.zip>
```
Reads an `export.zip` produced by the browser-based screenshot editor. For each locale in `manifest.json`, finds or creates the localization and screenshot set, then uploads each PNG in `order` sequence.

Options: `--output`, `--pretty`

---

## app-infos

### list
```bash
asc app-infos list --app-id <id>
```
Returns AppInfo records for an app (typically one per active state). Each AppInfo has an affordance for `listLocalizations`.

---

## app-info-localizations

### list
```bash
asc app-info-localizations list --app-info-id <id>
```
Returns per-locale metadata (name, subtitle, privacy URLs) for a given AppInfo.

### create
```bash
asc app-info-localizations create --app-info-id <id> --locale en-US --name "My App"
```
Creates a new locale entry. `--name` is required (up to 30 characters).

### update
```bash
asc app-info-localizations update --localization-id <id> [--name <n>] [--subtitle <s>] [--privacy-policy-url <url>]
```
All fields are optional — only provided fields are changed.

---

## builds

### list
```bash
asc builds list                        # all builds
asc builds list --app-id <id>          # filtered by app
asc builds list --app-id <id> --limit 5
```
Key fields: `version`, `uploadedDate`, `processingState` (`PROCESSING`, `VALID`, `INVALID`)

---

## testflight

### groups list
```bash
asc testflight groups list --app-id <id>
```

### testers list
```bash
asc testflight testers list --app-id <id>
```

---

## auth

```bash
asc auth    # verify credentials are configured correctly
```