import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

private func makePromoted(id: String = "pp-1", appId: String = "app-1") -> PromotedPurchase {
    PromotedPurchase(id: id, appId: appId, isVisibleForAllUsers: true, isEnabled: true,
                     state: .approved, inAppPurchaseId: "iap-1")
}

@Suite
struct PromotedPurchasesListTests {

    @Test func `list returns promoted purchases with affordances`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        given(mockRepo).listPromotedPurchases(appId: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [makePromoted()], nextCursor: nil))

        let cmd = try PromotedPurchasesList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\" : \"pp-1\""))
        #expect(output.contains("\"appId\" : \"app-1\""))
        #expect(output.contains("\"inAppPurchaseId\" : \"iap-1\""))
        #expect(output.contains("\"listSiblings\" : \"asc promoted-purchases list --app-id app-1\""))
    }
}

@Suite
struct PromotedPurchasesCreateTests {

    @Test func `requires either iap-id or subscription-id`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        let cmd = try PromotedPurchasesCreate.parse(["--app-id", "app-1"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `iap-id and subscription-id are mutually exclusive`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        let cmd = try PromotedPurchasesCreate.parse([
            "--app-id", "app-1",
            "--iap-id", "iap-1",
            "--subscription-id", "sub-1",
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `passes iap-id to repo`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        given(mockRepo).createPromotedPurchase(
            appId: .any, isVisibleForAllUsers: .any, isEnabled: .any,
            inAppPurchaseId: .any, subscriptionId: .any
        ).willReturn(makePromoted())

        let cmd = try PromotedPurchasesCreate.parse([
            "--app-id", "app-1",
            "--iap-id", "iap-1",
            "--enabled",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createPromotedPurchase(
            appId: .value("app-1"),
            isVisibleForAllUsers: .value(true),
            isEnabled: .value(true),
            inAppPurchaseId: .value("iap-1"),
            subscriptionId: .value(nil)
        ).called(1)
    }

    @Test func `hidden flag passes false visibility`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        given(mockRepo).createPromotedPurchase(
            appId: .any, isVisibleForAllUsers: .any, isEnabled: .any,
            inAppPurchaseId: .any, subscriptionId: .any
        ).willReturn(makePromoted())

        let cmd = try PromotedPurchasesCreate.parse([
            "--app-id", "app-1",
            "--subscription-id", "sub-1",
            "--hidden",
            "--disabled",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).createPromotedPurchase(
            appId: .value("app-1"),
            isVisibleForAllUsers: .value(false),
            isEnabled: .value(false),
            inAppPurchaseId: .value(nil),
            subscriptionId: .value("sub-1")
        ).called(1)
    }
}

@Suite
struct PromotedPurchasesUpdateTests {

    @Test func `update passes visibility and enabled flags`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        given(mockRepo).updatePromotedPurchase(
            promotedId: .any, isVisibleForAllUsers: .any, isEnabled: .any
        ).willReturn(makePromoted())

        let cmd = try PromotedPurchasesUpdate.parse([
            "--promoted-id", "pp-1",
            "--visible",
            "--disabled",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updatePromotedPurchase(
            promotedId: .value("pp-1"),
            isVisibleForAllUsers: .value(true),
            isEnabled: .value(false)
        ).called(1)
    }
}

@Suite
struct PromotedPurchasesDeleteTests {

    @Test func `delete calls repo with promoted-id`() async throws {
        let mockRepo = MockPromotedPurchaseRepository()
        given(mockRepo).deletePromotedPurchase(promotedId: .any).willReturn(())

        let cmd = try PromotedPurchasesDelete.parse(["--promoted-id", "pp-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deletePromotedPurchase(promotedId: .value("pp-1")).called(1)
    }
}
