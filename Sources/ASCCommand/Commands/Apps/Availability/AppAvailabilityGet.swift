import Foundation
import ArgumentParser
import ASCKit

struct AppAvailabilityGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get territory availability for an app with per-territory status"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID to get availability for")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeAppAvailabilityRepository()
        let output = try await execute(repo: repo)
        print(output)
        if output.contains("\"data\" : [\n\n  ]") || output.contains("\"data\":[]") {
            FileHandle.standardError.write(Data((
                "App availability isn't set up. Set it up with: "
                + "asc app-availability create --app-id \(appId) --all-territories --available-in-new-territories\n"
            ).utf8))
        }
    }

    func execute(repo: any AppAvailabilityRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let availability = try await repo.getAppAvailability(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        // nil → empty data array: availability was never set up (mirrors `iap-availability get`).
        return try formatter.formatAgentItems(availability.map { [$0] } ?? [], affordanceMode: affordanceMode)
    }
}
