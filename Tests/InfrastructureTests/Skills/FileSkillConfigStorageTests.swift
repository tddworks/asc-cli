import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct FileSkillConfigStorageTests {

    private func makeTempStorage() -> FileSkillConfigStorage {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-test-\(UUID().uuidString)")
            .appendingPathComponent("skills-config.json")
        return FileSkillConfigStorage(fileURL: url)
    }

    @Test func `save and load roundtrips config`() async throws {
        let storage = makeTempStorage()
        let date = Date(timeIntervalSince1970: 1710000000)
        let config = SkillConfig(skillsCheckedAt: date)
        try await storage.save(config)
        let loaded = try await storage.load()
        #expect(loaded == config)
    }

    @Test func `load returns nil when file does not exist`() async throws {
        let storage = makeTempStorage()
        let loaded = try await storage.load()
        #expect(loaded == nil)
    }

    @Test func `save creates parent directory if needed`() async throws {
        let storage = makeTempStorage()
        let config = SkillConfig(skillsCheckedAt: Date())
        try await storage.save(config)
        let loaded = try await storage.load()
        #expect(loaded != nil)
    }

    @Test func `nil checked at omits field from json`() async throws {
        let storage = makeTempStorage()
        let config = SkillConfig(skillsCheckedAt: nil)
        try await storage.save(config)
        let loaded = try await storage.load()
        #expect(loaded?.skillsCheckedAt == nil)
    }
}
