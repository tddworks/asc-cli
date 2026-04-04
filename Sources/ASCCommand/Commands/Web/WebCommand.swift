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

    /// Execute a CLI command via subprocess — pipe-safe for large output.
    static func runCommand(_ command: String) async -> (String, Int) {
        let ascBin = ProcessInfo.processInfo.arguments[0]
        let parts = shellSplit(command)
        let args = parts.first == "asc" ? Array(parts.dropFirst()) : parts

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ascBin)
        process.arguments = args
        process.environment = ProcessInfo.processInfo.environment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return (error.localizedDescription, 1)
        }

        // Read all data from pipe on a detached task to avoid buffer deadlock
        let data = await withCheckedContinuation { (cont: CheckedContinuation<Data, Never>) in
            DispatchQueue.global().async {
                let d = pipe.fileHandleForReading.readDataToEndOfFile()
                cont.resume(returning: d)
            }
        }

        process.waitUntilExit()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (output.trimmingCharacters(in: .whitespacesAndNewlines), Int(process.terminationStatus))
    }

    /// Split a command string respecting quoted arguments.
    /// e.g. `--headline "Your Headline"` → ["--headline", "Your Headline"]
    private static func shellSplit(_ command: String) -> [String] {
        var args: [String] = []
        var current = ""
        var inQuote: Character? = nil

        for ch in command {
            if let q = inQuote {
                if ch == q {
                    inQuote = nil
                } else {
                    current.append(ch)
                }
            } else if ch == "\"" || ch == "'" {
                inQuote = ch
            } else if ch == " " {
                if !current.isEmpty {
                    args.append(current)
                    current = ""
                }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { args.append(current) }
        return args
    }
}
