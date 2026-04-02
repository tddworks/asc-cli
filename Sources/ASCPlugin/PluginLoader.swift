import Foundation

/// Discovers plugins from `~/.asc/plugins/`.
///
/// Supports:
///   - `.plugin` bundles (dir with manifest.json + dylib + ui/)
///   - `.framework` bundles (legacy)
///   - `.dylib` files (standalone)
public enum PluginLoader {
    public static let pluginsDirectory = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".asc/plugins")

    public struct LoadedPlugin {
        public let plugin: ASCPluginBase
        public let name: String
        public let slug: String  // URL-safe identifier (directory name without extension)
        public let directory: URL
        public let uiScripts: [String]
    }

    private nonisolated(unsafe) static var _cached: [LoadedPlugin]?

    public static func discover() -> [LoadedPlugin] {
        if let cached = _cached { return cached }
        if ProcessInfo.processInfo.environment["ASC_NO_PLUGINS"] != nil { return [] }

        let fm = FileManager.default
        let dir = pluginsDirectory
        guard fm.fileExists(atPath: dir.path),
              let files = try? fm.contentsOfDirectory(atPath: dir.path) else { return [] }

        var results: [LoadedPlugin] = []

        for file in files {
            let fullPath = dir.appendingPathComponent(file)

            if file.hasSuffix(".plugin") {
                // Plugin bundle with manifest
                if let loaded = loadBundle(at: fullPath) {
                    results.append(loaded)
                }
            } else if file.hasSuffix(".framework") {
                // Framework bundle (legacy)
                let name = (file as NSString).deletingPathExtension
                let dylibPath = fullPath.appendingPathComponent(name).path
                if let plugin = loadDylib(at: dylibPath) {
                    results.append(LoadedPlugin(plugin: plugin, name: name, slug: name, directory: fullPath, uiScripts: []))
                }
            } else if file.hasSuffix(".dylib") {
                // Standalone dylib
                if let plugin = loadDylib(at: fullPath.path) {
                    let slug = (file as NSString).deletingPathExtension
                    results.append(LoadedPlugin(plugin: plugin, name: slug, slug: slug, directory: dir, uiScripts: []))
                }
            }
        }
        _cached = results
        return results
    }

    // MARK: - Private

    private static func loadBundle(at url: URL) -> LoadedPlugin? {
        let manifestURL = url.appendingPathComponent("manifest.json")
        guard let data = try? Data(contentsOf: manifestURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String else {
            return nil
        }

        let uiScripts = (json["ui"] as? [String]) ?? []
        let slug = (url.lastPathComponent as NSString).deletingPathExtension

        // UI-only plugin (no server/dylib)
        if json["server"] == nil {
            let stub = UIOnlyPlugin(name: name)
            FileHandle.standardError.write(Data("  Plugin: \(name) (\(url.lastPathComponent)) [UI-only]\n".utf8))
            return LoadedPlugin(plugin: stub, name: name, slug: slug, directory: url, uiScripts: uiScripts)
        }

        guard let serverPath = json["server"] as? String else { return nil }
        let dylibPath = url.appendingPathComponent(serverPath).path
        guard let plugin = loadDylib(at: dylibPath) else { return nil }

        FileHandle.standardError.write(Data("  Plugin: \(name) (\(url.lastPathComponent))\n".utf8))
        return LoadedPlugin(plugin: plugin, name: name, slug: slug, directory: url, uiScripts: uiScripts)
    }

    /// Stub for UI-only plugins that have no server-side dylib.
    private final class UIOnlyPlugin: NSObject, ASCPluginBase {
        let name: String
        var commands: [Any] { [] }
        init(name: String) { self.name = name }
        func configureRoutes(_ router: Any) {}
    }

    private static func loadDylib(at path: String) -> ASCPluginBase? {
        guard let handle = dlopen(path, RTLD_NOW) else {
            let err = String(cString: dlerror())
            FileHandle.standardError.write(Data("  Plugin: failed to load \(path): \(err)\n".utf8))
            return nil
        }
        guard let sym = dlsym(handle, "ascPlugin") else { return nil }

        typealias Fn = @convention(c) () -> UnsafeMutableRawPointer
        let obj = Unmanaged<AnyObject>.fromOpaque(unsafeBitCast(sym, to: Fn.self)()).takeRetainedValue()
        return obj as? ASCPluginBase
    }
}
