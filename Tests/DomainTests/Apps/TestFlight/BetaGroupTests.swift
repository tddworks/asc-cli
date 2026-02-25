import Testing
@testable import Domain

@Suite
struct BetaGroupTests {

    // MARK: - Parent ID

    @Test func `beta group carries appId`() {
        let group = MockRepositoryFactory.makeBetaGroup(id: "g-1", appId: "app-42")
        #expect(group.appId == "app-42")
    }

    // MARK: - Affordances

    @Test func `beta group affordances include listTesters`() {
        let group = MockRepositoryFactory.makeBetaGroup(id: "g-1")
        #expect(group.affordances["listTesters"] == "asc testflight testers list --group-id g-1")
    }

    @Test func `beta group affordances include importTesters with default filename`() {
        let group = MockRepositoryFactory.makeBetaGroup(id: "g-1")
        #expect(group.affordances["importTesters"] == "asc testflight testers import --group-id g-1 --file testers.csv")
    }

    @Test func `beta group affordances include exportTesters`() {
        let group = MockRepositoryFactory.makeBetaGroup(id: "g-1")
        #expect(group.affordances["exportTesters"] == "asc testflight testers export --group-id g-1")
    }
}
