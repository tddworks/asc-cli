import Foundation
import Testing
@testable import ASCKit

@Suite
struct ShellCommandTests {
    @Test func `should run the command through env with its arguments`() {
        let command = ShellCommand(command: "npx", arguments: ["skills", "list"], environment: nil)

        #expect(command.executable == URL(fileURLWithPath: "/usr/bin/env"))
        #expect(command.argv == ["npx", "skills", "list"])
    }

    @Test func `should add the given variables on top of the inherited environment`() {
        let command = ShellCommand(command: "npx", arguments: [], environment: ["A": "2", "B": "3"])

        #expect(command.environment(inheriting: ["PATH": "/bin", "A": "1"]) == ["PATH": "/bin", "A": "2", "B": "3"])
    }

    @Test func `should inherit the environment unchanged when no variables are given`() {
        let command = ShellCommand(command: "npx", arguments: [], environment: nil)

        #expect(command.environment(inheriting: ["PATH": "/bin"]) == nil)
    }

    @Test func `should answer the trimmed output when the command succeeds`() throws {
        let command = ShellCommand(command: "npx", arguments: [], environment: nil)

        let output = try command.output(exitCode: 0, stdout: Data("  installed\n".utf8), stderr: Data())

        #expect(output == "installed")
    }

    @Test func `should fail with the exit code and what it printed to stderr when the command fails`() {
        let command = ShellCommand(command: "npx", arguments: [], environment: nil)

        do {
            _ = try command.output(exitCode: 2, stdout: Data(), stderr: Data("boom".utf8))
            Issue.record("expected the command to fail")
        } catch ShellRunnerError.executionFailed(let exitCode, let stderr) {
            #expect(exitCode == 2)
            #expect(stderr == "boom")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
