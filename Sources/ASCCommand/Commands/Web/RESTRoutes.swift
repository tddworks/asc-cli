import Domain
import Hummingbird
import Infrastructure
import ASCPlugin
import Foundation

/// Composes all REST API v1 route files into a single configurator.
/// Each domain has its own route file in `Routes/` following OCP —
/// adding a new domain = add one file, register it here.
enum RESTRoutes {

    @Sendable
    static func configure(router: ASCRouter) {
        RootRoutes.register(on: router)

        let v1 = router.group("/api/v1")
        AppsRoutes.register(on: v1)
        CodeSigningRoutes.register(on: v1)
        SimulatorsRoutes.register(on: v1)
        PluginsRoutes.register(on: v1)
        TerritoriesRoutes.register(on: v1)
        AppShotsRoutes.register(on: v1)
    }
}

// MARK: - Shared response helpers for all route files

/// Execute a command and return its output as a JSON response.
/// Catches errors and returns them as JSON error responses.
func restExec(_ block: () async throws -> String) async throws -> Response {
    do {
        let output = try await block()
        return restResponse(output)
    } catch {
        return jsonError(error.localizedDescription, status: .internalServerError)
    }
}

/// Returns a JSON response from a pre-encoded JSON string.
func restResponse(_ json: String, status: HTTPResponse.Status = .ok) -> Response {
    Response(
        status: status,
        headers: [.contentType: "application/json; charset=utf-8"],
        body: .init(byteBuffer: ByteBuffer(string: json))
    )
}

/// Write base64 screenshot to a temp file. Returns the file path.
func writeTempScreenshot(_ base64: String?) throws -> String {
    guard let b64 = base64, let data = Data(base64Encoded: b64) else {
        return "screenshot.png"
    }
    let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("blitz-\(UUID().uuidString).png")
    try data.write(to: tmpFile)
    return tmpFile.path
}

/// Encode a dictionary to a JSON string.
func jsonEncode(_ dict: [String: Any]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else { return "{}" }
    return String(data: data, encoding: .utf8) ?? "{}"
}
