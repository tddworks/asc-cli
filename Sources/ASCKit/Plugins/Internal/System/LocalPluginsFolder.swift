import ASCPlugin
import Foundation

/// `~/.asc/plugins` on this Mac. Only the file system, `PluginLoader` and `unzip`
/// calls live here; which plugin matches is `MarketplacePlugins`'s.
struct LocalPluginsFolder: PluginsFolder {
    func installed() -> [InstalledPlugin] {
        PluginLoader.discover().map { plugin in
            let manifest = Self.manifest(in: plugin.directory)
            return InstalledPlugin(
                slug: plugin.slug, name: plugin.name, uiScripts: plugin.uiScripts,
                version: manifest?["version"] as? String,
                description: manifest?["description"] as? String,
                author: manifest?["author"] as? String,
                repositoryURL: manifest?["repositoryURL"] as? String,
                categories: manifest?["categories"] as? [String]
            )
        }
    }

    func bundles() -> [PluginBundle] {
        let folder = PluginLoader.pluginsDirectory
        let entries = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        return entries.filter { $0.hasSuffix(".plugin") }.map { entry in
            PluginBundle(
                slug: (entry as NSString).deletingPathExtension,
                manifestName: Self.manifest(in: folder.appendingPathComponent(entry))?["name"] as? String
            )
        }
    }

    func unpack(_ archive: Data, named name: String) throws -> Bool {
        let folder = PluginLoader.pluginsDirectory
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        let zip = temp.appendingPathComponent("\(name).zip")
        try archive.write(to: zip)

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-o", zip.path, "-d", folder.path]
        try unzip.run()
        unzip.waitUntilExit()
        // The next `installed()` re-scans the folder and sees the new bundle.
        PluginLoader.invalidateCache()
        return unzip.terminationStatus == 0
    }

    func remove(slug: String) throws {
        try FileManager.default.removeItem(at: PluginLoader.pluginsDirectory.appendingPathComponent("\(slug).plugin"))
        PluginLoader.invalidateCache()
    }

    private static func manifest(in directory: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent("manifest.json")) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

/// Downloads plugin archives with `URLSession`.
struct URLSessionPluginDownloads: PluginDownloads {
    func download(from url: URL) async throws -> Data {
        try await URLSession.shared.data(from: url).0
    }
}
