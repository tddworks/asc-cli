import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionPricesSetTests {

    @Test func `set price posts subscriptionId, territory and pricePointId`() async throws {
        let mockRepo = MockSubscriptionPriceRepository()
        given(mockRepo).setPrice(
            subscriptionId: .any, territory: .any, pricePointId: .any,
            startDate: .any, preserveCurrentPrice: .any
        ).willReturn(SubscriptionPrice(id: "price-1", subscriptionId: "sub-1"))

        let cmd = try SubscriptionPricesSet.parse([
            "--subscription-id", "sub-1",
            "--territory", "USA",
            "--price-point-id", "pp-1",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).setPrice(
            subscriptionId: .value("sub-1"),
            territory: .value("USA"),
            pricePointId: .value("pp-1"),
            startDate: .value(nil),
            preserveCurrentPrice: .value(nil)
        ).called(1)
    }

    @Test func `start-date and preserve-current-price flag pass through`() async throws {
        let mockRepo = MockSubscriptionPriceRepository()
        given(mockRepo).setPrice(
            subscriptionId: .any, territory: .any, pricePointId: .any,
            startDate: .any, preserveCurrentPrice: .any
        ).willReturn(SubscriptionPrice(id: "price-1", subscriptionId: "sub-1"))

        let cmd = try SubscriptionPricesSet.parse([
            "--subscription-id", "sub-1",
            "--territory", "USA",
            "--price-point-id", "pp-1",
            "--start-date", "2026-06-01",
            "--preserve-current-price",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).setPrice(
            subscriptionId: .value("sub-1"),
            territory: .value("USA"),
            pricePointId: .value("pp-1"),
            startDate: .value("2026-06-01"),
            preserveCurrentPrice: .value(true)
        ).called(1)
    }
}
