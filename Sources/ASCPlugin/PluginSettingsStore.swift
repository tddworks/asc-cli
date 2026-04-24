import Foundation

/// Plugin settings persistence. Plaintext JSON on disk at
/// `~/.asc/plugin-settings/<id>.json`. No keychain — keeps the CLI
/// portable and the storage model trivial; plugin authors that store
/// credentials must live with a regular file on disk.
///
/// Thread-safety: every write atomically replaces the target file via
/// `Data.write(to:options:.atomic)`, and reads tolerate partial writes
/// by returning an empty dictionary on parse failure. Callers (the web
/// server) may concurrently read + write different plugin IDs; each
/// plugin's file is its own lock domain.
public struct PluginSettingsStore: Sendable {
    public let rootDir: URL

    public init(rootDir: URL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".asc/plugin-settings"))
    {
        self.rootDir = rootDir
    }

    /// Load the settings blob for a plugin. Returns `[:]` when the file
    /// doesn't exist or is unparseable — plugins treat both as "first run".
    public func load(pluginId: String) -> [String: Any] {
        let url = fileURL(for: pluginId)
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }

    /// Replace the settings blob for a plugin. Creates the parent
    /// directory on first write.
    public func save(pluginId: String, value: [String: Any]) throws {
        try FileManager.default.createDirectory(at: rootDir, withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: fileURL(for: pluginId), options: .atomic)
    }

    // MARK: - Internals

    /// Path for a plugin's settings file. Sanitises the id so a malicious
    /// plugin can't traverse out of the settings directory.
    func fileURL(for pluginId: String) -> URL {
        let safe = sanitize(pluginId)
        return rootDir.appendingPathComponent("\(safe).json")
    }

    private func sanitize(_ id: String) -> String {
        // Allow letters, digits, dot, dash, underscore. Everything else
        // (slashes, dots traversals, spaces) collapses to `_`.
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_")
        return String(id.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
    }
}
