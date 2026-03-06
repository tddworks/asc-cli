# asc CLI Command Reference

## Global Flags

```
--output <json|table|markdown>   Output format (default: json)
--pretty                         Pretty-print JSON
--timeout <duration>             e.g. 30s, 2m
```

---

## init

### init — pin project context
```bash
asc init [--app-id <id>] [--name <name>] [--pretty]
```
Saves app ID, name, and bundle ID to `.asc/project.json` in the current directory. Priority: `--app-id` > `--name` > auto-detect from `.xcodeproj`.

Returns `ProjectConfig` with affordances for `listVersions`, `listBuilds`, `listAppInfos`, `checkReadiness`.

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

## version-review-detail

### get
```bash
asc version-review-detail get --version-id <id>
```
Fetch the App Store review contact info and demo account settings for a version.
Returns empty record (with `id: ""`) if review info has never been set.

### update
```bash
asc version-review-detail update --version-id <id> \
  [--contact-first-name <name>] \
  [--contact-last-name <name>] \
  [--contact-phone <phone>] \
  [--contact-email <email>] \
  [--demo-account-required <true|false>] \
  [--demo-account-name <username>] \
  [--demo-account-password <password>] \
  [--notes <text>]
```
Upsert review info: creates a new record if none exists (POST), or patches the existing one (PATCH).
Set contact info before submitting for review — `asc versions check-readiness` will warn if missing.

---

## version-localizations

### list
```bash
asc version-localizations list --version-id <id>
```

### create
```bash
asc version-localizations create --version-id <id> --locale en-US
asc version-localizations create --version-id <id> --locale zh-Hans
```

Common locales: `en-US`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, `de`, `fr`

### update
```bash
asc version-localizations update --localization-id <id> \
  [--whats-new <text>] \
  [--description <text>] \
  [--keywords <text>] \
  [--marketing-url <url>] \
  [--support-url <url>] \
  [--promotional-text <text>]
```

All fields are optional — only provided fields are sent to the API (PATCH semantics). Nil fields are omitted from JSON output.

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
Returns AppInfo records for an app (typically one per active state). Each AppInfo has affordances for `listLocalizations`, `getAgeRating`, and `updateCategories`.

### update (categories)
```bash
asc app-infos update --app-info-id <id> \
  [--primary-category GAMES] \
  [--primary-subcategory-one GAMES_ACTION] \
  [--primary-subcategory-two GAMES_ADVENTURE] \
  [--secondary-category UTILITIES] \
  [--secondary-subcategory-one <ID>] \
  [--secondary-subcategory-two <ID>]
```
Updates category relationships on an AppInfo. All flags are optional (PATCH semantics). Category IDs are strings like `GAMES`, `GAMES_ACTION`, `BUSINESS`, `UTILITIES` — use `asc app-categories list` to see all valid IDs.

---

## app-categories

### list
```bash
asc app-categories list [--platform IOS|MAC_OS|TV_OS]
```
Lists all available App Store categories and subcategories. Returns a flat list combining top-level categories (`data[]`) and subcategories (`included[]`). Subcategories have a non-nil `parentId`. Use returned IDs with `asc app-infos update`.

---

## app-info-localizations

### list
```bash
asc app-info-localizations list --app-info-id <id>
```

### create
```bash
asc app-info-localizations create \
  --app-info-id <id> \
  --locale en-US \
  --name "My App"
```
`--name` is required (up to 30 characters).

### update
```bash
asc app-info-localizations update --localization-id <id> \
  [--name "New Name"] \
  [--subtitle "New Subtitle"] \
  [--privacy-policy-url "https://example.com/privacy"] \
  [--privacy-choices-url "https://example.com/choices"] \
  [--privacy-policy-text "Our privacy policy"]
```
All flags optional — PATCH semantics.

### delete
```bash
asc app-info-localizations delete --localization-id <id>
```

---

## age-rating

### get
```bash
asc age-rating get --app-info-id <id>
```
Returns the full age rating declaration for an app info. Includes all content intensity ratings, boolean flags, kids age band, and regional overrides.

