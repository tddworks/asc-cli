import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct IAPUpdateTests {

    @Test func `updates iap reference name and review note and returns updated record`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        given(mockRepo).updateInAppPurchase(
            iapId: .any, referenceName: .any, reviewNote: .any, isFamilySharable: .any
        ).willReturn(InAppPurchase(
            id: "iap-1",
            appId: "",
            referenceName: "Gold Coins V2",
            productId: "com.app.gold",
            type: .consumable,
            state: .missingMetadata
        ))

        let cmd = try IAPUpdate.parse([
            "--iap-id", "iap-1",
            "--reference-name", "Gold Coins V2",
            "--review-note", "Test currency",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateInAppPurchase(
            iapId: .value("iap-1"),
            referenceName: .value("Gold Coins V2"),
            reviewNote: .value("Test currency"),
            isFamilySharable: .value(nil)
        ).called(1)
    }

    @Test func `family-sharable flag passes true to repo`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        given(mockRepo).updateInAppPurchase(
            iapId: .any, referenceName: .any, reviewNote: .any, isFamilySharable: .any
        ).willReturn(InAppPurchase(
            id: "iap-1", appId: "", referenceName: "X", productId: "com.x",
            type: .consumable, state: .missingMetadata
        ))

        let cmd = try IAPUpdate.parse(["--iap-id", "iap-1", "--family-sharable"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateInAppPurchase(
            iapId: .value("iap-1"), referenceName: .value(nil), reviewNote: .value(nil),
            isFamilySharable: .value(true)
        ).called(1)
    }

    @Test func `not-family-sharable flag passes false to repo`() async throws {
        let mockRepo = MockInAppPurchaseRepository()
        given(mockRepo).updateInAppPurchase(
            iapId: .any, referenceName: .any, reviewNote: .any, isFamilySharable: .any
        ).willReturn(InAppPurchase(
            id: "iap-1", appId: "", referenceName: "X", productId: "com.x",
            type: .consumable, state: .missingMetadata
        ))

        let cmd = try IAPUpdate.parse(["--iap-id", "iap-1", "--not-family-sharable"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateInAppPurchase(
            iapId: .value("iap-1"), referenceName: .value(nil), reviewNote: .value(nil),
            isFamilySharable: .value(false)
        ).called(1)
    }
}
