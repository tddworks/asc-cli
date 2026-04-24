import ArgumentParser
import Domain

struct AppsUpdate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update app-level metadata (currently: content rights declaration)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(
        name: .long,
        help: "Content rights declaration: USES_THIRD_PARTY_CONTENT or DOES_NOT_USE_THIRD_PARTY_CONTENT"
    )
    var contentRightsDeclaration: String?

    func run() async throws {
        let repo = try ClientProvider.makeAppRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let declaration = try validateDeclaration()
        let updated = try await repo.updateContentRights(appId: appId, declaration: declaration)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [updated],
            headers: ["ID", "Name", "Bundle ID", "Content Rights"],
            rowMapper: { [$0.id, $0.displayName, $0.bundleId, $0.contentRightsDeclaration?.rawValue ?? "-"] },
            affordanceMode: affordanceMode
        )
    }

    /// Validates the --content-rights-declaration flag and returns the parsed enum,
    /// or nil when the flag was omitted (no-op update).
    func validateDeclaration() throws -> ContentRightsDeclaration? {
        guard let raw = contentRightsDeclaration else { return nil }
        guard let declaration = ContentRightsDeclaration(rawValue: raw) else {
            throw ValidationError(
                "Unknown content-rights-declaration '\(raw)'. Use USES_THIRD_PARTY_CONTENT or DOES_NOT_USE_THIRD_PARTY_CONTENT"
            )
        }
        return declaration
    }
}
