@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKUserRepositoryTests {

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

        let repo = SDKUserRepository(client: stub)
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
        let repo = SDKUserRepository(client: stub)

        try await repo.removeUser(id: "u-1")

        #expect(stub.voidRequestCalled == true)
    }

    @Test func `cancelUserInvitation calls void endpoint`() async throws {
        let stub = StubAPIClient()
        let repo = SDKUserRepository(client: stub)

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

        let repo = SDKUserRepository(client: stub)
        let result = try await repo.listUserInvitations(role: nil)

        #expect(result[0].id == "inv-1")
        #expect(result[0].email == "new@example.com")
        #expect(result[0].roles == [.developer])
        #expect(result[0].isAllAppsVisible == true)
        #expect(result[0].expirationDate == nil)
    }
}
