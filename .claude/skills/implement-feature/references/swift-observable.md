# Swift 6.2 Concurrency in asc-swift

## Key Rules

- All domain models: `Sendable` (struct is implicitly Sendable when all stored props are Sendable)
- Repository protocols: `: Sendable` (required for `@Mockable` compatibility)
- Infrastructure repos: `@unchecked Sendable` (hold `APIProvider` which is a reference type)
- Commands: `AsyncParsableCommand` with `async throws func run()`

## Domain Models (Pure Structs)

```swift
// Automatically Sendable — all stored props are value types
public struct AppStoreVersion: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String
    public let versionString: String
    public let platform: AppStorePlatform    // enum: Sendable
    public let state: AppStoreVersionState  // enum: Sendable
    public let createdDate: Date?
}
```

## Repository Protocols

```swift
@Mockable
public protocol AppRepository: Sendable {
    func listApps(limit: Int?) async throws -> PaginatedResponse<App>
    func listVersions(appId: String) async throws -> [AppStoreVersion]
}
```

## Infrastructure (APIProvider wrapper)

```swift
// @unchecked Sendable because APIProvider is a reference type
public struct SDKAppRepository: AppRepository, @unchecked Sendable {
    private let provider: APIProvider

    public func listVersions(appId: String) async throws -> [AppStoreVersion] {
        let request = APIEndpoint.v1.apps.id(appId).appStoreVersions.get()
        let response = try await provider.request(request)
        return response.data.map { mapVersion($0, appId: appId) }
    }
}
```

## Commands

```swift
struct VersionsList: AsyncParsableCommand {
    @OptionGroup var globals: GlobalOptions
    @Option(name: .long) var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppRepository()
        let versions = try await repo.listVersions(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        let output = try formatter.formatAgentItems(
            versions,
            headers: ["Platform", "Version", "State"],
            rowMapper: { v in [v.platform.displayName, v.versionString, v.state.displayName] }
        )
        print(output)
    }
}
```

## TUI (@MainActor)

```swift
@MainActor
final class TUIApp {
    func loadVersions(for app: App) {
        Task { @MainActor in
            let repo = try ClientProvider.makeAppRepository()
            let versions = try await repo.listVersions(appId: app.id)
            // update UI
        }
    }
}
```

## Method Naming

Use `list` prefix for collection fetches (not `fetch`):
- `listApps(limit:)` ✅
- `listVersions(appId:)` ✅
- `fetchApps(limit:)` ❌