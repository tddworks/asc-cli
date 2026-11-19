import Foundation

/// Runs shell commands as real processes. Only the `Process` and pipe calls
/// live here; what to launch and what the exit means is `ShellCommand`'s.
public struct SystemShellRunner: ShellRunner {
    public init() {}

    public func run(command: String, arguments: [String], environment: [String: String]?) async throws -> String {
        let shell = ShellCommand(command: command, arguments: arguments, environment: environment)
        let process = Process()
        process.executableURL = shell.executable
        process.arguments = shell.argv
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        if let env = shell.environment(inheriting: ProcessInfo.processInfo.environment) {
            process.environment = env
        }

        // Close stdin so the child process cannot block waiting for input.
        process.standardInput = FileHandle.nullDevice
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()

        // Forward stderr to the terminal in real time (spinners, banners) while
        // also collecting it for the error if the process fails.
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
        stderrQueue.sync {}  // wait for stderr forwarding to finish
        process.waitUntilExit()

        return try shell.output(exitCode: process.terminationStatus, stdout: outputData, stderr: stderrData)
    }
}
