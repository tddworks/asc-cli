import Foundation
import Testing
@testable import Domain

@Suite("Skill")
struct SkillTests {

    @Test func `skill carries all fields`() {
        let skill = MockRepositoryFactory.makeSkill(
            id: "asc-cli",
            name: "asc-cli",
            description: "App Store Connect CLI skill",
            isInstalled: true
        )

        #expect(skill.id == "asc-cli")
        #expect(skill.name == "asc-cli")
        #expect(skill.description == "App Store Connect CLI skill")
        #expect(skill.isInstalled == true)
    }

    @Test func `installed skill affordances include uninstall but not install`() {
        let skill = MockRepositoryFactory.makeSkill(name: "asc-cli", isInstalled: true)

        #expect(skill.affordances["uninstall"] == "asc skills uninstall --name asc-cli")
        #expect(skill.affordances["listSkills"] == "asc skills list")
        #expect(skill.affordances["install"] == nil)
    }

    @Test func `not installed skill affordances include install but not uninstall`() {
        let skill = MockRepositoryFactory.makeSkill(name: "asc-auth", isInstalled: false)

        #expect(skill.affordances["install"] == "asc skills install --name asc-auth")
        #expect(skill.affordances["listSkills"] == "asc skills list")
        #expect(skill.affordances["uninstall"] == nil)
    }

    @Test func `skill is codable round trip`() throws {
        let skill = MockRepositoryFactory.makeSkill()
        let data = try JSONEncoder().encode(skill)
        let decoded = try JSONDecoder().decode(Skill.self, from: data)
        #expect(decoded == skill)
    }

    @Test func `skill check result raw values`() {
        #expect(SkillCheckResult.upToDate.rawValue == "upToDate")
        #expect(SkillCheckResult.updatesAvailable.rawValue == "updatesAvailable")
        #expect(SkillCheckResult.unavailable.rawValue == "unavailable")
    }

    @Test func `skill config stores checked at timestamp`() throws {
        let date = Date(timeIntervalSince1970: 1710000000)
        let config = SkillConfig(skillsCheckedAt: date)
        #expect(config.skillsCheckedAt == date)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SkillConfig.self, from: data)
        #expect(decoded == config)
    }

    @Test func `skill config with nil checked at`() throws {
        let config = SkillConfig(skillsCheckedAt: nil)
        #expect(config.skillsCheckedAt == nil)

        let data = try JSONEncoder().encode(config)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("skillsCheckedAt"))
    }
}