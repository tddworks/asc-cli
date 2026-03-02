import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct FileProjectConfigStorageTests {

    private func makeTempStorage() -> FileProjectConfigStorage {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-test-\(UUID().uuidString)")
        return FileProjectConfigStorage(directoryURL: dir)
    }

    @Test func `save and load roundtrips config`() throws {
        let storage = makeTempStorage()
        let config = ProjectConfig(appId: "app-123", appName: "My App", bundleId: "com.example.app")
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
        let config = ProjectConfig(appId: "app-1", appName: "App", bundleId: "com.example")
        try storage.save(config)
        let loaded = try storage.load()
        #expect(loaded != nil)
    }

    @Test func `delete removes saved config`() throws {
        let storage = makeTempStorage()
        try storage.save(ProjectConfig(appId: "app-1", appName: "App", bundleId: "com.example"))
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
