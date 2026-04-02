// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "hello-plugin",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HelloPlugin", type: .dynamic, targets: ["HelloPlugin"]),
    ],
    dependencies: [
        .package(path: "../../"),  // asc-cli
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", exact: "2.21.1"),
    ],
    targets: [
        .target(
            name: "HelloPlugin",
            dependencies: [
                .product(name: "ASCPlugin", package: "asc-cli"),
                .product(name: "ASCKit", package: "asc-cli"),
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"]),
            ]
        ),
    ]
)
