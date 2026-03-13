# Builds Archive Workflow Reference

## Architecture

```
BuildsArchive (ASCCommand)
├── resolve platform (--platform or default ios)
├── resolve export method (--export-method or default app-store-connect)
├── resolve signing style (--signing-style or default automatic)
├── resolve team ID (--team-id, optional)
├── auto-detect workspace/project from cwd
├── XcodeBuildRunner.archive(request)
│   └── xcodebuild archive -scheme X -archivePath .build/X.xcarchive
├── XcodeBuildRunner.exportArchive(request)
│   └── xcodebuild -exportArchive -archivePath ... -exportPath ... -exportOptionsPlist (auto)
└── (optional) BuildUploadRepository.uploadBuild(...)
    └── existing 5-step upload API flow
```

## Auto-detection Logic

When `--workspace` and `--project` are both omitted:

1. Scan current directory for `*.xcworkspace` — use the first match
2. If no workspace found, scan for `*.xcodeproj` — use the first match
3. If neither found, xcodebuild uses its own default resolution

Explicit flags always take precedence over auto-detection.

## Platform-to-Destination Mapping

| Platform | xcodebuild destination |
|----------|----------------------|
| `ios` | `generic/platform=iOS` |
| `macos` | `generic/platform=macOS` |
| `tvos` | `generic/platform=tvOS` |
| `visionos` | `generic/platform=visionOS` |

## ExportOptions Plist

Auto-generated as a temporary file with the selected export method, signing style, and optional team ID:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>ABCD1234</string>
</dict>
</plist>
```

- `signingStyle` is always included (default: `automatic`)
- `teamID` is only included when `--team-id` is provided
- When `signingStyle` is `automatic`, `-allowProvisioningUpdates` is added to the xcodebuild args

The plist is cleaned up after export completes.

## Binary Discovery

After export, the runner scans the export directory for:
1. `*.ipa` files (preferred — iOS/tvOS/visionOS)
2. `*.pkg` files (fallback — macOS)

If neither is found, throws `XcodeBuildError.noExportedBinary`.

## Upload Chaining

When `--upload` is specified:
- Required additional flags: `--app-id`, `--version`, `--build-number`
- Platform is reused from the archive step
- The exported IPA/PKG path is passed to `BuildUploadRepository.uploadBuild()`
- Output switches from `ExportResult` to `BuildUpload` format

## Domain Models

### Sources/Domain/Apps/Builds/XcodeBuild/XcodeBuildRunner.swift

- `ArchiveRequest` — scheme, workspace?, project?, platform, configuration, archivePath
- `ArchiveResult` — archivePath, scheme, platform (AffordanceProviding: `exportArchive`)
- `ExportRequest` — archivePath, exportPath, method, signingStyle (default: .automatic), teamId?
- `ExportResult` — ipaPath, exportPath (AffordanceProviding: `upload`)
- `ExportMethod` — appStoreConnect, adHoc, development, enterprise
- `SigningStyle` — automatic, manual
- `XcodeBuildRunner` — @Mockable protocol: archive(request:), exportArchive(request:)

### Sources/Infrastructure/Apps/Builds/XcodeBuild/ProcessXcodeBuildRunner.swift

- `XcodeBuildError` — archiveFailed, exportFailed, noExportedBinary
- `ProcessXcodeBuildRunner` — Process-based implementation, injectable xcodebuildPath for testing

## File Map

```
Sources/
├── Domain/Apps/Builds/XcodeBuild/
│   └── XcodeBuildRunner.swift
├── Infrastructure/Apps/Builds/XcodeBuild/
│   └── ProcessXcodeBuildRunner.swift
└── ASCCommand/Commands/Builds/
    └── BuildsArchive.swift

Tests/
├── DomainTests/Apps/Builds/XcodeBuild/
│   └── ArchiveExportTests.swift
├── InfrastructureTests/Apps/Builds/XcodeBuild/
│   └── ProcessXcodeBuildRunnerTests.swift
└── ASCCommandTests/Commands/Builds/
    └── BuildsArchiveTests.swift
```
