@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKTestFlightRepositoryTests {

    @Test func `listBetaGroups maps name and isInternalGroup`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaGroupsResponse(
            data: [
                BetaGroup(
                    type: .betaGroups,
                    id: "group-1",
                    attributes: .init(name: "External Testers", isInternalGroup: false)
                ),
                BetaGroup(
                    type: .betaGroups,
                    id: "group-2",
                    attributes: .init(name: "Internal", isInternalGroup: true)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKTestFlightRepository(client: stub)
        let result = try await repo.listBetaGroups(appId: nil, limit: nil)

        #expect(result.data.count == 2)
        #expect(result.data[0].name == "External Testers")
        #expect(result.data[0].isInternalGroup == false)
        #expect(result.data[1].isInternalGroup == true)
    }

    @Test func `listBetaGroups injects appIdHint when provided`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaGroupsResponse(
            data: [
                BetaGroup(type: .betaGroups, id: "group-1", attributes: .init(name: "Beta"))
            ],
            links: .init(this: "")
        ))

        let repo = SDKTestFlightRepository(client: stub)
        let result = try await repo.listBetaGroups(appId: "app-42", limit: nil)

        #expect(result.data[0].appId == "app-42")
    }

    @Test func `listBetaTesters maps name and email with groupId injected`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaTestersResponse(
            data: [
                BetaTester(
                    type: .betaTesters,
                    id: "tester-1",
                    attributes: .init(firstName: "Jane", lastName: "Doe", email: "jane@example.com", inviteType: .email)
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKTestFlightRepository(client: stub)
        let result = try await repo.listBetaTesters(groupId: "group-99", limit: nil)

        #expect(result.data[0].firstName == "Jane")
        #expect(result.data[0].lastName == "Doe")
        #expect(result.data[0].email == "jane@example.com")
        #expect(result.data[0].groupId == "group-99")
    }

    @Test func `listBetaTesters maps inviteType email and publicLink`() async throws {
        let cases: [(BetaInviteType, Domain.BetaTester.InviteType)] = [
            (.email, .email),
            (.publicLink, .publicLink),
        ]

        for (sdkType, domainType) in cases {
            let stub = StubAPIClient()
            stub.willReturn(BetaTestersResponse(
                data: [
                    BetaTester(
                        type: .betaTesters,
                        id: "t-1",
                        attributes: .init(inviteType: sdkType)
                    ),
                ],
                links: .init(this: "")
            ))

            let repo = SDKTestFlightRepository(client: stub)
            let result = try await repo.listBetaTesters(groupId: "g-1", limit: nil)

            #expect(result.data[0].inviteType == domainType)
        }
    }

    @Test func `addBetaTester returns tester with injected groupId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaTesterResponse(
            data: BetaTester(
                type: .betaTesters,
                id: "t-new",
                attributes: .init(firstName: "New", lastName: nil, email: "new@example.com", inviteType: .email)
            ),
            links: .init(this: "")
        ))

        let repo = SDKTestFlightRepository(client: stub)
        let tester = try await repo.addBetaTester(groupId: "g-1", email: "new@example.com", firstName: "New", lastName: nil)

        #expect(tester.id == "t-new")
        #expect(tester.email == "new@example.com")
        #expect(tester.firstName == "New")
        #expect(tester.groupId == "g-1")
    }

    @Test func `createBetaGroup external returns group with appId injected`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaGroupResponse(
            data: BetaGroup(
                type: .betaGroups,
                id: "g-new",
                attributes: .init(name: "External Beta", isInternalGroup: false, isPublicLinkEnabled: true)
            ),
            links: .init(this: "")
        ))

        let repo = SDKTestFlightRepository(client: stub)
        let group = try await repo.createBetaGroup(
            appId: "app-1",
            name: "External Beta",
            isInternalGroup: false,
            publicLinkEnabled: true,
            feedbackEnabled: nil
        )

        #expect(group.id == "g-new")
        #expect(group.name == "External Beta")
        #expect(group.appId == "app-1")
        #expect(group.isInternalGroup == false)
        #expect(group.publicLinkEnabled == true)
    }

    @Test func `createBetaGroup internal returns group with isInternalGroup true`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(BetaGroupResponse(
            data: BetaGroup(
                type: .betaGroups,
                id: "g-int",
                attributes: .init(name: "Company Team", isInternalGroup: true)
            ),
            links: .init(this: "")
        ))

        let repo = SDKTestFlightRepository(client: stub)
        let group = try await repo.createBetaGroup(
            appId: "app-7",
            name: "Company Team",
            isInternalGroup: true,
            publicLinkEnabled: nil,
            feedbackEnabled: nil
        )

        #expect(group.id == "g-int")
        #expect(group.appId == "app-7")
        #expect(group.isInternalGroup == true)
    }

    @Test func `removeBetaTester calls void delete endpoint`() async throws {
        let stub = StubAPIClient()

        let repo = SDKTestFlightRepository(client: stub)
        try await repo.removeBetaTester(groupId: "g-1", testerId: "t-1")

        #expect(stub.voidRequestCalled == true)
    }
}
