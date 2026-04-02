import ArgumentParser

struct PluginsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "plugins",
        abstract: "Manage installed plugins and browse the plugin marketplace",
        subcommands: [
            PluginsList.self,
            PluginsInstall.self,
            PluginsUninstall.self,
            PluginsMarket.self,
        ]
    )
}
