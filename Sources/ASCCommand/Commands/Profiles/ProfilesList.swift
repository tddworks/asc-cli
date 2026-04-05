import ArgumentParser
import Domain

struct ProfilesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List provisioning profiles"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by bundle ID resource ID")
    var bundleIdId: String?

    @Option(name: .long, help: "Filter by profile type (e.g. IOS_APP_STORE, MAC_APP_STORE)")
    var type: String?

    func run() async throws {
        let repo = try ClientProvider.makeProfileRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ProfileRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let profileType = type.flatMap { ProfileType(rawValue: $0.uppercased()) }
        let items = try await repo.listProfiles(bundleIdId: bundleIdId, profileType: profileType)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
