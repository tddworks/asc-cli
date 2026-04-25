/// A plugin — either installed locally or available in the marketplace.
///
/// Installed plugins are discovered from `~/.asc/plugins/` manifest.json.
/// Marketplace plugins are fetched from a registry (e.g. GitHub).
/// The `isInstalled` flag and presence of `slug`/`uiScripts` distinguish them.
public struct Plugin: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String?
    public let repositoryURL: String?
    public let categories: [String]
    public let downloadURL: String?
    public let isInstalled: Bool
    public let slug: String?         // URL-safe directory name (installed plugins only)
    public let uiScripts: [String]

    public init(
        id: String,
        name: String,
        version: String,
        description: String = "",
        author: String? = nil,
        repositoryURL: String? = nil,
        categories: [String] = [],
        downloadURL: String? = nil,
        isInstalled: Bool = false,
        slug: String? = nil,
        uiScripts: [String] = []
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.repositoryURL = repositoryURL
        self.categories = categories
        self.downloadURL = downloadURL
        self.isInstalled = isInstalled
        self.slug = slug
        self.uiScripts = uiScripts
    }
}

extension Plugin: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, version, description, author, repositoryURL, categories
        case downloadURL, isInstalled, slug, uiScripts
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        version = try c.decode(String.self, forKey: .version)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        author = try c.decodeIfPresent(String.self, forKey: .author)
        repositoryURL = try c.decodeIfPresent(String.self, forKey: .repositoryURL)
        categories = try c.decodeIfPresent([String].self, forKey: .categories) ?? []
        downloadURL = try c.decodeIfPresent(String.self, forKey: .downloadURL)
        isInstalled = try c.decodeIfPresent(Bool.self, forKey: .isInstalled) ?? false
        slug = try c.decodeIfPresent(String.self, forKey: .slug)
        uiScripts = try c.decodeIfPresent([String].self, forKey: .uiScripts) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(version, forKey: .version)
        try c.encode(description, forKey: .description)
        try c.encodeIfPresent(author, forKey: .author)
        try c.encodeIfPresent(repositoryURL, forKey: .repositoryURL)
        try c.encode(categories, forKey: .categories)
        try c.encodeIfPresent(downloadURL, forKey: .downloadURL)
        try c.encode(isInstalled, forKey: .isInstalled)
        try c.encodeIfPresent(slug, forKey: .slug)
        try c.encode(uiScripts, forKey: .uiScripts)
    }
}

extension Plugin: Presentable {
    public static var tableHeaders: [String] {
        ["Name", "Version", "Author", "Description"]
    }
    public var tableRow: [String] {
        [name, version, author ?? "-", description]
    }
}

extension Plugin: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "browseMarket": "asc plugins market list",
        ]
        if isInstalled {
            cmds["uninstall"] = "asc plugins uninstall --name \(slug ?? id)"
            cmds["checkUpdate"] = "asc plugins updates"
        } else {
            cmds["install"] = "asc plugins install --name \(id)"
        }
        if let repositoryURL {
            cmds["viewRepository"] = repositoryURL
        }
        return cmds
    }
}
