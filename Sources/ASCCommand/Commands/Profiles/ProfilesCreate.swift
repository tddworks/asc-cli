import ArgumentParser
import ASCKit

struct ProfilesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a provisioning profile"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Profile name")
    var name: String

    @Option(name: .long, help: "Profile type (e.g. IOS_APP_STORE, MAC_APP_STORE)")
    var type: String

    @Option(name: .long, help: "Bundle ID resource ID")
    var bundleIdId: String

    @Option(
        name: .long,
        help: "Comma-separated certificate resource IDs",
        transform: { $0.split(separator: ",").map(String.init) }
    )
    var certificateIds: [String]

    @Option(
        name: .long,
        help: "Comma-separated device resource IDs (optional, for development profiles)",
        transform: { $0.split(separator: ",").map(String.init) }
    )
    var deviceIds: [String] = []

    func run() async throws {
        let repo = try ClientProvider.makeProfileRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ProfileRepository) async throws -> String {
        guard let profileType = ProfileType(rawValue: type.uppercased()) else {
            throw ValidationError("Invalid profile type '\(type)'.")
        }
        let item = try await repo.createProfile(
            name: name,
            profileType: profileType,
            bundleIdId: bundleIdId,
            certificateIds: certificateIds,
            deviceIds: deviceIds
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Name", "Type", "State"],
            rowMapper: { [$0.id, $0.name, $0.profileType.rawValue, $0.profileState.rawValue] }
        )
    }
}
