import ArgumentParser
import Domain

struct IrisAppsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all apps"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let cookieProvider = ClientProvider.makeIrisCookieProvider()
        let repo = ClientProvider.makeIrisAppBundleRepository()
        print(try await execute(cookieProvider: cookieProvider, repo: repo))
    }

    func execute(
        cookieProvider: any IrisCookieProvider,
        repo: any IrisAppBundleRepository
    ) async throws -> String {
        let session = try cookieProvider.resolveSession()
        let apps = try await repo.listAppBundles(session: session)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(apps)
    }
}
