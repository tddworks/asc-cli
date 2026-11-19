import ArgumentParser
import ASCKit
import Foundation

struct BuildsArchive: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "archive",
        abstract: "Archive and export an Xcode project for App Store / TestFlight"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Xcode scheme to archive")
    var scheme: String

    @Option(name: .long, help: "Path to .xcworkspace (auto-detected if omitted)")
    var workspace: String?

    @Option(name: .long, help: "Path to .xcodeproj (auto-detected if omitted)")
    var project: String?

    @Option(name: .long, help: "Platform: ios, macos, tvos, visionos (default: ios)")
    var platform: String?

    @Option(name: .long, help: "Build configuration (default: Release)")
    var configuration: String = "Release"

    @Option(name: .long, help: "Export method: app-store-connect, ad-hoc, development, enterprise (default: app-store-connect)")
    var exportMethod: String?

    @Option(name: .long, help: "Signing style: automatic, manual (default: automatic)")
    var signingStyle: String?

    @Option(name: .long, help: "Team ID for signing")
    var teamId: String?

    @Option(name: .long, help: "Output directory for archive and export (default: .build)")
    var outputDir: String = ".build"

    // MARK: - Upload flags

    @Flag(name: .long, help: "Upload the exported IPA/PKG to App Store Connect after archiving")
    var upload: Bool = false

    @Option(name: .long, help: "App ID (required if --upload)")
    var appId: String?

    @Option(name: .long, help: "Version string (required if --upload, e.g. 1.0.0)")
    var version: String?

    @Option(name: .long, help: "Build number (required if --upload, e.g. 42)")
    var buildNumber: String?

    func run() async throws {
        let runner = ClientProvider.makeXcodeBuildRunner()
        let uploadRepo = upload ? try ClientProvider.makeBuildUploadRepository() : nil
        print(try await execute(runner: runner, uploadRepo: uploadRepo))
    }

    func execute(
        runner: any XcodeBuildRunner,
        uploadRepo: (any BuildUploadRepository)? = nil
    ) async throws -> String {
        // Resolve platform
        let resolvedPlatform: BuildUploadPlatform
        if let platformArg = platform {
            guard let p = BuildUploadPlatform(cliArgument: platformArg) else {
                throw ValidationError("Unknown platform: \(platformArg). Use: ios, macos, tvos, visionos")
            }
            resolvedPlatform = p
        } else {
            resolvedPlatform = .iOS
        }

        // Resolve export method
        let resolvedMethod: ExportMethod
        if let methodArg = exportMethod {
            guard let m = ExportMethod(cliArgument: methodArg) else {
                throw ValidationError("Unknown export method: \(methodArg). Use: app-store-connect, ad-hoc, development, enterprise")
            }
            resolvedMethod = m
        } else {
            resolvedMethod = .appStoreConnect
        }

        // Resolve signing style
        let resolvedSigningStyle: SigningStyle
        if let styleArg = signingStyle {
            guard let s = SigningStyle(rawValue: styleArg) else {
                throw ValidationError("Unknown signing style: \(styleArg). Use: automatic, manual")
            }
            resolvedSigningStyle = s
        } else {
            resolvedSigningStyle = .automatic
        }

        // Resolve workspace/project from cwd if not provided
        let resolvedWorkspace = workspace ?? detectWorkspace()
        let resolvedProject = (resolvedWorkspace == nil) ? (project ?? detectProject()) : project

        let archivePath = "\(outputDir)/\(scheme).xcarchive"
        let exportPath = "\(outputDir)/export"

        // Step 1: Archive
        let archiveRequest = ArchiveRequest(
            scheme: scheme,
            workspace: resolvedWorkspace,
            project: resolvedProject,
            platform: resolvedPlatform,
            configuration: configuration,
            archivePath: archivePath
        )
        _ = try await runner.archive(request: archiveRequest)

        // Step 2: Export
        let exportRequest = ExportRequest(
            archivePath: archivePath,
            exportPath: exportPath,
            method: resolvedMethod,
            signingStyle: resolvedSigningStyle,
            teamId: teamId
        )
        let exportResult = try await runner.exportArchive(request: exportRequest)

        // Step 3: Optionally upload
        if upload {
            guard let appId = appId else {
                throw ValidationError("--app-id is required when using --upload")
            }
            guard let version = version else {
                throw ValidationError("--version is required when using --upload")
            }
            guard let buildNumber = buildNumber else {
                throw ValidationError("--build-number is required when using --upload")
            }

            let repo = uploadRepo!
            let uploadResult = try await repo.uploadBuild(
                appId: appId,
                version: version,
                buildNumber: buildNumber,
                platform: resolvedPlatform,
                fileURL: URL(fileURLWithPath: exportResult.ipaPath)
            )

            let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
            return try formatter.formatAgentItems(
                [uploadResult],
                headers: ["ID", "Version", "Build", "Platform", "State"],
                rowMapper: { [$0.id, $0.version, $0.buildNumber, $0.platform.rawValue, $0.state.rawValue] }
            )
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [exportResult],
            headers: ["IPA Path", "Export Path"],
            rowMapper: { [$0.ipaPath, $0.exportPath] }
        )
    }

    // MARK: - Auto-detection

    private func detectWorkspace() -> String? {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: fm.currentDirectoryPath) else { return nil }
        return contents.first { $0.hasSuffix(".xcworkspace") }
    }

    private func detectProject() -> String? {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: fm.currentDirectoryPath) else { return nil }
        return contents.first { $0.hasSuffix(".xcodeproj") }
    }
}
