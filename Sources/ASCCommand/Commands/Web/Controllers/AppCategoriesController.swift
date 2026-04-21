import Domain
import Hummingbird
import HummingbirdWebSocket
import Infrastructure

/// Routes that return `AppCategory` resources.
struct AppCategoriesController: Sendable {
    let repo: any AppCategoryRepository

    func addRoutes(to group: RouterGroup<BasicWebSocketRequestContext>) {
        group.get("/app-categories") { request, _ -> Response in
            let platform = request.uri.queryParameters["platform"].map(String.init)
            let categories = try await self.repo.listCategories(platform: platform)
            return try restFormat(categories)
        }

        group.get("/app-categories/:categoryId") { _, context -> Response in
            guard let categoryId = context.parameters.get("categoryId") else { return jsonError("Missing categoryId") }
            let category = try await self.repo.getCategory(id: categoryId)
            return try restFormat(category)
        }
    }
}
