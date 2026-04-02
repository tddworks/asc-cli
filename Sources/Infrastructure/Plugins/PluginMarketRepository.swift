import Domain
import Foundation
import ASCPlugin

/// Manages installed dylib plugins and fetches marketplace listings from a remote registry.
public struct PluginMarketRepository: PluginRepository {

    public init() {}

    public func listInstalled() async throws -> [Plugin] {
        PluginLoader.discover().map { loaded in
            Plugin(
                id: loaded.slug,
                name: loaded.name,
                version: "1.0",
                slug: loaded.slug,
                uiScripts: loaded.uiScripts
            )
        }
    }

    public func listAvailable() async throws -> [MarketPlugin] {
        // TODO: fetch from remote registry
        []
    }

    public func searchAvailable(query: String) async throws -> [MarketPlugin] {
        let all = try await listAvailable()
        let q = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(q) ||
            $0.description.lowercased().contains(q) ||
            $0.categories.contains(where: { $0.lowercased().contains(q) })
        }
    }

    public func install(name: String) async throws -> Plugin {
        // TODO: download and extract .plugin bundle
        throw PluginMarketError.notImplemented
    }

    public func uninstall(name: String) async throws {
        let pluginsDir = PluginLoader.pluginsDirectory
        let bundlePath = pluginsDir.appendingPathComponent("\(name).plugin")
        guard FileManager.default.fileExists(atPath: bundlePath.path) else {
            throw PluginMarketError.pluginNotFound(name)
        }
        try FileManager.default.removeItem(at: bundlePath)
    }
}

enum PluginMarketError: Error, CustomStringConvertible {
    case pluginNotFound(String)
    case notImplemented

    var description: String {
        switch self {
        case .pluginNotFound(let name): "Plugin not found: \(name)"
        case .notImplemented: "Not implemented yet"
        }
    }
}
