import Foundation
import Hummingbird
import HummingbirdTLS
import HummingbirdWebSocket
import NIOCore
import NIOSSL
import Domain
import ASCPlugin

/// Hummingbird-based API server for ASC web apps.
///
/// Plugins auto-discovered from `~/.asc/plugins/`.
public struct ASCWebServer: Sendable {
    public let port: Int
    public let commandRunner: @Sendable (String) async -> (String, Int)

    public init(port: Int = 8420, commandRunner: @escaping @Sendable (String) async -> (String, Int)) {
        self.port = port
        self.commandRunner = commandRunner
    }

    public func run() async throws {
        let plugins = PluginLoader.discover()
        let runner = commandRunner

        let router = buildRouter(runner: runner, plugins: plugins)

        let httpApp = Application(
            router: router,
            server: .http1WebSocketUpgrade(webSocketRouter: router),
            configuration: .init(address: .hostname("0.0.0.0", port: port))
        )

        let httpsPort = port + 1
        let tlsConfig = SelfSignedCert.tlsConfiguration()
        let httpsLine = tlsConfig != nil ? "  │  https://localhost:\(httpsPort)                 │\n" : ""
        let pluginNames = plugins.map { "  │  + \($0.name.padding(toLength: 37, withPad: " ", startingAt: 0))│" }.joined(separator: "\n")

        print("""

          ┌─────────────────────────────────────────┐
          │  ASC Web Server (Hummingbird)            │
          │  http://localhost:\(port)                  │
        \(httpsLine)\
          │                                         │
          │  /api/run          CLI bridge           │
          │  /api/sim/devices  Simulator list       │
        \(plugins.isEmpty ? "" : "\(pluginNames)\n")\
          │                                         │
          │  Press Ctrl+C to stop                   │
          └─────────────────────────────────────────┘

        """)

        // Open browser to web app
        #if os(macOS)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        proc.arguments = ["https://asccli.app/command-center"]
        try? proc.run()
        #endif

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await httpApp.runService() }

            if let tlsConfig {
                let httpsRouter = self.buildRouter(runner: runner, plugins: plugins)
                let httpsApp = Application(
                    router: httpsRouter,
                    server: try .tls(
                        .http1WebSocketUpgrade(webSocketRouter: httpsRouter),
                        tlsConfiguration: tlsConfig
                    ),
                    configuration: .init(address: .hostname("0.0.0.0", port: httpsPort))
                )
                group.addTask { try await httpsApp.runService() }
            }

            try await group.next()
        }
    }

    private func buildRouter(
        runner: @escaping @Sendable (String) async -> (String, Int),
        plugins: [PluginLoader.LoadedPlugin]
    ) -> ASCRouter {
        let router = ASCRouter(context: BasicWebSocketRequestContext.self)
        router.middlewares.add(CORSMiddleware())

        // /api/run — execute CLI commands
        router.post("/api/run") { request, _ in
            let body = try await request.body.collect(upTo: 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let command = json["command"] as? String else {
                return jsonError("Missing command")
            }
            let (output, exitCode) = await runner(command)
            return jsonResponse(["stdout": output, "stderr": "", "exit_code": exitCode])
        }

        // /api/files/write — write base64-encoded content to .asc/ paths (sandboxed)
        router.post("/api/files/write") { request, _ in
            let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
            guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let path = json["path"] as? String,
                  let base64 = json["content"] as? String else {
                return jsonError("Missing path or content")
            }
            // Sandbox: only allow writing under .asc/
            guard path.hasPrefix(".asc/"), !path.contains("..") else {
                return jsonError("Path must be under .asc/ and cannot contain ..")
            }
            guard let data = Data(base64Encoded: base64) else {
                return jsonError("Invalid base64 content")
            }
            let fileURL = URL(fileURLWithPath: path)
            let dir = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: fileURL)
            return jsonResponse(["success": true, "path": path, "bytes": data.count])
        }

        // /api/files/read — serve files from .asc/ paths (sandboxed)
        router.get("/api/files/read") { request, _ in
            guard let path = request.uri.queryParameters.get("path"),
                  path.hasPrefix(".asc/"), !path.contains("..") else {
                return jsonError("Path must be under .asc/")
            }
            let fileURL = URL(fileURLWithPath: path)
            guard let data = try? Data(contentsOf: fileURL) else {
                return jsonError("File not found", status: .notFound)
            }
            let ext = fileURL.pathExtension.lowercased()
            let contentType = ext == "png" ? "image/png" : ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "application/octet-stream"
            return Response(status: .ok, headers: [.contentType: contentType, .cacheControl: "no-cache"],
                            body: .init(byteBuffer: ByteBuffer(data: data)))
        }

        // /api/sim/devices
        router.get("/api/sim/devices") { _, _ in
            let (output, _) = await runner("asc simulators list --pretty")
            if let data = output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let devices = json["data"] {
                let axeAvailable = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/axe")
                    || FileManager.default.fileExists(atPath: "/usr/local/bin/axe")
                return jsonResponse(["devices": devices, "axeAvailable": axeAvailable])
            }
            return jsonResponse(["devices": [], "axeAvailable": false])
        }

        // /api/plugins — list plugin UI scripts for the web app to load
        let pluginJSON: Data = {
            let manifests = plugins.map { p in
                ["name": p.name, "ui": p.uiScripts.map { "/api/plugins/\(p.slug)/\($0)" }] as [String: Any]
            }
            return (try? JSONSerialization.data(withJSONObject: ["plugins": manifests])) ?? Data("{}".utf8)
        }()
        router.get("/api/plugins") { _, _ in
            Response(status: .ok, headers: [.contentType: "application/json"],
                     body: .init(byteBuffer: ByteBuffer(data: pluginJSON)))
        }

        // Platform routes
        TemplatesRoute.register(on: router)

        // Serve each plugin UI file at its exact path
        for p in plugins {
            let pluginDir = p.directory
            for script in p.uiScripts {
                let routePath = "/api/plugins/\(p.slug)/\(script)"
                let filePath = pluginDir.appendingPathComponent(script).path
                router.get(RouterPath(routePath)) { _, _ in
                    guard let data = FileManager.default.contents(atPath: filePath) else {
                        return jsonError("not found", status: .notFound)
                    }
                    return Response(status: .ok,
                                    headers: [.contentType: "application/javascript", .cacheControl: "no-cache"],
                                    body: .init(byteBuffer: ByteBuffer(data: data)))
                }
            }
        }

        // Plugin server routes (dylib configures router directly)
        let routerPtr = Unmanaged.passUnretained(router).toOpaque()
        for p in plugins {
            p.plugin.configureRoutes(routerPtr)
        }

        return router
    }
}

// MARK: - Helpers

public func jsonResponse(_ dict: [String: Any], status: HTTPResponse.Status = .ok) -> Response {
    let data = try! JSONSerialization.data(withJSONObject: dict)
    return Response(status: status, headers: [.contentType: "application/json"],
                    body: .init(byteBuffer: ByteBuffer(data: data)))
}

public func jsonError(_ message: String, status: HTTPResponse.Status = .badRequest) -> Response {
    jsonResponse(["error": message], status: status)
}
