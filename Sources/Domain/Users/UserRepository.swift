import Mockable

@Mockable
public protocol UserRepository: Sendable {
    func listUsers(role: UserRole?) async throws -> [TeamMember]
    func updateUser(id: String, roles: [UserRole]) async throws -> TeamMember
    func removeUser(id: String) async throws
    func listUserInvitations(role: UserRole?) async throws -> [UserInvitationRecord]
    func inviteUser(email: String, firstName: String, lastName: String, roles: [UserRole], allAppsVisible: Bool) async throws -> UserInvitationRecord
    func cancelUserInvitation(id: String) async throws
}
