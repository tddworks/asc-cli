# asc builds upload — Workflow Reference

## 5-Step Upload API Flow

The `asc builds upload` command executes these App Store Connect API calls in order:

1. **Create upload session** — `POST /v1/buildUploads`
   Returns an upload ID and session.

2. **Reserve file slot** — `POST /v1/buildUploadFiles`
   Sends filename, filesize, and UTI (`.ipa` → `com.apple.ipa`, `.pkg` → `com.apple.pkg`).
   Returns `uploadOperations[]` — presigned chunk URLs with offsets and lengths.

3. **Upload chunks** — `PUT <presigned-url>` (per chunk)
   Each chunk is sliced from the file data and PUT to its presigned S3 URL with required headers.

4. **Confirm with MD5** — `PATCH /v1/buildUploadFiles/{id}`
   Sends MD5 checksum of the full file and `isUploaded: true` to signal completion.

5. **Get final state** — `GET /v1/buildUploads/{id}`
   Returns the current upload state. Use `--wait` to poll until not pending.

## Build Upload States

| State | `isPending` | `isComplete` | `hasFailed` | Meaning |
|-------|-------------|--------------|-------------|---------|
| `AWAITING_UPLOAD` | true | false | false | Session created, upload not started |
| `PROCESSING` | true | false | false | Upload received, ASC processing |
| `COMPLETE` | false | true | false | Build is ready |
| `FAILED` | false | false | true | Upload or processing failed |

**Polling with `--wait`:** Re-fetches every 10 seconds until `isPending == false`.

## Common Errors

**"Unknown platform: X"**
Use one of: `ios`, `macos`, `tvos`, `visionos`. Or omit `--platform` and let it auto-detect from the file extension (`.pkg` → `macos`, all others → `ios`).

**Build not appearing after upload**
- Wait for `state == COMPLETE` — use `--wait` flag or poll with `asc builds uploads get`
- Then use `asc builds list --app-id <id>` to find the build ID

**`listBuilds` affordance missing from `uploads get` response**
Expected — the single-resource GET (`/v1/buildUploads/{id}`) doesn't return `appId`. Use `asc builds uploads list --app-id <id>` instead for the full affordances.

**`upsert` on beta notes fails**
`update-beta-notes` does a GET-then-PATCH (if locale exists) or POST (if new). The locale must match exactly, e.g. `en-US` not `en_US`.

## Finding IDs

```bash
# App ID
asc apps list | jq -r '.data[] | select(.name == "MyApp") | .id'

# Build ID (after upload completes)
asc builds list --app-id $APP_ID | jq -r '.data[0].id'

# Beta group ID
asc testflight groups list --app-id $APP_ID | jq -r '.data[0].id'

# Version ID
asc versions list --app-id $APP_ID | jq -r '.data[0].id'
```

## API Reference

| Step | Endpoint | Purpose |
|------|----------|---------|
| 1 | `POST /v1/buildUploads` | Create upload session |
| 2 | `POST /v1/buildUploadFiles` | Reserve file slot, get presigned URLs |
| 3 | `PUT <presigned-url>` | Upload file chunks |
| 4 | `PATCH /v1/buildUploadFiles/{id}` | Confirm with MD5 checksum |
| 5 | `GET /v1/buildUploads/{id}` | Fetch final state |
| - | `GET /v1/apps/{id}/buildUploads` | List all uploads for an app |
| - | `DELETE /v1/buildUploads/{id}` | Delete pending upload |
| - | `POST /v1/builds/{id}/relationships/betaGroups` | Add beta group |
| - | `DELETE /v1/builds/{id}/relationships/betaGroups` | Remove beta group |
| - | `GET /v1/builds/{id}/betaBuildLocalizations` | List beta notes |
| - | `POST /v1/betaBuildLocalizations` | Create beta notes |
| - | `PATCH /v1/betaBuildLocalizations/{id}` | Update beta notes |
| - | `PATCH /v1/appStoreVersions/{id}` | Link build to version |
