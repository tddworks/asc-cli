# Swift 6.2 Concurrency Patterns

asc-swift uses Swift 6.2 strict concurrency. All domain models are immutable value types — no shared mutable state.

## Sendable Value Types

All domain models are immutable structs conforming to `Sendable` automatically:

```swift
// Structs with only Sendable stored properties are implicitly Sendable
public struct App: Sendable, Equatable {
    public let id: String
    public let name: String
    public let bundleId: String
}

// Enums with Sendable associated values are implicitly Sendable
public enum ProcessingState: String, Sendable {
    case processing = "PROCESSING"
    case valid = "VALID"
}
```

## Async Repository Methods

All repository protocols use `async throws`:

```swift
@Mockable
public protocol AppRepository: Sendable {
    func fetchApps(limit: Int?) async throws -> [App]
}

@Mockable
public protocol BuildRepository: Sendable {
    func fetchBuilds(appId: String?, limit: Int?) async throws -> [Build]
}
```

## Async CLI Commands

Commands inherit from `AsyncParsableCommand` to support `async run()`:

```swift
struct AppsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all apps"
    )

    @OptionGroup var globalOptions: GlobalOptions
    @Option(name: .long, help: "Maximum number of results")
    var limit: Int = 50

    func run() async throws {
        let repo = ClientProvider.makeAppRepository(globalOptions)
        let apps = try await repo.fetchApps(limit: limit)
        OutputFormatter.print(apps, format: globalOptions.output)
    }
}
```

## Stateless Infrastructure Types

Infrastructure types that don't hold mutable state use `struct`:

```swift
// Stateless — reads environment at call time, no stored mutable state
public struct EnvironmentAuthProvider: AuthProvider, Sendable {
    public func credentials() throws -> AuthCredentials {
        guard let keyId = ProcessInfo.processInfo.environment["ASC_KEY_ID"] else {
            throw AuthError.missingKeyId
        }
        guard let issuerId = ProcessInfo.processInfo.environment["ASC_ISSUER_ID"] else {
            throw AuthError.missingIssuerId
        }
        // Resolve private key from path or env var
        let privateKey = try resolvePrivateKey()
        return AuthCredentials(keyId: keyId, issuerId: issuerId, privateKey: privateKey)
    }
}
```

## Error Propagation

Use typed throwing through the async call chain:

```swift
func run() async throws {
    do {
        let apps = try await repo.fetchApps(limit: limit)
        OutputFormatter.print(apps, format: globalOptions.output)
    } catch let error as APIError {
        // Map to ArgumentParser's exit error for clean CLI output
        throw ExitCode.failure
    } catch let error as AuthError {
        fputs("Auth error: \(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
    }
}
```

## Async Test Patterns

```swift
// Use async throws in @Test functions
@Test func `fetchApps returns apps`() async throws {
    let mockRepo = MockAppRepository()
    given(mockRepo).fetchApps(limit: .any).willReturn([
        App(id: "1", name: "Test App", bundleId: "com.test.app", sku: nil, primaryLocale: "en-US")
    ])

    let apps = try await mockRepo.fetchApps(limit: nil)
    #expect(apps.count == 1)
}

// Test error throwing with await #expect(throws:)
@Test func `fetchApps propagates auth error`() async {
    let mockRepo = MockAppRepository()
    given(mockRepo).fetchApps(limit: .any).willThrow(APIError.unauthorized)

    await #expect(throws: APIError.unauthorized) {
        try await mockRepo.fetchApps(limit: nil)
    }
}
```

## Swift 6.2 Strict Concurrency Checklist

- [ ] Domain models are `struct` + `Sendable` (not `class`)
- [ ] Repository protocols conform to `Sendable`
- [ ] Infrastructure structs are stateless or explicitly `Sendable`
- [ ] Commands use `AsyncParsableCommand` for async entry points
- [ ] No `@unchecked Sendable` unless absolutely necessary with documented reason
- [ ] All `async throws` propagate errors rather than swallowing them