// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [:]
)
#endif

let package = Package(
    name: "ASCBar",
    dependencies: [
        .package(url: "https://github.com/Kolos65/Mockable.git", from: "0.5.0"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer.git", from: "1.5.1"),
    ]
)
