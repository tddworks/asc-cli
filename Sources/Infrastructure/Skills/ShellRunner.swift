import Foundation

/// Abstraction for executing shell commands, enabling testability.
public protocol ShellRunner: Sendable {
    func run(command: String, arguments: [String], environment: [String: String]?) async throws -> String
}

public enum ShellRunnerError: Error, LocalizedError {
    case commandNotFound
    case executionFailed(exitCode: Int32, stderr: String)

    public var errorDescription: String? {
        switch self {
        case .commandNotFound:
            return "Command not found"
        case .executionFailed(let code, let stderr):
            return "Command exited with code \(code): \(stderr)"
        }
    }
}

/// Runs shell commands via `/usr/bin/env` for real process execution.
public struct SystemShellRunner: ShellRunner {
    public init() {}

    public func run(command: String, arguments: [String], environment: [String: String]?) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser

        if let environment {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        // Read stdout and stderr concurrently to avoid pipe buffer deadlock.
        // If one pipe fills its buffer (~64KB) while we're blocking on the other,
        // the child process blocks on write and we deadlock.
        var stderrData = Data()
        let stderrQueue = DispatchQueue(label: "shell-runner-stderr")
        stderrQueue.async {
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        }

        let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        stderrQueue.sync {} // wait for stderr read to finish
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            throw ShellRunnerError.executionFailed(exitCode: process.terminationStatus, stderr: stderr)
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
