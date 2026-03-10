import Domain
import Foundation

/// Manages plugins installed in `~/.asc/plugins/<name>/`.
///
/// Each plugin directory must contain:
/// - `manifest.json` — plugin metadata and event subscriptions
/// - `run`           — executable file (any language, chmod +x)
///
/// A `.disabled` file in the plugin directory marks it as disabled.
public struct LocalPluginRepository: PluginRepository {

    private let pluginsDirectory: URL

    public init(pluginsDirectory: URL = Self.defaultPluginsDirectory) {
        self.pluginsDirectory = pluginsDirectory
    }

    private var fileManager: FileManager { .default }

    public static var defaultPluginsDirectory: URL {
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".asc/plugins")
    }

    public func listPlugins() async throws -> [Plugin] {
        guard fileManager.fileExists(atPath: pluginsDirectory.path) else { return [] }

        let entries = try fileManager.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )

        return entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .compactMap { dir in try? loadPlugin(from: dir) }
            .sorted { $0.name < $1.name }
    }

    public func getPlugin(name: String) async throws -> Plugin {
        let dir = pluginsDirectory.appendingPathComponent(name)
        guard fileManager.fileExists(atPath: dir.path) else {
            throw PluginError.notFound(name: name)
        }
        return try loadPlugin(from: dir)
    }

    public func installPlugin(from path: String) async throws -> Plugin {
        let sourceURL = URL(fileURLWithPath: path)
        let manifestURL = sourceURL.appendingPathComponent("manifest.json")
        let executableURL = sourceURL.appendingPathComponent("run")

        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw PluginError.missingManifest(path: path)
        }
        guard fileManager.fileExists(atPath: executableURL.path) else {
            throw PluginError.missingExecutable(path: path)
        }

        let manifest = try loadManifest(from: manifestURL)
        let destDir = pluginsDirectory.appendingPathComponent(manifest.name)

        try fileManager.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: destDir.path) {
            try fileManager.removeItem(at: destDir)
        }
        try fileManager.copyItem(at: sourceURL, to: destDir)

        // Ensure executable bit is set
        let destExecutable = destDir.appendingPathComponent("run")
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destExecutable.path)

        return try loadPlugin(from: destDir)
    }

    public func uninstallPlugin(name: String) async throws {
        let dir = pluginsDirectory.appendingPathComponent(name)
        guard fileManager.fileExists(atPath: dir.path) else {
            throw PluginError.notFound(name: name)
        }
        try fileManager.removeItem(at: dir)
    }

    public func enablePlugin(name: String) async throws -> Plugin {
        let dir = pluginsDirectory.appendingPathComponent(name)
        guard fileManager.fileExists(atPath: dir.path) else {
            throw PluginError.notFound(name: name)
        }
        let disabledMarker = dir.appendingPathComponent(".disabled")
        if fileManager.fileExists(atPath: disabledMarker.path) {
            try fileManager.removeItem(at: disabledMarker)
        }
        return try loadPlugin(from: dir)
    }

    public func disablePlugin(name: String) async throws -> Plugin {
        let dir = pluginsDirectory.appendingPathComponent(name)
        guard fileManager.fileExists(atPath: dir.path) else {
            throw PluginError.notFound(name: name)
        }
        let disabledMarker = dir.appendingPathComponent(".disabled")
        if !fileManager.fileExists(atPath: disabledMarker.path) {
            fileManager.createFile(atPath: disabledMarker.path, contents: nil)
        }
        return try loadPlugin(from: dir)
    }

    // MARK: - Private

    private func loadPlugin(from dir: URL) throws -> Plugin {
        let manifestURL = dir.appendingPathComponent("manifest.json")
        let executableURL = dir.appendingPathComponent("run")

        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw PluginError.missingManifest(path: dir.path)
        }
        guard fileManager.fileExists(atPath: executableURL.path) else {
            throw PluginError.missingExecutable(path: dir.path)
        }

        let manifest = try loadManifest(from: manifestURL)
        let disabledMarker = dir.appendingPathComponent(".disabled")
        let isEnabled = !fileManager.fileExists(atPath: disabledMarker.path)

        return Plugin(
            id: manifest.name,
            name: manifest.name,
            version: manifest.version,
            description: manifest.description,
            author: manifest.author,
            executablePath: executableURL.path,
            subscribedEvents: manifest.events,
            isEnabled: isEnabled
        )
    }

    private func loadManifest(from url: URL) throws -> PluginManifest {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(PluginManifest.self, from: data)
    }
}

// MARK: - Manifest

private struct PluginManifest: Codable {
    let name: String
    let version: String
    let description: String
    let author: String?
    let events: [PluginEvent]
}

// MARK: - Errors

public enum PluginError: Error, LocalizedError {
    case notFound(name: String)
    case missingManifest(path: String)
    case missingExecutable(path: String)
    case executionFailed(name: String, exitCode: Int32)
    case invalidOutput(name: String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let name):
            return "Plugin '\(name)' not found in ~/.asc/plugins/"
        case .missingManifest(let path):
            return "Plugin at '\(path)' is missing manifest.json"
        case .missingExecutable(let path):
            return "Plugin at '\(path)' is missing 'run' executable"
        case .executionFailed(let name, let code):
            return "Plugin '\(name)' exited with code \(code)"
        case .invalidOutput(let name):
            return "Plugin '\(name)' returned invalid JSON output"
        }
    }
}
