import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite
struct ProcessSkillRepositoryTests {

    @Test func `check parses updates available from stdout`() async throws {
        let runner = StubShellRunner(stdout: "2 update(s) available")
        let repo = ProcessSkillRepository(runner: runner)
        let result = try await repo.check()
        #expect(result == .updatesAvailable)
    }

    @Test func `check parses all skills are up to date`() async throws {
        let runner = StubShellRunner(stdout: "All skills are up to date")
        let repo = ProcessSkillRepository(runner: runner)
        let result = try await repo.check()
        #expect(result == .upToDate)
    }

    @Test func `check parses no updates available`() async throws {
        let runner = StubShellRunner(stdout: "No updates available")
        let repo = ProcessSkillRepository(runner: runner)
        let result = try await repo.check()
        #expect(result == .upToDate)
    }

    @Test func `check returns unavailable when runner throws`() async throws {
        let runner = StubShellRunner(error: ShellRunnerError.commandNotFound)
        let repo = ProcessSkillRepository(runner: runner)
        let result = try await repo.check()
        #expect(result == .unavailable)
    }

    @Test func `check returns up to date for unknown output`() async throws {
        let runner = StubShellRunner(stdout: "something unexpected")
        let repo = ProcessSkillRepository(runner: runner)
        let result = try await repo.check()
        #expect(result == .upToDate)
    }

    @Test func `listAvailable returns stdout from runner`() async throws {
        let runner = StubShellRunner(stdout: "asc-cli\nasc-auth\nasc-testflight")
        let repo = ProcessSkillRepository(runner: runner)
        let output = try await repo.listAvailable()
        #expect(output == "asc-cli\nasc-auth\nasc-testflight")
    }

    @Test func `install returns stdout from runner`() async throws {
        let runner = StubShellRunner(stdout: "Installed asc-cli skill")
        let repo = ProcessSkillRepository(runner: runner)
        let output = try await repo.install(name: "asc-cli")
        #expect(output == "Installed asc-cli skill")
    }

    @Test func `installAll returns stdout from runner`() async throws {
        let runner = StubShellRunner(stdout: "Installed 5 skills")
        let repo = ProcessSkillRepository(runner: runner)
        let output = try await repo.installAll()
        #expect(output == "Installed 5 skills")
    }

    @Test func `update returns stdout from runner`() async throws {
        let runner = StubShellRunner(stdout: "Updated 3 skills")
        let repo = ProcessSkillRepository(runner: runner)
        let output = try await repo.update()
        #expect(output == "Updated 3 skills")
    }
}
