@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import ASCKit

@Suite
struct SDKUsersTests {

    @Test func `listUsers maps username roles and visibility`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(UsersResponse(
            data: [
                AppStoreConnect_Swift_SDK.User(
                    type: .users,
                    id: "u-1",
                    attributes: .init(
                        username: "jdoe@example.com",
                        firstName: "Jane",
                        lastName: "Doe",
                        roles: [.developer, .appManager],
                        isAllAppsVisible: false,
                        isProvisioningAllowed: true
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKUsers(client: stub)
        let result = try await repo.listUsers(role: nil)

        #expect(result[0].id == "u-1")
        #expect(result[0].username == "jdoe@example.com")
        #expect(result[0].firstName == "Jane")
        #expect(result[0].lastName == "Doe")
        #expect(result[0].roles == [.developer, .appManager])
        #expect(result[0].isAllAppsVisible == false)
        #expect(result[0].isProvisioningAllowed == true)
    }

    @Test func `removeUser calls void endpoint`() async throws {
        let stub = StubAPIClient()
        let repo = SDKUsers(client: stub)

        try await repo.removeUser(id: "u-1")

        #expect(stub.voidRequestCalled == true)
    }

    @Test func `cancelUserInvitation calls void endpoint`() async throws {
        let stub = StubAPIClient()
        let repo = SDKUsers(client: stub)

        try await repo.cancelUserInvitation(id: "inv-1")

        #expect(stub.voidRequestCalled == true)
    }

    @Test func `listUserInvitations maps email roles and expiration`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(UserInvitationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.UserInvitation(
                    type: .userInvitations,
                    id: "inv-1",
                    attributes: .init(
                        email: "new@example.com",
                        firstName: "New",
                        lastName: "User",
                        expirationDate: nil,
                        roles: [.developer],
                        isAllAppsVisible: true,
                        isProvisioningAllowed: false
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKUsers(client: stub)
        let result = try await repo.listUserInvitations(role: nil)

        #expect(result[0].id == "inv-1")
        #expect(result[0].email == "new@example.com")
        #expect(result[0].roles == [.developer])
        #expect(result[0].isAllAppsVisible == true)
        #expect(result[0].expirationDate == nil)
    }

    @Test func `updateUser maps returned team member`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(UserResponse(
            data: AppStoreConnect_Swift_SDK.User(
                type: .users,
                id: "u-1",
                attributes: .init(
                    username: "jdoe@example.com",
                    firstName: "Jane",
                    lastName: "Doe",
                    roles: [.admin],
                    isAllAppsVisible: true,
                    isProvisioningAllowed: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKUsers(client: stub)
        let result = try await repo.updateUser(id: "u-1", roles: [.admin])

        #expect(result.id == "u-1")
        #expect(result.roles == [.admin])
        #expect(result.isAllAppsVisible == true)
    }

    @Test func `inviteUser maps returned invitation record`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(UserInvitationResponse(
            data: AppStoreConnect_Swift_SDK.UserInvitation(
                type: .userInvitations,
                id: "inv-2",
                attributes: .init(
                    email: "hire@example.com",
                    firstName: "Alex",
                    lastName: "Smith",
                    expirationDate: nil,
                    roles: [.developer],
                    isAllAppsVisible: false,
                    isProvisioningAllowed: false
                )
            ),
            links: .init(this: "")
        ))

        let repo = SDKUsers(client: stub)
        let result = try await repo.inviteUser(
            email: "hire@example.com",
            firstName: "Alex",
            lastName: "Smith",
            roles: [.developer],
            allAppsVisible: false
        )

        #expect(result.id == "inv-2")
        #expect(result.email == "hire@example.com")
        #expect(result.firstName == "Alex")
        #expect(result.roles == [.developer])
    }

    @Test func `listUsers with role filter passes filter to request`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(UsersResponse(
            data: [
                AppStoreConnect_Swift_SDK.User(
                    type: .users,
                    id: "u-2",
                    attributes: .init(roles: [.admin])
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKUsers(client: stub)
        let result = try await repo.listUsers(role: .admin)

        #expect(result[0].roles == [.admin])
    }

    @Test func `listUserInvitations with role filter returns filtered results`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(UserInvitationsResponse(
            data: [
                AppStoreConnect_Swift_SDK.UserInvitation(
                    type: .userInvitations,
                    id: "inv-3",
                    attributes: .init(
                        email: "admin@example.com",
                        firstName: "A",
                        lastName: "B",
                        roles: [.admin],
                        isAllAppsVisible: false,
                        isProvisioningAllowed: false
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKUsers(client: stub)
        let result = try await repo.listUserInvitations(role: .admin)

        #expect(result[0].roles == [.admin])
    }

    @Test func `users list includes every team member beyond the first page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> UsersResponse {
            UsersResponse(
                data: range.map { i in AppStoreConnect_Swift_SDK.User(type: .users, id: "item-\(i)", attributes: .init(username: "u\(i)@example.com", roles: [.developer])) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 75, limit: 50, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<50, nextCursor: "page-2"), page(50..<75, nextCursor: nil)])

        let repo = SDKUsers(client: stub)
        let result = try await repo.listUsers(role: nil)

        #expect(result.count == 75)
        #expect(result.last?.id == "item-74")
    }
}
