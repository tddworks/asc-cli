import Foundation
import Hummingbird

/// HTTP server for the ASC web console, built on Hummingbird.
/// Serves bundled static files and handles `/api/run` to execute `asc` subcommands.
enum WebServer {

    static func start(port: Int) async throws {
        guard let webRoot = Bundle.module.url(forResource: "web", withExtension: nil) else {
            throw WebServerError.missingWebResources
        }

        let router = Router()

        // POST /api/run — execute an asc command
        router.post("/api/run") { request, _ -> Response in
            try await handleRun(request)
        }

        // Middleware: serve static files for all GET requests
        router.middlewares.add(StaticFileMiddleware(webRoot: webRoot))

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: port))
        )

        try await app.runService()
    }

    static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": return "text/html; charset=utf-8"
        case "js":   return "application/javascript; charset=utf-8"
        case "css":  return "text/css; charset=utf-8"
        case "json": return "application/json"
        case "png":  return "image/png"
        case "svg":  return "image/svg+xml"
        default:     return "application/octet-stream"
        }
    }

    // MARK: - API handler

    private static func handleRun(_ request: Request) async throws -> Response {
        let body = try await request.body.collect(upTo: 1_048_576)
        guard let json = try? JSONSerialization.jsonObject(with: Data(buffer: body)) as? [String: Any],
              let command = json["command"] as? String,
              !command.isEmpty else {
            return jsonResponse(status: .badRequest, json: ["error": "Missing 'command' field"])
        }

        let parts = command.split(separator: " ").map(String.init)
        guard parts.first == "asc" else {
            return jsonResponse(status: .badRequest, json: ["error": "Only 'asc' commands are allowed"])
        }

        let dangerous: Set<Character> = [";", "|", "&", "$", "`", "\\", "(", ")", "{", "}", "[", "]", "!", ">", "<"]
        if command.contains(where: { dangerous.contains($0) }) {
            return jsonResponse(status: .badRequest, json: ["error": "Command contains disallowed characters"])
        }

        let ascBin = ProcessInfo.processInfo.arguments[0]
        let args = Array(parts.dropFirst())

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: ascBin)
                process.arguments = args

                var env = ProcessInfo.processInfo.environment
                env["NO_COLOR"] = "1"
                process.environment = env

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

                    continuation.resume(returning: jsonResponse(status: .ok, json: [
                        "stdout": stdout,
                        "stderr": stderr,
                        "exit_code": Int(process.terminationStatus),
                    ]))
                } catch {
                    continuation.resume(returning: jsonResponse(status: .internalServerError, json: ["error": error.localizedDescription]))
                }
            }
        }
    }

    // MARK: - Helpers

    private static func jsonResponse(status: HTTPResponse.Status, json: [String: Any]) -> Response {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            return Response(status: .internalServerError, body: .init(byteBuffer: .init(string: "JSON error")))
        }
        var headers: HTTPFields = [:]
        headers[.contentType] = "application/json"
        return Response(status: status, headers: headers, body: .init(byteBuffer: .init(data: data)))
    }
}

/// Middleware that serves static files from the bundled web directory.
struct StaticFileMiddleware: RouterMiddleware {
    let webRoot: URL

    func handle(_ request: Request, context: BasicRequestContext, next: (Request, BasicRequestContext) async throws -> Response) async throws -> Response {
        // Only handle GET requests
        guard request.method == .get else {
            return try await next(request, context)
        }

        let path = request.uri.path
        let filePath = (path == "/" || path.isEmpty) ? "/index.html" : path
        let cleanPath = filePath.components(separatedBy: "/").filter { $0 != ".." }.joined(separator: "/")
        let fileURL = webRoot.appendingPathComponent(cleanPath)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            // Try appending index.html for directory paths
            let indexURL = fileURL.appendingPathComponent("index.html")
            if FileManager.default.fileExists(atPath: indexURL.path),
               let data = try? Data(contentsOf: indexURL) {
                var headers: HTTPFields = [:]
                headers[.contentType] = "text/html; charset=utf-8"
                return Response(status: .ok, headers: headers, body: .init(byteBuffer: .init(data: data)))
            }
            return Response(status: .notFound, body: .init(byteBuffer: .init(string: "Not found")))
        }

        let contentType = WebServer.mimeType(for: fileURL.pathExtension)
        var headers: HTTPFields = [:]
        headers[.contentType] = contentType
        return Response(status: .ok, headers: headers, body: .init(byteBuffer: .init(data: data)))
    }
}

enum WebServerError: Error, CustomStringConvertible {
    case missingWebResources

    var description: String {
        "Web resources not found in bundle. This is a build issue."
    }
}
