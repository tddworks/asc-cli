import Foundation
import Mockable

/// A plugin installed in `~/.asc/plugins` that loads, with what its manifest says.
struct InstalledPlugin: Equatable, Sendable {
    let slug: String
    let name: String
    let uiScripts: [String]
    let version: String?
    let description: String?
    let author: String?
    let repositoryURL: String?
    let categories: [String]?
}

/// A `.plugin` bundle in the plugins folder, whether or not it loads.
struct PluginBundle: Equatable, Sendable {
    let slug: String
    let manifestName: String?
}

/// The plugins folder, `~/.asc/plugins`.
@Mockable
protocol PluginsFolder: Sendable {
    /// The plugins that load, with their manifests.
    func installed() -> [InstalledPlugin]
    /// Every `.plugin` bundle in the folder.
    func bundles() -> [PluginBundle]
    /// Unpacks a downloaded plugin archive into the folder; `false` when it doesn't unpack.
    func unpack(_ archive: Data, named name: String) throws -> Bool
    /// Removes the bundle `<slug>.plugin`.
    func remove(slug: String) throws
}

/// Where plugin archives are downloaded from.
@Mockable
protocol PluginDownloads: Sendable {
    func download(from url: URL) async throws -> Data
}
