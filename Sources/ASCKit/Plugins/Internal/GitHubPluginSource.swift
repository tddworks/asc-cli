import Foundation

/// Fetches available plugins from a `registry.json` hosted in a GitHub repository.
///
/// The registry URL defaults to:
///   `https://raw.githubusercontent.com/{owner}/{repo}/main/registry.json`
///
/// Default registry: `tddworks/asc-registry`
///
/// Registry format:
/// ```json
/// {
///   "plugins": [
///     {
///       "id": "asc-pro",
///       "name": "ASC Pro",
///       "version": "1.0",
///       "description": "...",
///       "author": "tddworks",
///       "repositoryURL": "https://github.com/tddworks/asc-pro",
///       "downloadURL": "https://github.com/.../ASCPro.plugin.zip",
///       "categories": ["simulators"]
///     }
///   ]
/// }
/// ```
public struct GitHubPluginSource: PluginSource {
    public let owner: String
    public let repo: String

    /// Injectable data fetcher for testing. Default uses URLSession.
    let fetcher: @Sendable (URL) async throws -> Data

    public var name: String { "GitHub: \(owner)/\(repo)" }

    public init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
        self.fetcher = { url in
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
    }

    /// Test-only initializer with injectable fetcher.
    init(owner: String, repo: String, fetcher: @escaping @Sendable (URL) async throws -> Data) {
        self.owner = owner
        self.repo = repo
        self.fetcher = fetcher
    }

    public func fetchPlugins() async throws -> [Plugin] {
        let url = URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/main/registry.json")!
        let data = try await fetcher(url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pluginsJSON = json["plugins"] else {
            return []
        }

        let pluginsData = try JSONSerialization.data(withJSONObject: pluginsJSON)
        let entries = try JSONDecoder().decode([RegistryPluginEntry].self, from: pluginsData)

        return entries.map { entry in
            Plugin(
                id: entry.id,
                name: entry.name,
                version: entry.version,
                description: entry.description,
                author: entry.author,
                repositoryURL: entry.repositoryURL,
                categories: entry.categories ?? [],
                downloadURL: entry.downloadURL,
                isInstalled: false
            )
        }
    }
}

/// Internal JSON shape for parsing registry entries.
private struct RegistryPluginEntry: Decodable {
    let id: String
    let name: String
    let version: String
    let description: String
    let author: String?
    let repositoryURL: String?
    let downloadURL: String
    let categories: [String]?
}
