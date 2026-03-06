@preconcurrency import AppStoreConnect_Swift_SDK
import Domain
import Foundation

public struct SDKUserRepository: UserRepository, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listUsers(role: Domain.UserRole?) async throws -> [Domain.TeamMember] {
        let filterRole = role.flatMap {
            APIEndpoint.V1.Users.GetParameters.FilterRoles(rawValue: $0.rawValue)
        }
        let request = APIEndpoint.v1.users.get(parameters: .init(
            filterRoles: filterRole.map { [$0] }
        ))
        let response = try await client.request(request)
        return response.data.map(mapTeamMember)
    }

    public func updateUser(id: String, roles: [Domain.UserRole]) async throws -> Domain.TeamMember {
        let sdkRoles = roles.compactMap { AppStoreConnect_Swift_SDK.UserRole(rawValue: $0.rawValue) }
        let body = UserUpdateRequest(data: .init(
            type: .users,
            id: id,
            attributes: .init(roles: sdkRoles)
        ))
        let response = try await client.request(APIEndpoint.v1.users.id(id).patch(body))
        return mapTeamMember(response.data)
    }

    public func removeUser(id: String) async throws {
        try await client.request(APIEndpoint.v1.users.id(id).delete)
    }

    public func listUserInvitations(role: Domain.UserRole?) async throws -> [Domain.UserInvitationRecord] {
        let filterRole = role.flatMap {
            APIEndpoint.V1.UserInvitations.GetParameters.FilterRoles(rawValue: $0.rawValue)
        }
        let request = APIEndpoint.v1.userInvitations.get(parameters: .init(
            filterRoles: filterRole.map { [$0] }
        ))
        let response = try await client.request(request)
        return response.data.map(mapInvitation)
    }

    public func inviteUser(
        email: String,
        firstName: String,
        lastName: String,
        roles: [Domain.UserRole],
        allAppsVisible: Bool
    ) async throws -> Domain.UserInvitationRecord {
        let sdkRoles = roles.compactMap { AppStoreConnect_Swift_SDK.UserRole(rawValue: $0.rawValue) }
        let body = UserInvitationCreateRequest(data: .init(
            type: .userInvitations,
            attributes: .init(
                email: email,
                firstName: firstName,
                lastName: lastName,
                roles: sdkRoles,
                isAllAppsVisible: allAppsVisible
            )
        ))
        let response = try await client.request(APIEndpoint.v1.userInvitations.post(body))
        return mapInvitation(response.data)
    }

    public func cancelUserInvitation(id: String) async throws {
        try await client.request(APIEndpoint.v1.userInvitations.id(id).delete)
    }

    // MARK: - Mappers

    private func mapTeamMember(_ sdk: AppStoreConnect_Swift_SDK.User) -> Domain.TeamMember {
        let roles = (sdk.attributes?.roles ?? []).compactMap {
            Domain.UserRole(rawValue: $0.rawValue)
        }
        return Domain.TeamMember(
            id: sdk.id,
            username: sdk.attributes?.username ?? "",
            firstName: sdk.attributes?.firstName ?? "",
            lastName: sdk.attributes?.lastName ?? "",
            roles: roles,
            isAllAppsVisible: sdk.attributes?.isAllAppsVisible ?? false,
            isProvisioningAllowed: sdk.attributes?.isProvisioningAllowed ?? false
        )
    }

    private func mapInvitation(_ sdk: AppStoreConnect_Swift_SDK.UserInvitation) -> Domain.UserInvitationRecord {
        let roles = (sdk.attributes?.roles ?? []).compactMap {
            Domain.UserRole(rawValue: $0.rawValue)
        }
        return Domain.UserInvitationRecord(
            id: sdk.id,
            email: sdk.attributes?.email ?? "",
            firstName: sdk.attributes?.firstName ?? "",
            lastName: sdk.attributes?.lastName ?? "",
            roles: roles,
            expirationDate: sdk.attributes?.expirationDate,
            isAllAppsVisible: sdk.attributes?.isAllAppsVisible ?? false,
            isProvisioningAllowed: sdk.attributes?.isProvisioningAllowed ?? false
        )
    }
}
