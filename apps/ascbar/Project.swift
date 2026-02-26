import ProjectDescription

let project = Project(
    name: "ASCBar",
    options: .options(
        defaultKnownRegions: ["en"],
        developmentRegion: "en"
    ),
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "MACOSX_DEPLOYMENT_TARGET": "15.0",
        ],
        debug: [
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG MOCKING",
        ],
        release: [
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "MOCKING",
        ]
    ),
    targets: [

        // MARK: - Domain Layer

        .target(
            name: "Domain",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.hanrenwei.ascbar.domain",
            deploymentTargets: .macOS("15.0"),
            sources: ["Sources/Domain/**"],
            dependencies: [
                .external(name: "Mockable"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                ]
            )
        ),

        // MARK: - Infrastructure Layer

        .target(
            name: "Infrastructure",
            destinations: .macOS,
            product: .staticFramework,
            bundleId: "com.hanrenwei.ascbar.infrastructure",
            deploymentTargets: .macOS("15.0"),
            sources: ["Sources/Infrastructure/**"],
            dependencies: [
                .target(name: "Domain"),
                .external(name: "Mockable"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                ]
            )
        ),

        // MARK: - Main Application

        .target(
            name: "ASCBar",
            destinations: .macOS,
            product: .app,
            bundleId: "com.hanrenwei.ascbar",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .file(path: "Sources/App/Info.plist"),
            sources: ["Sources/App/**"],
            entitlements: .file(path: "Sources/App/entitlements.plist"),
            dependencies: [
                .target(name: "Domain"),
                .target(name: "Infrastructure"),
                .external(name: "Shimmer"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "ENABLE_PREVIEWS": "YES",
                    "CODE_SIGN_IDENTITY": "-",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                ]
            )
        ),

        // MARK: - Domain Tests

        .target(
            name: "DomainTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.hanrenwei.ascbar.domain-tests",
            deploymentTargets: .macOS("15.0"),
            sources: ["Tests/DomainTests/**"],
            dependencies: [
                .target(name: "Domain"),
                .external(name: "Mockable"),
            ],
            settings: .settings(
                base: [
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "MOCKING",
                ]
            )
        ),
    ],
    schemes: [
        .scheme(
            name: "ASCBar",
            shared: true,
            buildAction: .buildAction(targets: ["ASCBar"]),
            testAction: .targets(
                [.testableTarget(target: .target("DomainTests"))],
                configuration: .debug
            ),
            runAction: .runAction(configuration: .debug, executable: .target("ASCBar")),
            archiveAction: .archiveAction(configuration: .release)
        ),
    ]
)
