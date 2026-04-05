import Domain
import Hummingbird
import Infrastructure
import ASCPlugin

/// Composes all REST API v1 route files into a single configurator.
/// Each domain has its own route file in `Routes/` following
/// the `enum + static register(on:)` pattern.
enum RESTRoutes {

    @Sendable
    static func configure(router: ASCRouter) {
        // Entry point
        RootRoutes.register(on: router)

        // Domain routes (grouped under /api/v1)
        let v1 = router.group("/api/v1")
        AppsRoutes.register(on: v1)
        CodeSigningRoutes.register(on: v1)
        SimulatorsRoutes.register(on: v1)
        PluginsRoutes.register(on: v1)
        TerritoriesRoutes.register(on: v1)
        AppShotsRoutes.register(on: v1)
    }
}

// MARK: - Shared response helpers for route files

/// Returns a JSON response from a pre-encoded JSON string.
func restResponse(_ json: String, status: HTTPResponse.Status = .ok) -> Response {
    let buffer = ByteBuffer(string: json)
    return Response(
        status: status,
        headers: [.contentType: "application/json; charset=utf-8"],
        body: .init(byteBuffer: buffer)
    )
}
