// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "asc-swift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "asc", targets: ["ASCCommand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AvdLee/appstoreconnect-swift-sdk.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/Kolos65/Mockable", from: "0.6.0"),
        .package(url: "https://github.com/steipete/TauTUI.git", from: "0.1.5"),
    ],
    targets: [
        .target(
            name: "Domain",
            dependencies: [
                .product(name: "Mockable", package: "Mockable"),
            ],
            swiftSettings: [.define("MOCKING")]
        ),
        .target(
            name: "Infrastructure",
            dependencies: [
                "Domain",
                .product(name: "AppStoreConnect-Swift-SDK", package: "appstoreconnect-swift-sdk"),
            ]
        ),
        .executableTarget(
            name: "ASCCommand",
            dependencies: [
                "Domain",
                "Infrastructure",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "TauTUI", package: "TauTUI"),
            ]
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
