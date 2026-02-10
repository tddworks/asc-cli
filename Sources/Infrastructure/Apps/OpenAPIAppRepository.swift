import Domain
import OpenAPIRuntime

public struct OpenAPIAppRepository: AppRepository {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    public func listApps(limit: Int?) async throws -> PaginatedResponse<App> {
        let response = try await client.apps_hyphen_get_collection(
            query: .init(limit: limit)
        )

        switch response {
        case .ok(let okResponse):
            let body = try okResponse.body.json
            let apps = body.data.map { item in
                App(
                    id: item.id,
                    name: item.attributes?.name ?? "",
                    bundleId: item.attributes?.bundleId ?? "",
                    sku: item.attributes?.sku,
                    primaryLocale: item.attributes?.primaryLocale
                )
            }
            let nextCursor = body.links.next
            return PaginatedResponse(data: apps, nextCursor: nextCursor)

        case .badRequest:
            throw APIError.unknown("Bad request")
        case .forbidden:
            throw APIError.forbidden
        case .unauthorized:
            throw APIError.unauthorized
        case .undocumented(let statusCode, _):
            throw APIError.serverError(statusCode)
        }
    }

    public func getApp(id: String) async throws -> App {
        let response = try await client.apps_hyphen_get_instance(path: .init(id: id))

        switch response {
        case .ok(let okResponse):
            let body = try okResponse.body.json
            return App(
                id: body.data.id,
                name: body.data.attributes?.name ?? "",
                bundleId: body.data.attributes?.bundleId ?? "",
                sku: body.data.attributes?.sku,
                primaryLocale: body.data.attributes?.primaryLocale
            )

        case .badRequest:
            throw APIError.unknown("Bad request")
        case .forbidden:
            throw APIError.forbidden
        case .unauthorized:
            throw APIError.unauthorized
        case .notFound:
            throw APIError.notFound("App with id \(id) not found")
        case .undocumented(let statusCode, _):
            throw APIError.serverError(statusCode)
        }
    }
}
