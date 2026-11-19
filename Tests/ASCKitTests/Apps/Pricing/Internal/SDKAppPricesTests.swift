@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import ASCKit

@Suite
struct SDKAppPricesTests {

    @Test func `hasPricing returns true when price schedule exists`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPriceScheduleResponse(
            data: AppPriceSchedule(
                type: .appPriceSchedules,
                id: "ps-1"
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppPrices(client: stub)
        let result = try await repo.hasPricing(appId: "app-1")
        #expect(result == true)
    }

    @Test func `hasPricing returns false when request throws`() async throws {
        let stub = ThrowingStubAPIClient()

        let repo = SDKAppPrices(client: stub)
        let result = try await repo.hasPricing(appId: "app-no-pricing")
        #expect(result == false)
    }
}

/// A stub client that always throws an error, used to simulate missing resources.
private final class ThrowingStubAPIClient: APIClient, @unchecked Sendable {
    func request<T: Decodable>(_ endpoint: Request<T>) async throws -> T {
        throw URLError(.badServerResponse)
    }
    func request(_ endpoint: Request<Void>) async throws {
        throw URLError(.badServerResponse)
    }

    // MARK: - Setting the app's price

    @Test func `price points for a territory carry the app, territory and price, across every page`() async throws {
        func page(_ range: Range<Int>, nextCursor: String?) -> AppPricePointsV3Response {
            AppPricePointsV3Response(
                data: range.map { AppPricePointV3(type: .appPricePoints, id: "pp-\($0)",
                                                   attributes: .init(customerPrice: "\($0).99", proceeds: "\($0).50")) },
                links: .init(this: ""),
                meta: .init(paging: .init(total: 250, limit: 200, nextCursor: nextCursor))
            )
        }
        let stub = StubAPIClient()
        stub.willReturnPages([page(0..<200, nextCursor: "page-2"), page(200..<250, nextCursor: nil)])

        let repo = SDKAppPrices(client: stub)
        let points = try await repo.listPricePoints(appId: "app-1", territory: "USA")

        #expect(points.count == 250)
        #expect(points.last == ASCKit.AppPricePoint(id: "pp-249", appId: "app-1", territory: "USA",
                                                    customerPrice: "249.99", proceeds: "249.50"))
        let query = Dictionary(uniqueKeysWithValues: (stub.requests.first?.query ?? []).map { ($0.0, $0.1 ?? "") })
        #expect(stub.requests.first?.path == "/v1/apps/app-1/appPricePoints")
        #expect(query["filter[territory]"] == "USA")
    }

    @Test func `setting the price creates a schedule with the price point as the base-territory price`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppPriceScheduleResponse(
            data: .init(type: .appPriceSchedules, id: "sched-1"), links: .init(this: "")
        ))

        let repo = SDKAppPrices(client: stub)
        let schedule = try await repo.setPriceSchedule(appId: "app-1", baseTerritory: "USA", pricePointId: "pp-9")

        #expect(schedule == ASCKit.AppPriceSchedule(id: "sched-1", appId: "app-1", baseTerritory: "USA"))
        let post = stub.requests.first { $0.method == "POST" }
        #expect(post?.path == "/v1/appPriceSchedules")
        #expect(post?.body == #"{"data":{"relationships":{"app":{"data":{"id":"app-1","type":"apps"}},"baseTerritory":{"data":{"id":"USA","type":"territories"}},"manualPrices":{"data":[{"id":"${local-app-price-1}","type":"appPrices"}]}},"type":"appPriceSchedules"},"included":[{"id":"${local-app-price-1}","relationships":{"appPricePoint":{"data":{"id":"pp-9","type":"appPricePoints"}}},"type":"appPrices"}]}"#)
    }
}
