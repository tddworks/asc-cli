# asc Commands for Screenshot Planning

## List apps (get App ID)

```bash
asc apps list [--pretty]
# Returns: id, name, bundleId
```

## Get version ID

```bash
asc versions list --app-id <APP_ID> [--pretty]
# Returns: id, versionString, platform, state
# Filter for prepareForSubmission or readyForSale state
```

## Get app info localizations (name, subtitle)

```bash
# Step 1: Get the app info ID
asc app-infos list --app-id <APP_ID>
# Returns: id, appId

# Step 2: Get localizations for that app info
asc app-info-localizations list --app-info-id <APP_INFO_ID> [--locale en-US]
# Returns: id, locale, name, subtitle, privacyPolicyUrl
```

## Get version localizations (description, keywords, whatsNew)

```bash
asc version-localizations list --version-id <VERSION_ID> [--pretty]
# Returns: id, locale, whatsNew, description, keywords, marketingUrl
```

## Filter by locale with jq

```bash
# Get name for en-US locale
asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .name'

# Get description for en-US locale
asc version-localizations list --version-id "$VERSION_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .description'
```

## Full metadata fetch script

```bash
APP_ID="6736834466"
VERSION_ID="abc123def"
LOCALE="en-US"

# App info
APP_INFO_ID=$(asc app-infos list --app-id "$APP_ID" | jq -r '.data[0].id')
APP_NAME=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .name')
SUBTITLE=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .subtitle // ""')

# Version localization
VERSION_DATA=$(asc version-localizations list --version-id "$VERSION_ID")
DESCRIPTION=$(echo "$VERSION_DATA" | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .description // ""')
KEYWORDS=$(echo "$VERSION_DATA" | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .keywords // ""')
WHATS_NEW=$(echo "$VERSION_DATA" | jq -r --arg locale "$LOCALE" '.data[] | select(.locale == $locale) | .whatsNew // ""')

echo "App: $APP_NAME ($APP_ID)"
echo "Subtitle: $SUBTITLE"
echo "Description: $DESCRIPTION"
echo "Keywords: $KEYWORDS"
```