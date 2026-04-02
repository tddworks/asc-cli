import ArgumentParser
import Foundation
import Domain
import Infrastructure
import ASCPlugin

struct WebServerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web-server",
        abstract: "Start the local API server for ASC web apps"
    )

    @Option(name: .long, help: "Port to listen on (default: 8420)")
    var port: Int = 8420

    func run() async throws {
        let server = ASCWebServer(port: port, commandRunner: Self.runCommand)
        try await server.run()
    }

    /// Execute a CLI command in-process via subprocess.
    /// We use subprocess here because in-process stdout capture conflicts with
    /// Hummingbird's server output. The subprocess is the same binary — fast, clean.
    static func runCommand(_ command: String) async -> (String, Int) {
        let ascBin = ProcessInfo.processInfo.arguments[0]
        let parts = command.split(separator: " ").map(String.init)
        let args = parts.first == "asc" ? Array(parts.dropFirst()) : parts

        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: ascBin)
            process.arguments = args
            process.environment = ProcessInfo.processInfo.environment

            let stdout = Pipe()
            process.standardOutput = stdout
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                continuation.resume(returning: (output.trimmingCharacters(in: .whitespacesAndNewlines), Int(process.terminationStatus)))
            } catch {
                continuation.resume(returning: (error.localizedDescription, 1))
            }
        }
    }
}
