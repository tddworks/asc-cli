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
        // The web client (cc.asccli.app and locally) uses the full REST
        // verb set: PATCH for partial updates (saveCategories, account
        // switch-active, …) and DELETE for resource removal (uninstall
        // plugin, sign out, delete localization). Without these listed,
        // browsers block the preflight and the request never fires.
        response.headers[.accessControlAllowMethods] = "GET, POST, PATCH, PUT, DELETE, OPTIONS"
        // Accept covers JSON content negotiation; Authorization is here
        // so future bearer-token auth doesn't need another CORS round-trip.
        response.headers[.accessControlAllowHeaders] = "Content-Type, Accept, Authorization"
        response.headers[HTTPField.Name("Access-Control-Allow-Private-Network")!] = "true"
    }
}
