import ArgumentParser
import ASCKit

struct IrisStatus: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check iris cookie session status"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        print(try await execute(cookieProvider: cookieProvider))
    }

    func execute(cookieProvider: any IrisCookieProvider) async throws -> String {
        let status = try cookieProvider.resolveStatus()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [status],
            headers: ["Source", "Cookies"],
            rowMapper: { [$0.source.rawValue, "\($0.cookieCount)"] }
        )
    }
}
