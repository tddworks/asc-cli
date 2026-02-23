# App Store Connect API Reference

Base URL: `https://api.appstoreconnect.apple.com/v1`

All endpoints require a signed JWT in the `Authorization: Bearer <token>` header. The CLI handles auth automatically via `EnvironmentAuthProvider`.

---

## Apps

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/apps` | `asc apps list` |

---

## App Store Versions

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/apps/{id}/appStoreVersions` | `asc versions list --app-id <id>` |
| POST | `/v1/appStoreVersions` | `asc versions create --app-id <id> --version <v> --platform IOS` |
| GET | `/v1/appStoreVersions/{id}` | *(used internally by submit flow)* |

---

## Submit for Review (4-step orchestration)

`asc versions submit --version-id <id>` internally calls:

| Step | Method | Endpoint |
|------|--------|----------|
| 1 | GET | `/v1/appStoreVersions/{id}` — extract `appId` + `platform` |
| 2 | POST | `/v1/reviewSubmissions` — create submission |
| 3 | POST | `/v1/reviewSubmissionItems` — add version as item |
| 4 | PATCH | `/v1/reviewSubmissions/{id}` — set `submitted: true` |

---

## App Store Version Localizations

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/appStoreVersions/{id}/appStoreVersionLocalizations` | `asc localizations list --version-id <id>` |
| POST | `/v1/appStoreVersionLocalizations` | `asc localizations create --version-id <id> --locale <locale>` |

---

## Screenshot Sets

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/appStoreVersionLocalizations/{id}/appScreenshotSets` | `asc screenshot-sets list --localization-id <id>` |
| POST | `/v1/appScreenshotSets` | `asc screenshot-sets create --localization-id <id> --display-type <type>` |

---

## Screenshots

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/appScreenshotSets/{id}/appScreenshots` | `asc screenshots list --set-id <id>` |
| POST + S3 + PATCH | *(3-step, see below)* | `asc screenshots upload --set-id <id> --file <path>` |

### Upload 3-step flow

| Step | Method | Endpoint | Purpose |
|------|--------|----------|---------|
| 1 | POST | `/v1/appScreenshots` | Reserve slot, get S3 upload URL |
| 2 | PUT | *(S3 presigned URL)* | Binary upload with MD5 checksum |
| 3 | PATCH | `/v1/appScreenshots/{id}` | Commit (`uploaded: true`) |

### Import from ZIP

`asc screenshots import --version-id <id> --from export.zip` reuses the above endpoints in a loop per locale from `manifest.json`.

---

## App Infos

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/apps/{id}/appInfos` | `asc app-infos list --app-id <id>` |

---

## App Info Localizations

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/appInfos/{id}/appInfoLocalizations` | `asc app-info-localizations list --app-info-id <id>` |
| POST | `/v1/appInfoLocalizations` | `asc app-info-localizations create --app-info-id <id> --locale <l> --name <n>` |
| PATCH | `/v1/appInfoLocalizations/{id}` | `asc app-info-localizations update --localization-id <id> [--name] [--subtitle] [--privacy-policy-url]` |

---

## Builds

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/builds` | `asc builds list` |
| GET | `/v1/builds?filter[app]=<id>` | `asc builds list --app-id <id>` |

Key fields: `version`, `uploadedDate`, `processingState` (`PROCESSING`, `VALID`, `INVALID`)

---

## TestFlight

| Method | Endpoint | CLI command |
|--------|----------|-------------|
| GET | `/v1/betaGroups?filter[app]=<id>` | `asc testflight groups list --app-id <id>` |
| GET | `/v1/betaTesters?filter[apps]=<id>` | `asc testflight testers list --app-id <id>` |

---

## Error Codes

| HTTP | Code | Meaning |
|------|------|---------|
| 401 | UNAUTHORIZED | Credentials missing or expired JWT |
| 404 | NOT_FOUND | Wrong resource ID or wrong ID type passed to wrong endpoint |
| 409 | STATE_ERROR.ENTITY_STATE_INVALID | Version not in a state that allows the operation (e.g. missing screenshots, build, or metadata before submit) |
| 422 | PARAMETER_ERROR | Invalid field value (e.g. unsupported locale or display type) |