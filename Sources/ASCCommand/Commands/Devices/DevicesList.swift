import ArgumentParser
import Domain

struct DevicesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List registered test devices"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by platform (ios, macos)")
    var platform: String?

    func run() async throws {
        let repo = try ClientProvider.makeDeviceRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any DeviceRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let domainPlatform = platform.flatMap { BundleIDPlatform(cliArgument: $0) }
        let items = try await repo.listDevices(platform: domainPlatform)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
