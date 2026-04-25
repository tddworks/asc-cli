import ArgumentParser
import Domain
import Infrastructure

struct AuthList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all saved App Store Connect accounts"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let storage = FileAuthStorage()
        print(try await execute(storage: storage))
    }

    func execute(storage: any AuthStorage, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let accounts = try storage.loadAll()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            accounts,
            headers: ["Name", "Key ID", "Issuer ID", "Active"],
            rowMapper: { [$0.name, $0.keyID, $0.issuerID, $0.isActive ? "*" : ""] },
            affordanceMode: affordanceMode
        )
    }
}
