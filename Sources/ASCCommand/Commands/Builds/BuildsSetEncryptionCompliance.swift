import ArgumentParser
import Domain

struct BuildsSetEncryptionCompliance: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set-encryption-compliance",
        abstract: "Set Apple's export-compliance answer (Info.plist ITSAppUsesNonExemptEncryption) on a build"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Build ID")
    var buildId: String

    @Option(name: .long, help: "Whether the build uses non-exempt encryption (true|false)")
    var usesNonExemptEncryption: Bool

    func run() async throws {
        let repo = try ClientProvider.makeBuildRepository()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any BuildRepository,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        let build = try await repo.updateBuildEncryptionCompliance(
            buildId: buildId,
            usesNonExemptEncryption: usesNonExemptEncryption
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [build],
            headers: Build.tableHeaders,
            rowMapper: { $0.tableRow },
            affordanceMode: affordanceMode
        )
    }
}
