import Domain
import OpenAPIRuntime

public struct OpenAPIBuildRepository: BuildRepository {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    public func listBuilds(appId: String?, limit: Int?) async throws -> PaginatedResponse<Build> {
        var filterAppId: [String]?
        if let appId {
            filterAppId = [appId]
        }

        let response = try await client.builds_hyphen_get_collection(
            query: .init(
                filter_lbrack_app_rbrack_: filterAppId,
                limit: limit
            )
        )

        switch response {
        case .ok(let okResponse):
            let body = try okResponse.body.json
            let builds = body.data.map { item in
                Build(
                    id: item.id,
                    version: item.attributes?.version ?? "",
                    uploadedDate: item.attributes?.uploadedDate.flatMap { parseDate($0) },
                    expirationDate: item.attributes?.expirationDate.flatMap { parseDate($0) },
                    expired: item.attributes?.expired ?? false,
                    processingState: mapProcessingState(item.attributes?.processingState),
                    buildNumber: nil
                )
            }
            let nextCursor = body.links.next
            return PaginatedResponse(data: builds, nextCursor: nextCursor)

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

    public func getBuild(id: String) async throws -> Build {
        let response = try await client.builds_hyphen_get_instance(path: .init(id: id))

        switch response {
        case .ok(let okResponse):
            let body = try okResponse.body.json
            return Build(
                id: body.data.id,
                version: body.data.attributes?.version ?? "",
                uploadedDate: body.data.attributes?.uploadedDate.flatMap { parseDate($0) },
                expirationDate: body.data.attributes?.expirationDate.flatMap { parseDate($0) },
                expired: body.data.attributes?.expired ?? false,
                processingState: mapProcessingState(body.data.attributes?.processingState),
                buildNumber: nil
            )

        case .badRequest:
            throw APIError.unknown("Bad request")
        case .forbidden:
            throw APIError.forbidden
        case .unauthorized:
            throw APIError.unauthorized
        case .notFound:
            throw APIError.notFound("Build with id \(id) not found")
        case .undocumented(let statusCode, _):
            throw APIError.serverError(statusCode)
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    private func mapProcessingState(_ state: Components.Schemas.BuildAttributes.processingStatePayload?) -> Build.ProcessingState {
        guard let state else { return .processing }
        switch state {
        case .PROCESSING: return .processing
        case .FAILED: return .failed
        case .INVALID: return .invalid
        case .VALID: return .valid
        }
    }
}
