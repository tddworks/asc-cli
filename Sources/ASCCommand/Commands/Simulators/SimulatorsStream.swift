import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct SimulatorsStream: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Stream a simulator screen to the browser with interactive controls"
    )

    @Option(name: .long, help: "Simulator UDID (optional — pick from browser if omitted)")
    var udid: String?

    @Option(name: .long, help: "HTTP server port (default: 8425)")
    var port: Int = 8425

    @Option(name: .long, help: "Frames per second (default: 5)")
    var fps: Int = 5

    func run() async throws {
        let simulatorRepo = ClientProvider.makeSimulatorRepository()
        let interactionRepo = ClientProvider.makeSimulatorInteractionRepository()

        // If udid provided, verify it's booted
        if let udid {
            let simulators = try await simulatorRepo.listSimulators(filter: .booted)
            if !simulators.contains(where: { $0.id == udid }) {
                throw ValidationError("Simulator \(udid) is not booted. Run: asc simulators boot --udid \(udid)")
            }
        }

        // Load the HTML UI and device config from bundled files
        let htmlContent = Self.loadHTML()
        let deviceConfig = Self.loadDeviceConfig()

        let server = try DeviceStreamServer(
            port: UInt16(port),
            simulatorRepo: simulatorRepo,
            interactionRepo: interactionRepo,
            htmlContent: htmlContent,
            deviceConfigJSON: deviceConfig
        )
        server.start()

        let url = "http://localhost:\(port)"
        print("Interactive simulator stream at \(url)")
        if interactionRepo.isAvailable() {
            print("axe: ready (tap, swipe, type, gestures enabled)")
        } else {
            print("axe: not found (install: brew install cameroncooke/axe/axe)")
        }
        print("Press Ctrl+C to stop.")

        // Open browser
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url]
        try process.run()

        // Keep running until cancelled
        while !Task.isCancelled {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        server.stop()
    }

    private static func loadHTML() -> String {
        // Try to load from apps/remote-device-stream/index.html relative to the binary
        let binaryPath = ProcessInfo.processInfo.arguments[0]
        let binaryDir = URL(fileURLWithPath: binaryPath).deletingLastPathComponent()

        // Check common locations
        let candidates = [
            binaryDir.appendingPathComponent("../../apps/remote-device-stream/index.html"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("apps/remote-device-stream/index.html"),
        ]

        for candidate in candidates {
            if let content = try? String(contentsOf: candidate, encoding: .utf8) {
                return content
            }
        }

        // Fallback: minimal HTML
        return """
        <!DOCTYPE html>
        <html><head><title>Simulator Stream</title>
        <style>
            body { margin: 0; background: #0a0a0f; color: #e0e0f0; font-family: -apple-system, system-ui;
                   display: flex; justify-content: center; align-items: center; min-height: 100vh; }
            img { max-height: 85vh; border-radius: 12px; cursor: crosshair; }
            .info { text-align: center; }
            h1 { font-size: 16px; font-weight: 500; margin-bottom: 8px; }
            p { font-size: 12px; color: #888; }
        </style></head><body>
        <div class="info">
            <h1>Simulator Stream</h1>
            <p>Place apps/remote-device-stream/index.html in the project directory for full interactive UI</p>
        </div>
        </body></html>
        """
    }

    private static func loadDeviceConfig() -> String {
        let candidates = [
            URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0])
                .deletingLastPathComponent()
                .appendingPathComponent("../../apps/remote-device-stream/simulator-config.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("apps/remote-device-stream/simulator-config.json"),
        ]
        for candidate in candidates {
            if let content = try? String(contentsOf: candidate, encoding: .utf8) {
                return content
            }
        }
        return "{}"
    }
}