### update
```bash
asc age-rating update --declaration-id <id> \
  [--advertising <bool>] [--gambling <bool>] [--loot-box <bool>] \
  [--messaging-and-chat <bool>] [--parental-controls <bool>] \
  [--age-assurance <bool>] [--unrestricted-web-access <bool>] \
  [--user-generated-content <bool>] [--health-or-wellness <bool>] \
  [--violence-realistic <NONE|INFREQUENT_OR_MILD|FREQUENT_OR_INTENSE|INFREQUENT|FREQUENT>] \
  [--violence-cartoon <intensity>] [--violence-realistic-prolonged <intensity>] \
  [--profanity <intensity>] [--sexual-content <intensity>] \
  [--sexual-content-graphic <intensity>] [--horror-fear <intensity>] \
  [--mature-suggestive <intensity>] [--alcohol-tobacco-drugs <intensity>] \
  [--contests <intensity>] [--gambling-simulated <intensity>] [--guns-weapons <intensity>] \
  [--medical-treatment <intensity>] \
  [--kids-age-band <FIVE_AND_UNDER|SIX_TO_EIGHT|NINE_TO_ELEVEN>] \
  [--age-rating-override <NONE|NINE_PLUS|THIRTEEN_PLUS|SIXTEEN_PLUS|EIGHTEEN_PLUS|UNRATED>] \
  [--korea-age-rating-override <NONE|FIFTEEN_PLUS|NINETEEN_PLUS>]
```
All flags are optional — only provided fields are changed (PATCH semantics).

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
asc app-info-localizations update --localization-id <id> \
  [--name <n>] \
  [--subtitle <s>] \
  [--privacy-policy-url <url>] \
  [--privacy-choices-url <url>] \
  [--privacy-policy-text <text>]
```
All fields are optional — only provided fields are changed.

---

## iap

### list
```bash
asc iap list --app-id <id> [--limit N] [--pretty]
```

### create
```bash
asc iap create \
  --app-id <id> \
  --reference-name "Gold Coins" \
  --product-id "com.app.goldcoins" \
  --type consumable
```
**`--type`** values: `consumable`, `non-consumable`, `non-renewing-subscription`

### submit
```bash
asc iap submit --iap-id <id>
```
Submits the IAP for App Store review. Requires state `READY_TO_SUBMIT`.

### price-points list
```bash
asc iap price-points list --iap-id <id> [--territory USA]
```
Lists available price tiers. Each result has a `setPrice` affordance with the ready-to-run `asc iap prices set` command.

### prices set
```bash
asc iap prices set \
  --iap-id <id> \
  --base-territory USA \
  --price-point-id <id>
```
Sets a price schedule. The base territory price is used; Apple auto-calculates all other territories.

---

## iap-localizations

### list
```bash
asc iap-localizations list --iap-id <id>
```

### create
```bash
asc iap-localizations create \
  --iap-id <id> \
  --locale en-US \
  --name "Gold Coins" \
  [--description "In-game currency"]
```

---

## subscription-groups

### list
```bash
asc subscription-groups list --app-id <id> [--limit N]
```

### create
```bash
asc subscription-groups create \
  --app-id <id> \
  --reference-name "Premium Plans"
```

---

## subscriptions

### list
```bash
asc subscriptions list --group-id <id> [--limit N]
```

### create
```bash
asc subscriptions create \
  --group-id <id> \
  --name "Monthly Premium" \
  --product-id "com.app.monthly" \
  --period ONE_MONTH \
  [--family-sharable] \
  [--group-level 1]
```
**`--period`** values: `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`

---

## subscription-localizations

### list
```bash
asc subscription-localizations list --subscription-id <id>
```

### create
```bash
asc subscription-localizations create \
  --subscription-id <id> \
  --locale en-US \
  --name "Monthly Premium" \
  [--description "Full access, billed monthly"]
```

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

## app-shots

### generate
```bash
asc app-shots generate \
  --plan app-shots-plan.json \
  --gemini-api-key $GEMINI_API_KEY \
  [--model gemini-3.1-flash-image-preview] \
  [--output-dir app-shots-output] \
  [screen1.png screen2.png ...]
