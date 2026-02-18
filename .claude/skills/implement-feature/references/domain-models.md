# Rich Domain Model Patterns

## Model Requirements

Every domain model must be:

```swift
public struct MyModel: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let parentId: String  // always carry parent ID
    // ...
}
```

Required conformances:
- `Sendable` — safe to pass across concurrency boundaries
- `Equatable` — testable with `#expect(a == b)`
- `Identifiable` — TUI navigation uses this
- `Codable` — the JSON encoding IS the public API schema
- `AffordanceProviding` — embed navigation commands (see command-affordances.md)

## Parent IDs (Critical)

The ASC API never includes parent IDs in response bodies. The infrastructure mapper must inject them:

```swift
// Infrastructure: inject parentId from the request parameter
private func mapLocalization(
    _ sdk: AppStoreVersionLocalization,
    versionId: String            // ← comes from the request, not the response
) -> Domain.AppStoreVersionLocalization {
    Domain.AppStoreVersionLocalization(
        id: sdk.id,
        versionId: versionId,    // ← injected
        locale: sdk.attributes?.locale ?? ""
    )
}
```

Resource hierarchy and required parent IDs:
```
App                                    (no parent)
└── AppStoreVersion      .appId        (parent: App.id)
    └── AppStoreVersionLocalization .versionId  (parent: AppStoreVersion.id)
        └── AppScreenshotSet  .localizationId  (parent: Localization.id)
            └── AppScreenshot .setId           (parent: ScreenshotSet.id)
```

## Semantic Booleans on State Enums

Agents use computed booleans for decisions without extra round-trips:

```swift
public enum AppStoreVersionState: String, Sendable, Equatable, Codable {
    case readyForSale      = "READY_FOR_SALE"
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case inReview          = "IN_REVIEW"
    case waitingForReview  = "WAITING_FOR_REVIEW"
    // ... all 15 cases

    public var isLive: Bool     { self == .readyForSale }
    public var isEditable: Bool { [.prepareForSubmission, .developerRejected, .rejected, .metadataRejected].contains(self) }
    public var isPending: Bool  { [.waitingForReview, .inReview, .pendingDeveloperRelease, ...].contains(self) }
    public var displayName: String { /* human-readable */ }
}
```

Delegate from the model to the state:
```swift
public var isLive: Bool     { state.isLive }
public var isEditable: Bool { state.isEditable }
public var isPending: Bool  { state.isPending }
```

## Behavior Over Data

```swift
public struct AppScreenshot: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let setId: String
    public let fileName: String
    public let fileSize: Int
    public let assetState: AssetDeliveryState?

    // Domain behavior — not in formatters
    public var isComplete: Bool { assetState == .complete }

    public var fileSizeDescription: String {
        let bytes = Double(fileSize)
        if bytes < 1024 { return "\(fileSize) B" }
        if bytes < 1_048_576 { return String(format: "%.1f KB", bytes / 1024) }
        return String(format: "%.1f MB", bytes / 1_048_576)
    }

    public var dimensionsDescription: String? {
        guard let w = imageWidth, let h = imageHeight else { return nil }
        return "\(w) × \(h)"
    }
}
```

## Repository Protocols

```swift
@Mockable
public protocol AppRepository: Sendable {
    func listApps(limit: Int?) async throws -> PaginatedResponse<App>
    func listVersions(appId: String) async throws -> [AppStoreVersion]
}

@Mockable
public protocol ScreenshotRepository: Sendable {
    func listLocalizations(versionId: String) async throws -> [AppStoreVersionLocalization]
    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]
    func listScreenshots(setId: String) async throws -> [AppScreenshot]
}
```

Method naming convention: `list` prefix (not `fetch`).

## MockRepositoryFactory (Test Helper)

All tests use `MockRepositoryFactory` with sensible defaults — never construct models inline:

```swift
// Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift
enum MockRepositoryFactory {
    static func makeVersion(
        id: String = "v1",
        appId: String = "app-1",
        versionString: String = "1.0",
        platform: AppStorePlatform = .iOS,
        state: AppStoreVersionState = .prepareForSubmission
    ) -> AppStoreVersion { ... }

    static func makeLocalization(
        id: String = "loc-1",
        versionId: String = "v-1",
        locale: String = "en-US"
    ) -> AppStoreVersionLocalization { ... }
}

// Usage in tests:
let version = MockRepositoryFactory.makeVersion(state: .readyForSale)
let loc = MockRepositoryFactory.makeLocalization(versionId: "v-99")
```

Add new `make*` methods to `MockRepositoryFactory` whenever you add a new domain model.

## Infrastructure Mapper Pattern

Use private mapper functions (not static factory methods on the domain type):

```swift
// In OpenAPIXxxRepository.swift (Infrastructure layer)
private func mapVersion(
    _ sdkVersion: AppStoreConnect_Swift_SDK.AppStoreVersion,
    appId: String
) -> Domain.AppStoreVersion {
    let state = Domain.AppStoreVersionState(
        rawValue: sdkVersion.attributes?.appStoreState?.rawValue ?? ""
    ) ?? .prepareForSubmission
    return Domain.AppStoreVersion(
        id: sdkVersion.id,
        appId: appId,
        versionString: sdkVersion.attributes?.versionString ?? "",
        platform: Domain.AppStorePlatform(rawValue: sdkVersion.attributes?.platform?.rawValue ?? "") ?? .iOS,
        state: state,
        createdDate: sdkVersion.attributes?.createdDate
    )
}
```

## What NOT to Put in Domain Models

- No `import AppStoreConnect_Swift_SDK` (Infrastructure concern)
- No CLI output formatting (ASCCommand concern)
- No network code or `URLSession`
- No SwiftUI or `@Observable` (this is a CLI, not a GUI app)
- No injected repositories (use free functions or navigator classes for composition)