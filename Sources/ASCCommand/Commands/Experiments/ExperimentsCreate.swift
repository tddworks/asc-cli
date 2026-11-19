import ArgumentParser
import ASCKit

struct ExperimentsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a product page optimization test"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    @Option(name: .long, help: "Reference name shown in App Analytics")
    var name: String

    @Option(name: .long, help: "Platform: ios, macos, tvos, visionos")
    var platform: String = "ios"

    @Option(name: .long, help: "Percentage of users (1-100) shown a treatment instead of the original page")
    var trafficProportion: Int

    func run() async throws {
        let repo = try ClientProvider.makeExperiments()
        print(try await execute(repo: repo))
    }

    func execute(
        repo: any Experiments,
        affordanceMode: AffordanceMode = .cli
    ) async throws -> String {
        guard let appStorePlatform = AppStorePlatform(cliArgument: platform) else {
            throw ValidationError("Unknown platform '\(platform)'. Use: ios, macos, tvos, visionos")
        }
        guard (1...100).contains(trafficProportion) else {
            throw ValidationError("--traffic-proportion must be between 1 and 100")
        }
        let created = try await repo.createExperiment(
            appId: appId, name: name, platform: appStorePlatform, trafficProportion: trafficProportion
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems([created], affordanceMode: affordanceMode)
    }
}
