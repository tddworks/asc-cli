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
    public let restRouteConfigurator: (@Sendable (ASCRouter) -> Void)?

    public init(
        port: Int = 8420,
        commandRunner: @escaping @Sendable (String) async -> (String, Int),
        restRouteConfigurator: (@Sendable (ASCRouter) -> Void)? = nil
    ) {
        self.port = port
        self.commandRunner = commandRunner
        self.restRouteConfigurator = restRouteConfigurator
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
          │  /api/v1/*         REST API (HATEOAS)    │
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

        // /api/plugins — list plugin UI scripts for the web app to load.
        // Shape: { plugins: [{ name, slug, ui: [...], apiVersion? }] }
        // `ui` is a list of raw relative paths (e.g. "ui/sim-stream.js").
        // The browser bootstrap composes the URL as
        // `/api/plugins/<slug>/<ui-path>` so plugins can be re-bundled
        // without the host caring about the URL shape.
        let pluginJSON: Data = {
            let manifests = plugins.map { p -> [String: Any] in
                var m: [String: Any] = [
                    "name": p.name,
                    "slug": p.slug,
                    "ui":   p.uiScripts,
                ]
                if let v = p.apiVersion { m["apiVersion"] = v }
                return m
            }
            return (try? JSONSerialization.data(withJSONObject: ["plugins": manifests])) ?? Data("{}".utf8)
        }()
        router.get("/api/plugins") { _, _ in
            Response(status: .ok, headers: [.contentType: "application/json"],
                     body: .init(byteBuffer: ByteBuffer(data: pluginJSON)))
        }

        // /api/plugin-settings/:id — plaintext plugin settings store.
        // GET returns { settings: {...} }; PUT replaces with the body's
        // `settings` field. File lives at ~/.asc/plugin-settings/<id>.json.
        let settingsStore = PluginSettingsStore()
        router.get("/api/plugin-settings/:id") { request, _ in
            let id = request.uri.path.split(separator: "/").last.map(String.init) ?? ""
            let settings = settingsStore.load(pluginId: id)
            return jsonResponse(["settings": settings])
        }
        router.put("/api/plugin-settings/:id") { request, context in
            let id = request.uri.path.split(separator: "/").last.map(String.init) ?? ""
            var buffer = try await request.body.collect(upTo: context.maxUploadSize)
            let bytes = buffer.readBytes(length: buffer.readableBytes) ?? []
            guard let obj = try? JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any],
                  let value = obj["settings"] as? [String: Any] else {
                return jsonError("expected { settings: {...} }", status: .badRequest)
            }
            do {
                try settingsStore.save(pluginId: id, value: value)
            } catch {
                return jsonError("save failed: \(error.localizedDescription)", status: .internalServerError)
            }
            return jsonResponse(["settings": value])
        }

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

        // REST API v1 routes (in-process, no subprocess)
        restRouteConfigurator?(router)

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
