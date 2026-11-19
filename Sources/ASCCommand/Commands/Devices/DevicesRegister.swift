import ArgumentParser
import ASCKit

struct DevicesRegister: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "register",
        abstract: "Register a test device"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Device name")
    var name: String

    @Option(name: .long, help: "Device UDID")
    var udid: String

    @Option(name: .long, help: "Platform: ios or macos")
    var platform: String

    func run() async throws {
        let repo = try ClientProvider.makeDeviceRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any DeviceRepository) async throws -> String {
        guard let domainPlatform = BundleIDPlatform(cliArgument: platform) else {
            throw ValidationError("Invalid platform '\(platform)'. Use ios or macos.")
        }
        let item = try await repo.registerDevice(name: name, udid: udid, platform: domainPlatform)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Name", "UDID", "Class", "Status"],
            rowMapper: { [$0.id, $0.name, $0.udid, $0.deviceClass.rawValue, $0.status.rawValue] }
        )
    }
}
