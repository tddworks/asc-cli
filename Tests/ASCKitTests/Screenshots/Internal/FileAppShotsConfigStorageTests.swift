import Foundation
import Testing
@testable import ASCKit

@Suite
struct FileAppShotsConfigStorageTests {

    private func makeTempStorage() -> FileAppShotsConfigStorage {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-test-\(UUID().uuidString)")
            .appendingPathComponent("app-shots-config.json")
        return FileAppShotsConfigStorage(fileURL: url)
    }

    @Test func `save and load roundtrips config`() throws {
        let storage = makeTempStorage()
        let config = AppShotsConfig(geminiApiKey: "AIzaSyTestKey")
        try storage.save(config)
        let loaded = try storage.load()
        #expect(loaded == config)
    }

    @Test func `load returns nil when file does not exist`() throws {
        let storage = makeTempStorage()
        let loaded = try storage.load()
        #expect(loaded == nil)
    }

    @Test func `save creates parent directory if needed`() throws {
        let storage = makeTempStorage()
        let config = AppShotsConfig(geminiApiKey: "key-123")
        try storage.save(config)
        let loaded = try storage.load()
        #expect(loaded != nil)
    }

    @Test func `delete removes saved config`() throws {
        let storage = makeTempStorage()
        try storage.save(AppShotsConfig(geminiApiKey: "key-abc"))
        try storage.delete()
        let loaded = try storage.load()
        #expect(loaded == nil)
    }

    @Test func `delete succeeds silently when file does not exist`() throws {
        let storage = makeTempStorage()
        // Should not throw
        try storage.delete()
    }
}
