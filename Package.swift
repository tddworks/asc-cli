// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "asc-cli",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "asc", targets: ["ASCCommand"]),
        .library(name: "ASCKit", targets: ["Domain", "Infrastructure"]),
        .library(name: "ASCPlugin", targets: ["ASCPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AvdLee/appstoreconnect-swift-sdk.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/Kolos65/Mockable", from: "0.6.0"),
        .package(url: "https://github.com/steipete/TauTUI.git", from: "0.1.5"),
        .package(url: "https://github.com/steipete/SweetCookieKit.git", from: "0.3.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", exact: "2.21.1"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "ASCPlugin",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
            ]
        ),
        .target(
            name: "Domain",
            dependencies: [
                .product(name: "Mockable", package: "Mockable"),
            ],
            resources: [.copy("Screenshots/Gallery/Resources")],
            swiftSettings: [.define("MOCKING")]
        ),
        .target(
            name: "Infrastructure",
            dependencies: [
                "Domain",
                "ASCPlugin",
                .product(name: "AppStoreConnect-Swift-SDK", package: "appstoreconnect-swift-sdk"),
                .product(name: "SweetCookieKit", package: "sweetcookiekit"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdTLS", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
            ]
        ),
        .executableTarget(
            name: "ASCCommand",
            dependencies: [
                "Domain",
                "Infrastructure",
                "ASCPlugin",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "TauTUI", package: "TauTUI"),
            ],
            resources: [.copy("Resources/mockups")]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain",
                .product(name: "Mockable", package: "Mockable"),
            ],
            swiftSettings: [.define("MOCKING")]
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "Infrastructure",
                "Domain",
                .product(name: "Mockable", package: "Mockable"),
            ],
            swiftSettings: [.define("MOCKING")]
        ),
        .testTarget(
            name: "ASCCommandTests",
            dependencies: [
                "ASCCommand",
                "Domain",
                .product(name: "Mockable", package: "Mockable"),
            ],
            swiftSettings: [.define("MOCKING")]
        ),
    ]
)
