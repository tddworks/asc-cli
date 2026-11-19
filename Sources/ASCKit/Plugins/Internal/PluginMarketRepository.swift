import Foundation

/// Manages installed plugins and the marketplace listings from composable sources.
public struct PluginMarketRepository: PluginRepository {
    private let sources: [any PluginSource]
    private let folder: any PluginsFolder
    private let downloads: any PluginDownloads

    public init(sources: [any PluginSource] = []) {
        self.init(sources: sources, folder: LocalPluginsFolder(), downloads: URLSessionPluginDownloads())
    }

    init(sources: [any PluginSource], folder: any PluginsFolder, downloads: any PluginDownloads) {
        self.sources = sources
        self.folder = folder
        self.downloads = downloads
    }

    public func listInstalled() async throws -> [Plugin] {
        folder.installed().map { p in
            Plugin(
                id: p.slug,
                name: p.name,
                version: p.version ?? "1.0",
                description: p.description ?? "",
                author: p.author,
                repositoryURL: p.repositoryURL,
                categories: p.categories ?? [],
                isInstalled: true,
                slug: p.slug,
                uiScripts: p.uiScripts
            )
        }
    }

    public func listAvailable() async throws -> [Plugin] {
        let installedIds = Set(folder.installed().flatMap { p in
            [p.slug, p.slug.lowercased(), Self.id(forName: p.name)]
        })

        var all: [Plugin] = []
        for source in sources {
            let plugins = try await source.fetchPlugins()
            all.append(contentsOf: plugins.map { plugin in
                Plugin(
                    id: plugin.id,
                    name: plugin.name,
                    version: plugin.version,
                    description: plugin.description,
                    author: plugin.author,
                    repositoryURL: plugin.repositoryURL,
                    categories: plugin.categories,
                    downloadURL: plugin.downloadURL,
                    isInstalled: installedIds.contains(plugin.id) || installedIds.contains(plugin.id.lowercased())
                )
            })
        }
        return all
    }

    public func searchAvailable(query: String) async throws -> [Plugin] {
        let q = query.lowercased()
        return try await listAvailable().filter {
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
        let archive = try await downloads.download(from: URL(string: downloadURL)!)
        guard try folder.unpack(archive, named: name) else {
            throw PluginMarketError.installFailed(name)
        }
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

    /// Removes the plugin whose folder is `name`, or else whose folder or manifest
    /// name, as an id (`"ASC Pro"` → `asc-pro`), is `name` ignoring case.
    public func uninstall(name: String) async throws {
        let bundles = folder.bundles()
        let wanted = name.lowercased()
        let match = bundles.first { $0.slug == name }
            ?? bundles.first { $0.slug.lowercased() == wanted || $0.manifestName.map(Self.id(forName:)) == wanted }
        guard let match else {
            throw PluginMarketError.pluginNotFound(name)
        }
        try folder.remove(slug: match.slug)
    }

    public func listOutdated() async throws -> [PluginUpdate] {
        let installed = try await listInstalled()
        var availableByName: [String: Plugin] = [:]
        for plugin in try await listAvailable() {
            availableByName[plugin.name] = plugin
        }
        return installed.compactMap { local in
            guard let remote = availableByName[local.name],
                  remote.version != local.version else { return nil }
            return PluginUpdate(
                name: local.name,
                installedVersion: local.version,
                latestVersion: remote.version,
                repositoryURL: remote.repositoryURL ?? local.repositoryURL,
                downloadURL: remote.downloadURL
            )
        }
    }

    public func update(name: String) async throws -> Plugin {
        let installed = try await listInstalled()
        guard let local = installed.first(where: { $0.name == name || $0.slug == name || $0.id == name }) else {
            throw PluginMarketError.pluginNotFound(name)
        }
        guard let remote = try await listAvailable().first(where: { $0.name == local.name }) else {
            throw PluginMarketError.pluginNotFound(local.name)
        }
        try await uninstall(name: local.slug ?? local.id)
        return try await install(name: remote.id)
    }

    /// A plugin's name as a marketplace id: `"ASC Pro"` → `asc-pro`.
    private static func id(forName name: String) -> String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
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
