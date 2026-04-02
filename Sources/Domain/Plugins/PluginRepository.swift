import Mockable

/// Manages installed dylib plugins and the plugin marketplace.
@Mockable
public protocol PluginRepository: Sendable {
    func listInstalled() async throws -> [Plugin]
    func listAvailable() async throws -> [MarketPlugin]
    func searchAvailable(query: String) async throws -> [MarketPlugin]
    func install(name: String) async throws -> Plugin
    func uninstall(name: String) async throws
}
