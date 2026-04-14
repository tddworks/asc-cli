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
        let groups = response.data.map { mapBetaGroup($0, appIdHint: appId) }
        let nextCursor = response.links.next
        return PaginatedResponse(data: groups, nextCursor: nextCursor)
    }

    public func createBetaGroup(
        appId: String,
        name: String,
        isInternalGroup: Bool,
        publicLinkEnabled: Bool?,
        feedbackEnabled: Bool?
    ) async throws -> Domain.BetaGroup {
        let body = BetaGroupCreateRequest(data: .init(
            type: .betaGroups,
            attributes: .init(
                name: name,
                isInternalGroup: isInternalGroup,
                isPublicLinkEnabled: publicLinkEnabled,
                isFeedbackEnabled: feedbackEnabled
            ),
            relationships: .init(
                app: .init(data: .init(type: .apps, id: appId))
            )
        ))
        let response = try await client.request(APIEndpoint.v1.betaGroups.post(body))
        return mapBetaGroup(response.data, appIdHint: appId)
    }

    public func listBetaTesters(groupId: String, limit: Int?) async throws -> PaginatedResponse<Domain.BetaTester> {
        let request = APIEndpoint.v1.betaTesters.get(parameters: .init(
            filterBetaGroups: [groupId],
            limit: limit
        ))
        let response = try await client.request(request)
        let testers = response.data.map { mapBetaTester($0, groupId: groupId) }
        let nextCursor = response.links.next
        return PaginatedResponse(data: testers, nextCursor: nextCursor)
    }

    public func addBetaTester(groupId: String, email: String, firstName: String?, lastName: String?) async throws -> Domain.BetaTester {
        let body = BetaTesterCreateRequest(data: .init(
            type: .betaTesters,
            attributes: .init(firstName: firstName, lastName: lastName, email: email),
            relationships: .init(
                betaGroups: .init(data: [.init(type: .betaGroups, id: groupId)])
            )
        ))
        let response = try await client.request(APIEndpoint.v1.betaTesters.post(body))
        return mapBetaTester(response.data, groupId: groupId)
    }

    public func removeBetaTester(groupId: String, testerId: String) async throws {
        let body = BetaGroupBetaTestersLinkagesRequest(
            data: [.init(type: .betaTesters, id: testerId)]
        )
        try await client.request(APIEndpoint.v1.betaGroups.id(groupId).relationships.betaTesters.delete(body))
    }

    private func mapBetaGroup(_ sdkGroup: AppStoreConnect_Swift_SDK.BetaGroup, appIdHint: String?) -> Domain.BetaGroup {
        let appId = appIdHint ?? sdkGroup.relationships?.app?.data?.id ?? ""
        return Domain.BetaGroup(
            id: sdkGroup.id,
            appId: appId,
            name: sdkGroup.attributes?.name ?? "",
            isInternalGroup: sdkGroup.attributes?.isInternalGroup ?? false,
            publicLinkEnabled: sdkGroup.attributes?.isPublicLinkEnabled ?? false,
            createdDate: sdkGroup.attributes?.createdDate
        )
    }

    private func mapBetaTester(_ sdkTester: AppStoreConnect_Swift_SDK.BetaTester, groupId: String) -> Domain.BetaTester {
        Domain.BetaTester(
            id: sdkTester.id,
            groupId: groupId,
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
