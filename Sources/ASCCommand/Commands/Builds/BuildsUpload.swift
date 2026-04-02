import ArgumentParser
import Domain
import Foundation

struct BuildsUpload: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload an IPA or PKG to App Store Connect"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Path to .ipa (iOS/tvOS/visionOS) or .pkg (macOS) file")
    var file: String

    @Option(name: .long, help: "CFBundleShortVersionString (e.g. 1.0.0)")
    var version: String

    @Option(name: .long, help: "CFBundleVersion build number (e.g. 42)")
    var buildNumber: String

    @Option(name: .long, help: "Platform: ios, macos, tvos, visionos (auto-detected from file extension)")
    var platform: String?

    @Flag(name: .long, help: "Poll until build processing completes")
    var wait: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeBuildUploadRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any BuildUploadRepository) async throws -> String {
        let fileURL = URL(fileURLWithPath: file)

        let resolvedPlatform: BuildUploadPlatform
        if let platformArg = platform {
            guard let p = BuildUploadPlatform(cliArgument: platformArg) else {
                throw ValidationError("Unknown platform: \(platformArg). Use: ios, macos, tvos, visionos")
            }
            resolvedPlatform = p
        } else {
            resolvedPlatform = fileURL.pathExtension.lowercased() == "pkg" ? .macOS : .iOS
        }

        var upload = try await repo.uploadBuild(
            appId: appId,
            version: version,
            buildNumber: buildNumber,
            platform: resolvedPlatform,
            fileURL: fileURL
        )

        if wait {
            upload = try await poll(uploadId: upload.id, repo: repo)
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [upload],
            headers: ["ID", "Version", "Build", "Platform", "State"],
            rowMapper: { [$0.id, $0.version, $0.buildNumber, $0.platform.rawValue, $0.state.rawValue] }
        )
    }

    private func poll(uploadId: String, repo: any BuildUploadRepository) async throws -> BuildUpload {
        while true {
            let upload = try await repo.getBuildUpload(id: uploadId)
            if upload.state.hasFailed {
                let details = upload.errors.map { "[\($0.code)] \($0.description)" }.joined(separator: "\n")
                throw ValidationError(
                    details.isEmpty
                        ? "Build upload failed (upload-id: \(uploadId))"
                        : "Build upload failed:\n\(details)"
                )
            }
            if !upload.state.isPending { return upload }
            try await Task.sleep(nanoseconds: 10_000_000_000)
        }
    }
}
