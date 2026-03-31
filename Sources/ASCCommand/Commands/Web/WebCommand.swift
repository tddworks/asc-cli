import ArgumentParser
import Foundation

struct WebServerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web-server",
        abstract: "Start the local API proxy for ASC web apps"
    )

    @Option(name: .long, help: "Port to listen on (default: 8420)")
    var port: Int = 8420

    func run() async throws {
        // Write embedded server.js to temp file
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("asc-web-server")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let serverFile = tmpDir.appendingPathComponent("server.js")
        try EmbeddedServerJS.content.write(to: serverFile, atomically: true, encoding: .utf8)

        let ascBin = ProcessInfo.processInfo.arguments[0]

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        let projectDir = FileManager.default.currentDirectoryPath
        process.arguments = ["node", serverFile.path, "--port", "\(port)", "--asc-bin", ascBin, "--project-dir", projectDir]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.standardError

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                FileHandle.standardOutput.write(data)
            }
        }

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw ValidationError("Server exited with code \(process.terminationStatus)")
        }
    }
}
