import Mockable

/// Manages installed dylib plugins and the plugin marketplace.
@Mockable
public protocol PluginRepository: Sendable {
    func listInstalled() async throws -> [Plugin]
    func listAvailable() async throws -> [Plugin]
    func searchAvailable(query: String) async throws -> [Plugin]
    func install(name: String) async throws -> Plugin
    func uninstall(name: String) async throws
    /// Diff installed plugins against the marketplace; emit one entry per outdated plugin.
    func listOutdated() async throws -> [PluginUpdate]
    /// Reinstall the named plugin with the latest marketplace version.
    func update(name: String) async throws -> Plugin
}
