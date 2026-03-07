@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKXcodeCloudProductRepositoryTests {

    @Test func `listProducts maps name and productType from SDK response`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiProductsResponse(
            data: [
                CiProduct(
                    type: .ciProducts,
                    id: "prod-1",
                    attributes: .init(name: "My App CI", productType: .app),
                    relationships: .init(
                        app: .init(data: .init(type: .apps, id: "app-42"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudProductRepository(client: stub)
        let result = try await repo.listProducts(appId: nil)

        #expect(result[0].id == "prod-1")
        #expect(result[0].name == "My App CI")
        #expect(result[0].productType == .app)
    }

    @Test func `listProducts injects appId from relationship data`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiProductsResponse(
            data: [
                CiProduct(
                    type: .ciProducts,
                    id: "prod-1",
                    attributes: .init(name: "My App CI", productType: .app),
                    relationships: .init(
                        app: .init(data: .init(type: .apps, id: "app-99"))
                    )
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKXcodeCloudProductRepository(client: stub)
        let result = try await repo.listProducts(appId: nil)

        #expect(result[0].appId == "app-99")
    }

    @Test func `listProducts with appId filter passes filterApp param`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(CiProductsResponse(data: [], links: .init(this: "")))

        let repo = SDKXcodeCloudProductRepository(client: stub)
        let result = try await repo.listProducts(appId: "app-123")

        #expect(result.isEmpty)
    }
}
