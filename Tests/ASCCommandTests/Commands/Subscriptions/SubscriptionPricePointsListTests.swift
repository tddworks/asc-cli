import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SubscriptionPricePointsListTests {

    @Test func `listed price points include subscriptionId, territory, prices and affordances`() async throws {
        let mockRepo = MockSubscriptionPriceRepository()
        given(mockRepo).listPricePoints(subscriptionId: .any, territory: .any, limit: .any, cursor: .any)
            .willReturn(PaginatedResponse(data: [
                SubscriptionPricePoint(
                    id: "pp-tier1",
                    subscriptionId: "sub-1",
                    territory: "USA",
                    customerPrice: "9.99",
                    proceeds: "6.99",
                    proceedsYear2: "7.49"
                )
            ], nextCursor: nil))

        let cmd = try SubscriptionPricePointsList.parse([
            "--subscription-id", "sub-1",
            "--territory", "USA",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listPricePoints" : "asc subscriptions price-points list --subscription-id sub-1",
                "setPrice" : "asc subscriptions prices set --price-point-id pp-tier1 --subscription-id sub-1 --territory USA"
              },
              "customerPrice" : "9.99",
              "id" : "pp-tier1",
              "proceeds" : "6.99",
              "proceedsYear2" : "7.49",
              "subscriptionId" : "sub-1",
              "territory" : "USA"
            }
          ]
        }
        """)
        verify(mockRepo).listPricePoints(
            subscriptionId: .value("sub-1"),
            territory: .value("USA"),
            limit: .value(nil),
            cursor: .value(nil)
        ).called(1)
    }

    @Test func `passes nil territory when flag omitted`() async throws {
        let mockRepo = MockSubscriptionPriceRepository()
        given(mockRepo).listPricePoints(subscriptionId: .any, territory: .any, limit: .any, cursor: .any)
            .willReturn(PaginatedResponse(data: [], nextCursor: nil))

        let cmd = try SubscriptionPricePointsList.parse(["--subscription-id", "sub-1"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).listPricePoints(
            subscriptionId: .value("sub-1"),
            territory: .value(nil),
            limit: .value(nil),
            cursor: .value(nil)
        ).called(1)
    }
}
