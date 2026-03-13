---
name: asc-builds-archive
description: |
  Archive and export Xcode projects to IPA/PKG using the `asc` CLI tool, with optional upload to App Store Connect.
  Use this skill when:
  (1) Archiving an Xcode project: "asc builds archive --scheme MyApp"
  (2) Exporting an archive to IPA or PKG for distribution
  (3) Archive + export + upload in one step: "asc builds archive --scheme MyApp --upload --app-id ..."
  (4) User says "archive my app", "build for TestFlight", "export IPA", "archive and upload", "build and distribute", "create an IPA from my Xcode project"
  (5) User wants to go from Xcode project to TestFlight without manually running xcodebuild
---

# asc Builds Archive & Export

Archive Xcode projects, export IPA/PKG binaries, and optionally upload to App Store Connect — all in one command. See [workflow.md](references/workflow.md) for the full end-to-end flow.

## Commands

### Archive and export

```bash
asc builds archive \
  --scheme <SCHEME_NAME> \
  [--workspace MyApp.xcworkspace]     # auto-detected from cwd
  [--project MyApp.xcodeproj]         # auto-detected from cwd
  [--platform ios|macos|tvos|visionos] # default: ios
  [--configuration Release]           # default: Release
  [--export-method app-store-connect|ad-hoc|development|enterprise]  # default: app-store-connect
  [--signing-style automatic|manual]  # default: automatic
  [--team-id ABCD1234]               # team ID for signing
  [--output-dir .build]              # default: .build
```

Workspace/project are auto-detected from the current directory if not specified. The command runs `xcodebuild archive` followed by `xcodebuild -exportArchive` with an auto-generated ExportOptions plist.

### Archive + export + upload (one command)

```bash
asc builds archive \
  --scheme <SCHEME_NAME> \
  --upload \
  --app-id <APP_ID> \
  --version 1.0.0 \
  --build-number 42
```

The `--upload` flag chains the exported IPA/PKG directly into the existing `asc builds upload` flow.

## Resolve App ID

See [project-context.md](../shared/project-context.md) — check `.asc/project.json` before asking the user or running `asc apps list`.

## Typical Workflow

```bash
APP_ID=$(cat .asc/project.json 2>/dev/null | jq -r '.appId // empty')
# If empty: ask user or run `asc apps list | jq -r '.data[0].id'`

# 1. Archive, export, and upload in one command
asc builds archive --scheme MyApp --upload \
  --app-id "$APP_ID" --version 1.2.0 --build-number 55

# 2. Get the processed build ID
BUILD_ID=$(asc builds list --app-id $APP_ID | jq -r '.data[0].id')

# 3. Distribute to TestFlight beta group
asc builds add-beta-group --build-id $BUILD_ID --beta-group-id $GROUP_ID

# 4. Set TestFlight notes
asc builds update-beta-notes --build-id $BUILD_ID --locale en-US --notes "New features"

# 5. Link to version and submit for review
asc versions set-build --version-id $VERSION_ID --build-id $BUILD_ID
asc versions submit --version-id $VERSION_ID
```

### Archive only (no upload)

```bash
# Archive and export to default .build/export/
asc builds archive --scheme MyApp

# The output includes an affordance for the next step:
# "upload": "asc builds upload --file .build/export/MyApp.ipa"

# Ad-hoc distribution
asc builds archive --scheme MyApp --export-method ad-hoc --output-dir dist/

# Manual signing with team ID
asc builds archive --scheme MyApp --signing-style manual --team-id ABCD1234

# macOS app
asc builds archive --scheme MyMacApp --platform macos
```

## Export Methods

| Method | Use case |
|--------|----------|
| `app-store-connect` | App Store / TestFlight distribution (default) |
| `ad-hoc` | Direct distribution to registered devices |
| `development` | Development testing on registered devices |
| `enterprise` | In-house enterprise distribution |

## Signing Options

| Flag | Default | Description |
|------|---------|-------------|
| `--signing-style` | `automatic` | `automatic` lets Xcode manage profiles; `manual` requires pre-configured profiles |
| `--team-id` | (none) | Apple Developer team ID; useful when multiple teams are configured |

When `--signing-style automatic` (the default), the export step passes `-allowProvisioningUpdates` to `xcodebuild` so profiles are automatically resolved.

## CAEOAS Affordances

Archive-only responses include an `upload` affordance pointing to the exported binary:

```json
{
  "data": [{
    "ipaPath": ".build/export/MyApp.ipa",
    "exportPath": ".build/export",
    "affordances": {
      "upload": "asc builds upload --file .build/export/MyApp.ipa"
    }
  }]
}
```

When `--upload` is used, the response matches the standard build upload format with `checkStatus` and `listBuilds` affordances.

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| "Unknown platform: watchos" | Invalid platform argument | Use: `ios`, `macos`, `tvos`, `visionos` |
| "Scheme not found" | Scheme doesn't exist or workspace not detected | Pass `--workspace` or `--project` explicitly |
| "no signing identity found" | Code signing not configured | Configure signing in Xcode or pass `--export-method development` |
| "No profiles for 'X' were found" | Provisioning profile not available | Default `--signing-style automatic` resolves this; or pass `--team-id` explicitly |
| "app-store" is deprecated | Old export method name | Use `app-store-connect` (now the default) |
| "No .ipa or .pkg found" | Export succeeded but no binary produced | Check xcodebuild output, verify scheme builds an app target |
| "--app-id is required" | `--upload` used without `--app-id` | Provide `--app-id` or run `asc init` first |

## Reference

See [workflow.md](references/workflow.md) for:
- Auto-detection logic for workspace/project
- ExportOptions plist generation details
- Platform-to-destination mapping
- How archive chains into the upload flow
