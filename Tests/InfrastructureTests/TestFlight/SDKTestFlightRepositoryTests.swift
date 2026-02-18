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

    @Test func `listBetaTesters maps name and email`() async throws {
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
        let result = try await repo.listBetaTesters(groupId: nil, limit: nil)

        #expect(result.data[0].firstName == "Jane")
        #expect(result.data[0].lastName == "Doe")
        #expect(result.data[0].email == "jane@example.com")
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
            let result = try await repo.listBetaTesters(groupId: nil, limit: nil)

            #expect(result.data[0].inviteType == domainType)
        }
    }
}
