import ArgumentParser
import ASCKit

struct IrisAppsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all apps"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        let repo = ClientProvider.makeIrisAppBundles()
        print(try await execute(cookieProvider: cookieProvider, repo: repo))
    }

    func execute(
        cookieProvider: any IrisCookieProvider,
        repo: any IrisAppBundles
    ) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let apps = try await repo.listAppBundles(session: session)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(apps)
    }
}
