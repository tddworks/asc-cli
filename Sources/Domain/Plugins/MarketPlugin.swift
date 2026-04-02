/// A plugin available in the marketplace registry.
public struct MarketPlugin: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String?
    public let repositoryURL: String?
    public let downloadURL: String
    public let categories: [String]
    public let isInstalled: Bool

    public init(
        id: String,
        name: String,
        version: String,
        description: String,
        author: String? = nil,
        repositoryURL: String? = nil,
        downloadURL: String,
        categories: [String] = [],
        isInstalled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.repositoryURL = repositoryURL
        self.downloadURL = downloadURL
        self.categories = categories
        self.isInstalled = isInstalled
    }
}

extension MarketPlugin: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, version, description, author, repositoryURL, downloadURL, categories, isInstalled
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        version = try c.decode(String.self, forKey: .version)
        description = try c.decode(String.self, forKey: .description)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        repositoryURL = try c.decodeIfPresent(String.self, forKey: .repositoryURL)
        downloadURL = try c.decode(String.self, forKey: .downloadURL)
        categories = try c.decodeIfPresent([String].self, forKey: .categories) ?? []
        isInstalled = try c.decodeIfPresent(Bool.self, forKey: .isInstalled) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(version, forKey: .version)
        try c.encode(description, forKey: .description)
        try c.encodeIfPresent(author, forKey: .author)
        try c.encodeIfPresent(repositoryURL, forKey: .repositoryURL)
        try c.encode(downloadURL, forKey: .downloadURL)
        try c.encode(categories, forKey: .categories)
        try c.encode(isInstalled, forKey: .isInstalled)
    }
}

extension MarketPlugin: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listMarket": "asc plugins market list",
        ]
        if isInstalled {
            cmds["uninstall"] = "asc plugins uninstall --name \(id)"
        } else {
            cmds["install"] = "asc plugins install --name \(id)"
        }
        if let repositoryURL {
            cmds["viewRepository"] = repositoryURL
        }
        return cmds
    }
}
