import Domain
import OpenAPIRuntime

public struct OpenAPITestFlightRepository: TestFlightRepository {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    public func listBetaGroups(appId: String?, limit: Int?) async throws -> PaginatedResponse<BetaGroup> {
        var filterApp: [String]?
        if let appId {
            filterApp = [appId]
        }

        let response = try await client.betaGroups_hyphen_get_collection(
            query: .init(
                filter_lbrack_app_rbrack_: filterApp,
                limit: limit
            )
        )

        switch response {
        case .ok(let okResponse):
            let body = try okResponse.body.json
            let groups = body.data.map { item in
                BetaGroup(
                    id: item.id,
                    name: item.attributes?.name ?? "",
                    isInternalGroup: item.attributes?.isInternalGroup ?? false,
                    publicLinkEnabled: item.attributes?.publicLinkEnabled ?? false,
                    createdDate: item.attributes?.createdDate.flatMap { parseDate($0) }
                )
            }
            let nextCursor = body.links.next
            return PaginatedResponse(data: groups, nextCursor: nextCursor)

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

    public func listBetaTesters(groupId: String?, limit: Int?) async throws -> PaginatedResponse<BetaTester> {
        let response = try await client.betaTesters_hyphen_get_collection(
            query: .init(limit: limit)
        )

        switch response {
        case .ok(let okResponse):
            let body = try okResponse.body.json
            let testers = body.data.map { item in
                BetaTester(
                    id: item.id,
                    firstName: item.attributes?.firstName,
                    lastName: item.attributes?.lastName,
                    email: item.attributes?.email,
                    inviteType: mapInviteType(item.attributes?.inviteType)
                )
            }
            let nextCursor = body.links.next
            return PaginatedResponse(data: testers, nextCursor: nextCursor)

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

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }

    private func mapInviteType(_ type: Components.Schemas.BetaTesterAttributes.inviteTypePayload?) -> BetaTester.InviteType? {
        guard let type else { return nil }
        switch type {
        case .EMAIL: return .email
        case .PUBLIC_LINK: return .publicLink
        }
    }
}
