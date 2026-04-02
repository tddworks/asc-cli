/// An installed dylib plugin discovered from `~/.asc/plugins/`.
///
/// Plugin bundles (`.plugin` directories) contain a `manifest.json`,
/// a compiled dylib, and optional UI scripts for the web app.
public struct Plugin: Sendable, Equatable, Identifiable, Codable {
    public let id: String        // = slug
    public let name: String
    public let version: String
    public let slug: String      // URL-safe directory name (e.g. "ASCPro")
    public let uiScripts: [String]

    public init(
        id: String,
        name: String,
        version: String,
        slug: String,
        uiScripts: [String]
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.slug = slug
        self.uiScripts = uiScripts
    }
}

extension Plugin: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "uninstall": "asc plugins uninstall --name \(slug)",
            "browseMarket": "asc plugins market list",
        ]
    }
}
