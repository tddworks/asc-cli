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
        let loaded = PluginLoader.discover()
        return loaded.map { p in
            let manifest = readManifest(at: p.directory)
            return Plugin(
                id: p.slug,
                name: p.name,
                version: manifest?["version"] as? String ?? "1.0",
                description: manifest?["description"] as? String ?? "",
                author: manifest?["author"] as? String,
                repositoryURL: manifest?["repositoryURL"] as? String,
                categories: manifest?["categories"] as? [String] ?? [],
                isInstalled: true,
                slug: p.slug,
                uiScripts: p.uiScripts
            )
        }
    }

    public func listAvailable() async throws -> [Plugin] {
        let installed = PluginLoader.discover()
        let installedIds = Set(
            installed.flatMap { p in
                [p.slug, p.slug.lowercased(), p.name.lowercased().replacingOccurrences(of: " ", with: "-")]
            }
        )

        var all: [Plugin] = []
        for source in sources {
            let plugins = try await source.fetchPlugins()
            all.append(contentsOf: plugins.map { plugin in
                let matched = installedIds.contains(plugin.id) || installedIds.contains(plugin.id.lowercased())
                return Plugin(
                    id: plugin.id,
                    name: plugin.name,
                    version: plugin.version,
                    description: plugin.description,
                    author: plugin.author,
                    repositoryURL: plugin.repositoryURL,
                    categories: plugin.categories,
                    downloadURL: plugin.downloadURL,
                    isInstalled: matched
                )
            })
        }
        return all
    }

    public func searchAvailable(query: String) async throws -> [Plugin] {
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
        guard let entry = available.first(where: { $0.id == name }),
              let downloadURL = entry.downloadURL else {
            throw PluginMarketError.pluginNotFound(name)
        }

        let pluginsDir = PluginLoader.pluginsDirectory
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        let zipURL = URL(string: downloadURL)!
        let (zipData, _) = try await URLSession.shared.data(from: zipURL)

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let zipPath = tempDir.appendingPathComponent("\(name).zip")
        try zipData.write(to: zipPath)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipPath.path, "-d", pluginsDir.path]
        try process.run()
        process.waitUntilExit()

        try? FileManager.default.removeItem(at: tempDir)

        guard process.terminationStatus == 0 else {
            throw PluginMarketError.installFailed(name)
        }

        // Drop the in-memory plugin cache so the next `listInstalled()`
        // re-scans `~/.asc/plugins` and includes the new bundle.
        PluginLoader.invalidateCache()

        return Plugin(
            id: name,
            name: entry.name,
            version: entry.version,
            description: entry.description,
            author: entry.author,
            repositoryURL: entry.repositoryURL,
            categories: entry.categories,
            isInstalled: true,
            slug: name
        )
    }

    public func uninstall(name: String) async throws {
        let pluginsDir = PluginLoader.pluginsDirectory
        // Try exact match first (slug like "ASCPro"), then scan for matching plugin
        let exactPath = pluginsDir.appendingPathComponent("\(name).plugin")
        if FileManager.default.fileExists(atPath: exactPath.path) {
            try FileManager.default.removeItem(at: exactPath)
            return
        }
        // Scan installed plugins — match by slug or name-derived id
        let nameLower = name.lowercased()
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: pluginsDir.path) else {
            throw PluginMarketError.pluginNotFound(name)
        }
        for entry in entries where entry.hasSuffix(".plugin") {
            let slug = (entry as NSString).deletingPathExtension
            let slugLower = slug.lowercased()
            // Match: exact slug, lowercased slug, or name-derived id (e.g. "asc-pro" matches "ASC Pro")
            let manifestURL = pluginsDir.appendingPathComponent(entry).appendingPathComponent("manifest.json")
            let manifestName = (try? Data(contentsOf: manifestURL))
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                .flatMap { $0["name"] as? String }
            let nameId = manifestName?.lowercased().replacingOccurrences(of: " ", with: "-")

            if slugLower == nameLower || nameId == nameLower {
                try fm.removeItem(at: pluginsDir.appendingPathComponent(entry))
                return
            }
        }
        throw PluginMarketError.pluginNotFound(name)
    }

    // MARK: - Private

    private func readManifest(at directory: URL) -> [String: Any]? {
        let manifestURL = directory.appendingPathComponent("manifest.json")
        guard let data = try? Data(contentsOf: manifestURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
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
