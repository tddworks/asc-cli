import Foundation

/// One shell command as `SystemShellRunner` runs it: how it is launched,
/// which environment it sees, and what its exit means. The process itself
/// lives in `System/SystemShellRunner.swift`.
struct ShellCommand: Equatable, Sendable {
    let command: String
    let arguments: [String]
    let environment: [String: String]?

    /// Run through `/usr/bin/env`, so the command is found on the `PATH`.
    var executable: URL { URL(fileURLWithPath: "/usr/bin/env") }

    var argv: [String] { [command] + arguments }

    /// The given variables on top of `inherited`, or `nil` to inherit it unchanged.
    func environment(inheriting inherited: [String: String]) -> [String: String]? {
        guard let environment else { return nil }
        return inherited.merging(environment) { _, given in given }
    }

    /// The trimmed standard output, or `executionFailed` with the exit code and stderr.
    func output(exitCode: Int32, stdout: Data, stderr: Data) throws -> String {
        guard exitCode == 0 else {
            throw ShellRunnerError.executionFailed(exitCode: exitCode, stderr: String(data: stderr, encoding: .utf8) ?? "")
        }
        return String(data: stdout, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
