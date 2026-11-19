# Use as a Swift Package

`asc-cli` exposes an `ASCKit` library product so you can embed App Store Connect automation directly into your own Swift tool, script, or app without using the CLI binary.

## Add the dependency

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tddworks/asc-cli.git", from: "0.18.0"),
],
targets: [
    .target(
        name: "MyTool",
        dependencies: [
            .product(name: "ASCKit", package: "asc-cli"),
        ]
    ),
]
```

## Example

```swift
import ASCKit

// 1. Provide credentials (inline, env vars, or your own AuthProvider)
let credentials = AuthCredentials(
    keyID: "YOUR_KEY_ID",
    issuerID: "YOUR_ISSUER_ID",
    privateKeyPEM: """
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
    """
)

// 2. A simple inline AuthProvider that wraps fixed credentials
struct StaticAuthProvider: AuthProvider {
    let credentials: AuthCredentials
    func resolve() throws -> AuthCredentials { credentials }
}

// 3. Create any repository via ClientFactory
let factory = ClientFactory()
let authProvider = StaticAuthProvider(credentials: credentials)

let appRepo = try factory.makeApps(authProvider: authProvider)
let apps = try await appRepo.listApps(limit: 50)
apps.data.forEach { print($0.name, $0.bundleId) }

let buildRepo = try factory.makeBuilds(authProvider: authProvider)
let builds = try await buildRepo.listBuilds(appId: "YOUR_APP_ID", platform: nil, version: nil, limit: 10)
```

## Repositories

`ClientFactory` has a `make…Repository(authProvider:)` method for every domain area: apps, builds, versions, TestFlight, screenshots, in-app purchases, subscriptions, reports, code signing, Xcode Cloud and more. The full list is in [`Sources/ASCKit/Shared/Internal/ClientFactory.swift`](../Sources/ASCKit/Shared/Internal/ClientFactory.swift); each returns a protocol from the concept's public face.
