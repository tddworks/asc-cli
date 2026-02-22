import ArgumentParser
import Domain

struct ScreenshotSetsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new screenshot set for a localization"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Localization ID")
    var localizationId: String

    @Option(name: .long, help: "Screenshot display type (e.g. APP_IPHONE_67)")
    var displayType: String

    func run() async throws {
        let repo = try ClientProvider.makeScreenshotRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotRepository) async throws -> String {
        guard let screenshotDisplayType = ScreenshotDisplayType(rawValue: displayType) else {
            throw ValidationError("Unknown display type '\(displayType)'")
        }
        let created = try await repo.createScreenshotSet(localizationId: localizationId, displayType: screenshotDisplayType)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [created],
            headers: ["ID", "Display Type", "Localization ID"],
            rowMapper: { [$0.id, $0.displayTypeName, $0.localizationId] }
        )
    }
}
