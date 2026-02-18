# Rich Domain Model Patterns

## User's Mental Model

Domain models should match how users think about App Store Connect data:

```swift
// User thinks: "What apps do I have on App Store Connect?"
public struct App: Sendable, Equatable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let sku: String?
    public let primaryLocale: String

    // User asks: "What's a short identifier for this app?"
    public var shortIdentifier: String {
        bundleId.components(separatedBy: ".").last ?? name
    }
}

// User thinks: "What's the status of this build?"
public struct Build: Sendable, Equatable {
    public let id: String
    public let version: String
    public let uploadedDate: Date
    public let processingState: ProcessingState

    // User asks: "Is this build ready to test?"
    public var isReady: Bool { processingState == .valid }

    // User asks: "How old is this build?"
    public var ageDescription: String {
        let interval = Date().timeIntervalSince(uploadedDate)
        // Return human-readable relative time
    }
}
```

## Behavior Over Data

Encapsulate domain rules in the model, not in commands or formatters:

```swift
public enum ProcessingState: String, Sendable, CaseIterable, Equatable {
    case processing = "PROCESSING"
    case failed = "FAILED"
    case invalid = "INVALID"
    case valid = "VALID"

    // Domain rule: ready for TestFlight distribution
    public var isReady: Bool { self == .valid }

    // Domain rule: terminal failure state (no recovery)
    public var hasFailed: Bool { self == .failed || self == .invalid }

    // Domain rule: human-readable display name
    public var displayName: String {
        switch self {
        case .processing: return "Processing"
        case .failed:     return "Failed"
        case .invalid:    return "Invalid"
        case .valid:      return "Valid"
        }
    }
}
```

## Repository Protocols as DI Boundaries

Define protocols in Domain for all external data access. These are the seams for testing:

```swift
@Mockable
public protocol AppRepository: Sendable {
    func fetchApps(limit: Int?) async throws -> [App]
}

@Mockable
public protocol BuildRepository: Sendable {
    func fetchBuilds(appId: String?, limit: Int?) async throws -> [Build]
}

@Mockable
public protocol TestFlightRepository: Sendable {
    func fetchBetaGroups(appId: String) async throws -> [BetaGroup]
    func fetchBetaTesters(groupId: String) async throws -> [BetaTester]
}
```

## Value Types for Data

Use structs for immutable domain data. Never use classes for domain models:

```swift
public struct BetaTester: Sendable, Equatable {
    public let id: String
    public let firstName: String?
    public let lastName: String?
    public let email: String
    public let inviteType: InviteType

    // Computed display property - encapsulated in the model
    public var displayName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

public enum InviteType: String, Sendable {
    case email = "EMAIL"
    case publicLink = "PUBLIC_LINK"

    public var displayName: String {
        switch self {
        case .email: return "Email Invitation"
        case .publicLink: return "Public Link"
        }
    }
}
```

## Paginated Responses

Use generics for the common pagination wrapper:

```swift
public struct PaginatedResponse<T: Sendable>: Sendable {
    public let data: [T]
    public let total: Int?
    public let nextCursor: String?

    public var hasMore: Bool { nextCursor != nil }
    public var isEmpty: Bool { data.isEmpty }
}
```

## Error Types

Domain-specific error types with user-facing messages:

```swift
public enum APIError: Error, Sendable {
    case unauthorized
    case notFound(resource: String)
    case rateLimited
    case serverError(statusCode: Int)
    case decodingFailed(underlying: Error)

    // Domain rule: what to tell the user
    public var userFacingMessage: String {
        switch self {
        case .unauthorized:
            return "Authentication failed. Check ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY_PATH."
        case .notFound(let resource):
            return "\(resource) not found."
        case .rateLimited:
            return "Rate limit exceeded. Please wait before retrying."
        case .serverError(let code):
            return "Server error (\(code)). Try again later."
        case .decodingFailed:
            return "Failed to parse API response."
        }
    }
}
```

## Factory / Mapping Methods

Use static factory methods to construct domain models from SDK types:

```swift
extension App {
    // Adapter mapping: SDK type → domain type (lives in Infrastructure, not Domain)
    static func from(_ sdkApp: AppStoreConnectSwiftSDK.App) -> App {
        App(
            id: sdkApp.id,
            name: sdkApp.attributes?.name ?? "",
            bundleId: sdkApp.attributes?.bundleId ?? "",
            sku: sdkApp.attributes?.sku,
            primaryLocale: sdkApp.attributes?.primaryLocale ?? "en-US"
        )
    }
}

extension Build {
    static func from(_ sdkBuild: AppStoreConnectSwiftSDK.Build) -> Build {
        Build(
            id: sdkBuild.id,
            version: sdkBuild.attributes?.version ?? "",
            uploadedDate: sdkBuild.attributes?.uploadedDate ?? .distantPast,
            processingState: ProcessingState(
                rawValue: sdkBuild.attributes?.processingState?.rawValue ?? ""
            ) ?? .processing
        )
    }
}
```

## What NOT to Put in Domain Models

- No import of `appstoreconnect-swift-sdk` (Infrastructure concern)
- No formatting logic for CLI output (ASCCommand concern)
- No URLSession or network code
- No `@Observable` or SwiftUI types (this is a CLI, not a GUI app)