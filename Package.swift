// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "asc-swift",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "asc", targets: ["ASCCommand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-crypto", "1.0.0" ..< "5.0.0"),
        .package(url: "https://github.com/Kolos65/Mockable", from: "0.6.0"),
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
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Crypto", package: "swift-crypto"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .executableTarget(
            name: "ASCCommand",
            dependencies: [
                "Domain",
                "Infrastructure",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
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
