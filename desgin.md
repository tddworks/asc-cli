Plan: Swift App Store Connect CLI (asc-swift)

Context

Create a new Swift CLI for App Store Connect at ~/github/learning/asc-swift/. The CLI uses Apple's official OpenAPI spec (downloaded from Apple's sample code site) to auto-generate a type-safe SDK via swift-openapi-generator, then builds a CLI on top using swift-argument-parser. The architecture follows rich
domain first design (modeled after the claudebar project), uses TDD with Mockable for mocking, targets Swift 6.2, and uses Swift Testing with backtick-style test names.

 ---
Architecture: Three-Layer Design

Sources/
├── Domain/           # Pure business logic, protocols, rich models (zero external deps except Mockable)
├── Infrastructure/   # Implementations: OpenAPI client, JWT auth, networking
└── ASCCommand/       # CLI executable: argument parsing, output formatting

Dependency flow: ASCCommand → Infrastructure → Domain

 ---
Step 1: Create project skeleton and Package.swift

Create ~/github/learning/asc-swift/ with:

Package.swift (Swift 6.2, macOS 13+):
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
.package(url: "https://github.com/apple/swift-crypto", "1.0.0"..<"5.0.0"),
.package(url: "https://github.com/Kolos65/Mockable", from: "0.6.0"),
],
targets: [
// Domain: pure business logic + @Mockable protocols
.target(
name: "Domain",
dependencies: [
.product(name: "Mockable", package: "Mockable"),
],
swiftSettings: [.define("MOCKING")]
),

         // Infrastructure: OpenAPI generated client + JWT auth + networking
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

         // CLI executable
         .executableTarget(
             name: "ASCCommand",
             dependencies: [
                 "Domain",
                 "Infrastructure",
                 .product(name: "ArgumentParser", package: "swift-argument-parser"),
             ]
         ),

         // Tests
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

 ---
Step 2: Download OpenAPI spec

curl -L -o /tmp/asc-openapi.zip \
https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip
unzip -o /tmp/asc-openapi.zip -d /tmp/asc-openapi
cp /tmp/asc-openapi/*.json Sources/Infrastructure/openapi.json

Create Sources/Infrastructure/openapi-generator-config.yaml:
generate:
- types
- client
  accessModifier: public

 ---
Step 3: Domain layer (TDD first)

All protocols get @Mockable. All models are rich value types with behavior.

Directory structure

Sources/Domain/
├── Auth/
│   ├── AuthCredentials.swift          # Value object: keyID, issuerID, privateKeyPEM
│   ├── AuthProvider.swift             # @Mockable protocol
│   └── AuthError.swift                # Domain error enum
├── Apps/
│   ├── App.swift                      # Rich domain model
│   └── AppRepository.swift            # @Mockable protocol
├── Builds/
│   ├── Build.swift                    # Rich domain model
│   └── BuildRepository.swift          # @Mockable protocol
├── TestFlight/
│   ├── BetaGroup.swift
│   ├── BetaTester.swift
│   └── TestFlightRepository.swift     # @Mockable protocol
├── Shared/
│   ├── PaginatedResponse.swift        # Generic pagination model
│   ├── OutputFormat.swift             # json | table | markdown enum
│   └── APIError.swift                 # Domain error types

Key patterns (following claudebar)

@Mockable protocols in Domain:
@Mockable
public protocol AppRepository: Sendable {
func listApps(limit: Int?) async throws -> PaginatedResponse<App>
func getApp(id: String) async throws -> App
}

@Mockable
public protocol AuthProvider: Sendable {
func resolve() throws -> AuthCredentials
}

Rich domain models:
public struct App: Sendable, Codable {
public let id: String
public let name: String
public let bundleId: String
public let sku: String?
public let primaryLocale: String?
// Domain behavior methods here
}

Tests (written FIRST)

Tests/DomainTests/
├── Apps/
│   ├── AppTests.swift
│   └── AppRepositoryTests.swift
├── Builds/
│   └── BuildTests.swift
├── Auth/
│   └── AuthCredentialsTests.swift
└── Shared/
└── PaginatedResponseTests.swift

Test naming convention (backtick pattern from claudebar):
@Suite
struct AppTests {
@Test
func `app has correct bundle id`() { ... }

     @Test
     func `app display name falls back to bundle id when name is empty`() { ... }
}

 ---
Step 4: Infrastructure layer (TDD)

Implements Domain protocols using the generated OpenAPI client.

Directory structure

Sources/Infrastructure/
├── openapi.json                           # Apple's OpenAPI spec
├── openapi-generator-config.yaml          # Generator config
├── Auth/
│   ├── JWTTokenGenerator.swift            # ES256 JWT creation (swift-crypto)
│   ├── JWTMiddleware.swift                # ClientMiddleware for bearer token
│   ├── PrivateKeyLoader.swift             # .p8 file loading
│   └── EnvironmentAuthProvider.swift      # Resolves creds from env vars
├── Apps/
│   └── OpenAPIAppRepository.swift         # Implements AppRepository using generated Client
├── Builds/
│   └── OpenAPIBuildRepository.swift       # Implements BuildRepository
├── TestFlight/
│   └── OpenAPITestFlightRepository.swift  # Implements TestFlightRepository
└── Client/
└── ClientFactory.swift                # Wires Client + JWTMiddleware + URLSession

Tests

Tests/InfrastructureTests/
├── Auth/
│   ├── JWTTokenGeneratorTests.swift
│   ├── PrivateKeyLoaderTests.swift
│   └── EnvironmentAuthProviderTests.swift
├── Apps/
│   └── OpenAPIAppRepositoryTests.swift    # Uses MockAuthProvider from Mockable
└── Client/
└── ClientFactoryTests.swift

 ---
Step 5: CLI layer (ASCCommand)

Directory structure

Sources/ASCCommand/
├── ASC.swift                    # @main root ParsableCommand
├── GlobalOptions.swift          # --output, --pretty, --timeout
├── ClientProvider.swift         # Builds authenticated client from env/config
├── OutputFormatter.swift        # JSON/table/markdown rendering
├── Commands/
│   ├── Apps/
│   │   ├── AppsCommand.swift    # `asc apps` group
│   │   └── AppsList.swift       # `asc apps list`
│   ├── Builds/
│   │   ├── BuildsCommand.swift
│   │   └── BuildsList.swift
│   ├── TestFlight/
│   │   └── TestFlightCommand.swift
│   ├── Auth/
│   │   └── AuthCommand.swift
│   └── Version/
│       └── VersionCommand.swift

All subcommands use AsyncParsableCommand, explicit long flags only (--app, --output), JSON-first output.

 ---
Step 6: Makefile and supporting files

Create Makefile with: build, test, lint, format, download-spec, clean, dev, run

Create Scripts/download-spec.sh for OpenAPI spec download.

Create .gitignore for Swift/SPM.

 ---
Implementation Sequence (TDD flow)

1. Create skeleton: Package.swift, directory structure, .gitignore
2. Download OpenAPI spec and verify build plugin generates code
3. Domain layer TDD: Write failing tests first → implement models and protocols
4. Infrastructure auth TDD: Write JWT tests first → implement JWTTokenGenerator, PrivateKeyLoader, JWTMiddleware
5. Infrastructure repositories TDD: Write repository tests with Mockable → implement OpenAPI-backed repositories
6. CLI scaffolding: Root command, GlobalOptions, OutputFormatter
7. CLI commands TDD: Write command tests → implement apps list, builds list, etc.
8. Polish: Makefile, README, scripts

 ---
Verification

# Build
swift build

# Run tests
swift test

# Run CLI
swift run asc --help
swift run asc apps list --output json

# With auth (requires real credentials)
ASC_KEY_ID=xxx ASC_ISSUER_ID=xxx ASC_PRIVATE_KEY_PATH=~/.asc/key.p8 \
swift run asc apps list

 ---
Key Files from Reference Projects

- claudebar structure: /Users/hanrenwei/github/tddworks/claudebar/Sources/ (Domain/Infrastructure/App layering, @Mockable usage, backtick test names, MockRepositoryFactory pattern)
- Existing Go CLI auth: /Users/hanrenwei/github/learning/App-Store-Connect-CLI/internal/asc/ (JWT claims structure for App Store Connect)
- OpenAPI spec: /Users/hanrenwei/github/learning/App-Store-Connect-CLI/docs/openapi/latest.json (fallback if Apple download differs)

Risks
┌────────────────────────────────────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────┐
│                                Risk                                │                                    Mitigation                                     │
├────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Full spec compile time (6.4MB → potentially 200K+ lines generated) │ If too slow, switch to pre-generated committed code or add filter: tags to config │
├────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ OpenAPI spec compatibility issues                                  │ Keep download script; apply patches if needed                                     │
├────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
│ Generated API names may be awkward                                 │ Thin facade in repository implementations                                         │
└────────────────────────────────────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────┘
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
