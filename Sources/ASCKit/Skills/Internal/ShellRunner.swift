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

        // Close stdin so the child process cannot block waiting for input.
        process.standardInput = FileHandle.nullDevice
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        // Stream stderr directly to the terminal so the user sees progress
        // (spinners, banners) in real time. Capture it only for error reporting.
        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()

        // Forward stderr to the terminal in real time while also collecting it
        // for error reporting if the process fails.
        var stderrData = Data()
        let stderrQueue = DispatchQueue(label: "shell-runner-stderr")
        stderrQueue.async {
            let handle = stderrPipe.fileHandleForReading
            while true {
                let chunk = handle.availableData
                if chunk.isEmpty { break }
                FileHandle.standardError.write(chunk)
                stderrData.append(chunk)
            }
        }

        let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        stderrQueue.sync {} // wait for stderr forwarding to finish
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            throw ShellRunnerError.executionFailed(exitCode: process.terminationStatus, stderr: stderr)
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
