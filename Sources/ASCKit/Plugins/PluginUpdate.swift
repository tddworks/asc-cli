/// An available update for an installed plugin.
///
/// Returned by `PluginRepository.listOutdated()`. Represents the diff between
/// what's installed locally and what the marketplace offers.
public struct PluginUpdate: Sendable, Equatable, Identifiable, Codable {
    public var id: String { name }
    public let name: String
    public let installedVersion: String
    public let latestVersion: String
    public let repositoryURL: String?
    public let downloadURL: String?

    public init(
        name: String,
        installedVersion: String,
        latestVersion: String,
        repositoryURL: String? = nil,
        downloadURL: String? = nil
    ) {
        self.name = name
        self.installedVersion = installedVersion
        self.latestVersion = latestVersion
        self.repositoryURL = repositoryURL
        self.downloadURL = downloadURL
    }

    enum CodingKeys: String, CodingKey {
        case name, installedVersion, latestVersion, repositoryURL, downloadURL
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        installedVersion = try c.decode(String.self, forKey: .installedVersion)
        latestVersion = try c.decode(String.self, forKey: .latestVersion)
        repositoryURL = try c.decodeIfPresent(String.self, forKey: .repositoryURL)
        downloadURL = try c.decodeIfPresent(String.self, forKey: .downloadURL)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(installedVersion, forKey: .installedVersion)
        try c.encode(latestVersion, forKey: .latestVersion)
        try c.encodeIfPresent(repositoryURL, forKey: .repositoryURL)
        try c.encodeIfPresent(downloadURL, forKey: .downloadURL)
    }
}

extension PluginUpdate: Presentable {
    public static var tableHeaders: [String] {
        ["Name", "Installed", "Latest"]
    }
    public var tableRow: [String] {
        [name, installedVersion, latestVersion]
    }
}

extension PluginUpdate: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "update": "asc plugins update --name \(name)",
            "list": "asc plugins updates",
        ]
        if let repositoryURL {
            cmds["viewRepository"] = repositoryURL
        }
        return cmds
    }
}
