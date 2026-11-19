import ArgumentParser
import ASCKit

struct IrisAppComplianceList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List every App Compliance requirement for an app, answered or not"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        print(try await execute(cookieProvider: ClientProvider.makeIrisCookieProvider(), repo: ClientProvider.makeIrisComplianceRepository()))
    }

    func execute(cookieProvider: any IrisCookieProvider, repo: any IrisComplianceRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let rows = try await repo.listRequirements(session: try cookieProvider.resolveSession(), appId: appId)
        return try OutputFormatter(format: globals.outputFormat, pretty: globals.pretty).formatAgentItems(rows, affordanceMode: affordanceMode)
    }
}
