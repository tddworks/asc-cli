import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("SkillUpdateChecker")
struct SkillUpdateCheckerTests {

    @Test func `skips check when ASC_SKIP_SKILL_CHECK is true`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()

        await SkillUpdateChecker.checkIfNeeded(
            repo: mockRepo,
            storage: mockStorage,
            environment: ["ASC_SKIP_SKILL_CHECK": "true"]
        )

        // Repo.check should never be called
        verify(mockRepo).check().called(.never)
    }

    @Test func `skips check in CI environment`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()

        await SkillUpdateChecker.checkIfNeeded(
            repo: mockRepo,
            storage: mockStorage,
            environment: ["CI": "true"]
        )

        verify(mockRepo).check().called(.never)
    }

    @Test func `skips check when last check was less than 24h ago`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        let recentCheck = Date().addingTimeInterval(-3600) // 1 hour ago
        given(mockStorage).load().willReturn(SkillConfig(skillsCheckedAt: recentCheck))

        await SkillUpdateChecker.checkIfNeeded(
            repo: mockRepo,
            storage: mockStorage,
            environment: [:]
        )

        verify(mockRepo).check().called(.never)
    }

    @Test func `runs check when last check was more than 24h ago`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        let oldCheck = Date().addingTimeInterval(-25 * 3600) // 25 hours ago
        given(mockStorage).load().willReturn(SkillConfig(skillsCheckedAt: oldCheck))
        given(mockRepo).check().willReturn(.upToDate)
        given(mockStorage).save(.any).willReturn()

        await SkillUpdateChecker.checkIfNeeded(
            repo: mockRepo,
            storage: mockStorage,
            environment: [:]
        )

        verify(mockRepo).check().called(.once)
    }

    @Test func `runs check when no previous check exists`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        given(mockStorage).load().willReturn(nil)
        given(mockRepo).check().willReturn(.upToDate)
        given(mockStorage).save(.any).willReturn()

        await SkillUpdateChecker.checkIfNeeded(
            repo: mockRepo,
            storage: mockStorage,
            environment: [:]
        )

        verify(mockRepo).check().called(.once)
    }

    @Test func `does not persist timestamp when result is unavailable`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        given(mockStorage).load().willReturn(nil)
        given(mockRepo).check().willReturn(.unavailable)

        await SkillUpdateChecker.checkIfNeeded(
            repo: mockRepo,
            storage: mockStorage,
            environment: [:]
        )

        verify(mockStorage).save(.any).called(.never)
    }

    @Test func `persists timestamp when result is up to date`() async throws {
        let mockRepo = MockSkillRepository()
        let mockStorage = MockSkillConfigStorage()
        given(mockStorage).load().willReturn(nil)
        given(mockRepo).check().willReturn(.upToDate)
        given(mockStorage).save(.any).willReturn()

        await SkillUpdateChecker.checkIfNeeded(
            repo: mockRepo,
            storage: mockStorage,
            environment: [:]
        )

        verify(mockStorage).save(.any).called(.once)
    }
}
