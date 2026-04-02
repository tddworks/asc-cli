import Foundation
import ASCPlugin
import Domain
import Hummingbird

// MARK: - Entry point (required)

/// The C entry point that ASC discovers via `dlsym`.
/// This is called once at startup when the plugin is loaded.
@_cdecl("ascPlugin")
public func ascPlugin() -> UnsafeMutableRawPointer {
    let plugin = HelloPlugin()

    // Register affordances on domain models.
    // This adds a "greet" button to every app in the web UI.
    AffordanceRegistry.register(App.self) { id, props in
        let name = props["name"] ?? id
        return ["greet": "asc hello greet --app-id \(id) --name \(name)"]
    }

    return Unmanaged.passRetained(plugin).toOpaque()
}

// MARK: - Plugin

public final class HelloPlugin: NSObject, ASCPluginBase {
    public let name = "Hello Plugin"
    public var commands: [Any] { [] }

    public func configureRoutes(_ routerPtr: Any) {
        guard let ptr = routerPtr as? UnsafeMutableRawPointer else { return }
        let router = Unmanaged<ASCRouter>.fromOpaque(ptr).takeUnretainedValue()

        // GET /api/hello — simple JSON response
        router.get("/api/hello") { _, _ in
            let data = try! JSONSerialization.data(withJSONObject: [
                "message": "Hello from the example plugin!",
                "timestamp": ISO8601DateFormatter().string(from: Date()),
            ])
            return Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: ByteBuffer(data: data))
            )
        }

        // GET /api/hello/greet?name=World — called by the UI affordance handler
        router.get("/api/hello/greet") { request, _ in
            let name = request.uri.queryParameters.get("name") ?? "World"
            let data = try! JSONSerialization.data(withJSONObject: [
                "message": "Hello, \(name)!",
            ])
            return Response(
                status: .ok,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: ByteBuffer(data: data))
            )
        }
    }
}
