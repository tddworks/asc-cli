import Foundation
import Testing
@testable import ASCPlugin

@Suite("PluginSettingsStore — on-disk JSON settings")
struct PluginSettingsStoreTests {
    private static func makeTempDir() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("plugin-settings-test-\(UUID().uuidString)")
        return url
    }

    @Test func `load returns empty when file is missing`() {
        let tempDir = Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = PluginSettingsStore(rootDir: tempDir)
        #expect(store.load(pluginId: "asc-pro.ai").isEmpty)
    }

    @Test func `save and load round-trips JSON`() throws {
        let tempDir = Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = PluginSettingsStore(rootDir: tempDir)
        try store.save(pluginId: "asc-pro.ai", value: [
            "apiKey": "abc",
            "model": "gpt-5",
        ])

        let loaded = store.load(pluginId: "asc-pro.ai")
        #expect(loaded["apiKey"] as? String == "abc")
        #expect(loaded["model"] as? String == "gpt-5")
    }

    @Test func `save overwrites the previous file`() throws {
        let tempDir = Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = PluginSettingsStore(rootDir: tempDir)
        try store.save(pluginId: "asc-pro.ai", value: ["apiKey": "old"])
        try store.save(pluginId: "asc-pro.ai", value: ["apiKey": "new"])

        let loaded = store.load(pluginId: "asc-pro.ai")
        #expect(loaded["apiKey"] as? String == "new")
    }

    @Test func `load returns empty on malformed JSON`() throws {
        let tempDir = Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try "not valid json".write(
            to: tempDir.appendingPathComponent("asc-pro.ai.json"),
            atomically: true,
            encoding: .utf8,
        )

        let store = PluginSettingsStore(rootDir: tempDir)
        #expect(store.load(pluginId: "asc-pro.ai").isEmpty)
    }

    @Test func `sanitises plugin id to prevent path traversal`() {
        let tempDir = Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = PluginSettingsStore(rootDir: tempDir)
        // ".." / "/" characters must be scrubbed so the resolved file URL
        // stays under `rootDir` — otherwise a malicious plugin could write
        // to arbitrary user files.
        let url = store.fileURL(for: "../malicious")
        #expect(url.path.hasPrefix(tempDir.path),
                "file URL escapes the root directory: \(url.path)")
    }

    @Test func `nested plugin ids are sanitised`() {
        let tempDir = Self.makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = PluginSettingsStore(rootDir: tempDir)
        let url = store.fileURL(for: "asc-pro/ai")
        #expect(!url.path.contains("/asc-pro/ai"),
                "slash in plugin id must be replaced; got \(url.path)")
    }
}
