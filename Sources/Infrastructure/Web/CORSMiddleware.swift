import Hummingbird
import HTTPTypes

/// CORS middleware for cross-origin requests from asccli.app to localhost.
struct CORSMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        if request.method == .options {
            var response = Response(status: .noContent)
            applyCORS(&response)
            return response
        }
        var response = try await next(request, context)
        applyCORS(&response)
        return response
    }

    private func applyCORS(_ response: inout Response) {
        response.headers[.accessControlAllowOrigin] = "*"
        response.headers[.accessControlAllowMethods] = "GET, POST, OPTIONS"
        response.headers[.accessControlAllowHeaders] = "Content-Type"
        response.headers[HTTPField.Name("Access-Control-Allow-Private-Network")!] = "true"
    }
}