```
Calls Gemini image generation API (OpenAI-compatible endpoint) to generate actual PNG background images for each screen in the plan. Each screen's `imagePrompt` + its matched screenshot are sent to Gemini; the returned PNG is saved to `--output-dir`. Does **not** require ASC credentials.

- `--plan` — path to plan JSON written by the `asc-app-shots` skill
- `--gemini-api-key` — falls back to `GEMINI_API_KEY` env var
- `--model` — Gemini image generation model (default: `gemini-3.1-flash-image-preview`)
- `--output-dir` — directory to write generated PNG files (default: `app-shots-output`; created if needed)
- positional args — screenshot files matched to screens by filename or index order

Output: JSON list of generated file paths. Generated images saved as `{output-dir}/screen-{index}.png`.

**Typical two-step workflow:**
```bash
# Step 1 (Claude Code skill): analyze screenshots → write plan with imagePrompts
# invoke asc-app-shots skill in Claude Code

# Step 2 (CLI): generate images with Gemini
asc app-shots generate \
  --plan app-shots-plan.json \
  --gemini-api-key $GEMINI_API_KEY \
  --output-dir app-shots-output \
  screen1.png screen2.png screen3.png
# → saves app-shots-output/screen-0.png, screen-1.png, screen-2.png
```

---

## auth

### login
```bash
asc auth login \
  --key-id <KEY_ID> \
  --issuer-id <ISSUER_ID> \
  --private-key-path ~/.asc/AuthKey_KEYID.p8 \
  [--name <alias>]
```
Saves credentials under a named account (defaults to key ID). The saved account becomes active. Accepts `--private-key` (raw PEM) instead of `--private-key-path`.

Output: JSON `AuthStatus` with `name`, `source: "file"` and affordances.

### list
```bash
asc auth list [--pretty] [--output table]
```
Lists all saved `ConnectAccount` entries. Active account has `"isActive": true`. Each inactive account carries a `"use"` affordance.

### use
```bash
asc auth use <name>
```
Switches the active account. All subsequent API commands use this account. Throws `accountNotFound` if the name doesn't exist.

### logout
```bash
asc auth logout [--name <alias>]
```
Removes the named account (or the active account if `--name` is omitted). Prints "Logged out successfully".

### check
```bash
asc auth check [--pretty] [--output table]
```
Shows active credentials with `name` (omitted for environment credentials) and `source` (`"file"` or `"environment"`).

**Credential resolution order:** active account in `~/.asc/credentials.json` → environment variables (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_PATH` / `ASC_PRIVATE_KEY_B64` / `ASC_PRIVATE_KEY`).

Output fields: `keyID`, `issuerID`, `source`, `affordances`.

---

## users

Manage App Store Connect team members.

```bash
asc users list [--role <ROLE>] [--pretty] [--output table]
asc users update --user-id <id> --role <ROLE> [--role <ROLE> ...]
asc users remove --user-id <id>
```

**Roles (uppercase):** `ADMIN`, `FINANCE`, `ACCOUNT_HOLDER`, `SALES`, `MARKETING`, `APP_MANAGER`, `DEVELOPER`, `ACCESS_TO_REPORTS`, `CUSTOMER_SUPPORT`, `CREATE_APPS`, `CLOUD_MANAGED_DEVELOPER_ID`, `CLOUD_MANAGED_APP_DISTRIBUTION`, `GENERATE_INDIVIDUAL_KEYS`

`TeamMember` affordances: `remove`, `updateRoles` (pre-filled with current roles).

---

## user-invitations

Manage pending team invitations.

```bash
asc user-invitations list [--role <ROLE>] [--pretty] [--output table]
asc user-invitations invite --email <email> --first-name <name> --last-name <name> --role <ROLE> [--role <ROLE> ...] [--all-apps-visible]
asc user-invitations cancel --invitation-id <id>
```

`UserInvitationRecord` affordance: `cancel`.