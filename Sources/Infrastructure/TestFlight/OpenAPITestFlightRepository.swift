@preconcurrency import AppStoreConnect_Swift_SDK
import Domain

public struct SDKTestFlightRepository: TestFlightRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listBetaGroups(appId: String?, limit: Int?) async throws -> PaginatedResponse<Domain.BetaGroup> {
        var filterApp: [String]?
        if let appId {
            filterApp = [appId]
        }

        let request = APIEndpoint.v1.betaGroups.get(parameters: .init(
            filterApp: filterApp,
            limit: limit
        ))
        let response = try await client.request(request)
        let groups = response.data.map { mapBetaGroup($0) }
        let nextCursor = response.links.next
        return PaginatedResponse(data: groups, nextCursor: nextCursor)
    }

    public func listBetaTesters(groupId: String?, limit: Int?) async throws -> PaginatedResponse<Domain.BetaTester> {
        let request = APIEndpoint.v1.betaTesters.get(parameters: .init(
            limit: limit
        ))
        let response = try await client.request(request)
        let testers = response.data.map { mapBetaTester($0) }
        let nextCursor = response.links.next
        return PaginatedResponse(data: testers, nextCursor: nextCursor)
    }

    private func mapBetaGroup(_ sdkGroup: AppStoreConnect_Swift_SDK.BetaGroup) -> Domain.BetaGroup {
        Domain.BetaGroup(
            id: sdkGroup.id,
            name: sdkGroup.attributes?.name ?? "",
            isInternalGroup: sdkGroup.attributes?.isInternalGroup ?? false,
            publicLinkEnabled: sdkGroup.attributes?.isPublicLinkEnabled ?? false,
            createdDate: sdkGroup.attributes?.createdDate
        )
    }

    private func mapBetaTester(_ sdkTester: AppStoreConnect_Swift_SDK.BetaTester) -> Domain.BetaTester {
        Domain.BetaTester(
            id: sdkTester.id,
            firstName: sdkTester.attributes?.firstName,
            lastName: sdkTester.attributes?.lastName,
            email: sdkTester.attributes?.email,
            inviteType: mapInviteType(sdkTester.attributes?.inviteType)
        )
    }

    private func mapInviteType(_ type: AppStoreConnect_Swift_SDK.BetaInviteType?) -> Domain.BetaTester.InviteType? {
        guard let type else { return nil }
        switch type {
        case .email: return .email
        case .publicLink: return .publicLink
        }
    }
}
