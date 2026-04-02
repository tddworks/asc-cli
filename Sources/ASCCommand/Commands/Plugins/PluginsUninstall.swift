import ArgumentParser
import Domain

struct PluginsUninstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall a plugin"
    )

    @Option(name: .long, help: "Plugin name to uninstall")
    var name: String

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any PluginRepository) async throws {
        try await repo.uninstall(name: name)
        print("Plugin '\(name)' uninstalled successfully.")
    }
}
