import Domain
import Foundation
import ASCPlugin

/// Manages installed dylib plugins and fetches marketplace listings from composable sources.
public struct PluginMarketRepository: PluginRepository {
    private let sources: [any PluginSource]

    public init(sources: [any PluginSource] = []) {
        self.sources = sources
    }

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
        let installed = PluginLoader.discover()
        let installedIds = Set(
            installed.flatMap { p in
                // Match by slug ("ASCPro"), lowercased slug ("ascpro"),
                // and name-derived id ("asc-pro") to handle registry ID variations
                [p.slug, p.slug.lowercased(), p.name.lowercased().replacingOccurrences(of: " ", with: "-")]
            }
        )

        var all: [MarketPlugin] = []
        for source in sources {
            let plugins = try await source.fetchPlugins()
            all.append(contentsOf: plugins.map { plugin in
                let matched = installedIds.contains(plugin.id) || installedIds.contains(plugin.id.lowercased())
                return MarketPlugin(
                    id: plugin.id,
                    name: plugin.name,
                    version: plugin.version,
                    description: plugin.description,
                    author: plugin.author,
                    repositoryURL: plugin.repositoryURL,
                    downloadURL: plugin.downloadURL,
                    categories: plugin.categories,
                    isInstalled: matched
                )
            })
        }
        return all
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
        let available = try await listAvailable()
        guard let entry = available.first(where: { $0.id == name }) else {
            throw PluginMarketError.pluginNotFound(name)
        }

        let pluginsDir = PluginLoader.pluginsDirectory
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        let zipURL = URL(string: entry.downloadURL)!
        let (zipData, _) = try await URLSession.shared.data(from: zipURL)

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let zipPath = tempDir.appendingPathComponent("\(name).zip")
        try zipData.write(to: zipPath)

        // Extract zip to plugins directory
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipPath.path, "-d", pluginsDir.path]
        try process.run()
        process.waitUntilExit()

        try? FileManager.default.removeItem(at: tempDir)

        guard process.terminationStatus == 0 else {
            throw PluginMarketError.installFailed(name)
        }

        return Plugin(
            id: name,
            name: entry.name,
            version: entry.version,
            slug: name,
            uiScripts: []
        )
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
    case installFailed(String)

    var description: String {
        switch self {
        case .pluginNotFound(let name): "Plugin not found: \(name)"
        case .installFailed(let name): "Failed to install plugin: \(name)"
        }
    }
}
