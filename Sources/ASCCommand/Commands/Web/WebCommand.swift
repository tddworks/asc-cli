import ArgumentParser
import Foundation

struct WebCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web",
        abstract: "Start the ASC web management console"
    )

    @Option(name: .long, help: "Port to listen on (default: 8420)")
    var port: Int = 8420

    @Flag(name: .long, help: "Don't open the browser automatically")
    var noBrowser: Bool = false

    func run() async throws {
        let url = "http://127.0.0.1:\(port)"
        print("")
        print("  ASC Web Console")
        print("  \(String(repeating: "─", count: 32))")
        print("  Local:  \(url)")
        print("  \(String(repeating: "─", count: 32))")
        print("  Press Ctrl+C to stop")
        print("")

        if !noBrowser {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = [url]
            try? process.run()
        }

        try await WebServer.start(port: port)
    }
}
