@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKAppCategoryRepositoryTests {

    @Test func `listCategories returns top level and subcategories as flat list`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppCategoriesResponse(
            data: [
                AppCategory(type: .appCategories, id: "6014", attributes: .init(platforms: [.ios])),
                AppCategory(type: .appCategories, id: "6005", attributes: .init(platforms: [.ios])),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppCategoryRepository(client: stub)
        let result = try await repo.listCategories(platform: nil)

        #expect(result.count == 2)
        #expect(result[0].id == "6014")
        #expect(result[1].id == "6005")
    }

    @Test func `listCategories maps platforms from SDK attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppCategoriesResponse(
            data: [
                AppCategory(type: .appCategories, id: "6014", attributes: .init(platforms: [.ios, .macOs])),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppCategoryRepository(client: stub)
        let result = try await repo.listCategories(platform: nil)

        #expect(result[0].platforms.contains("IOS"))
        #expect(result[0].platforms.contains("MAC_OS"))
    }

    @Test func `listCategories maps parentId for subcategories`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppCategoriesResponse(
            data: [
                AppCategory(
                    type: .appCategories,
                    id: "6014-action",
                    attributes: .init(platforms: [.ios]),
                    relationships: .init(parent: .init(data: .init(type: .appCategories, id: "6014")))
                ),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppCategoryRepository(client: stub)
        let result = try await repo.listCategories(platform: nil)

        #expect(result[0].parentId == "6014")
    }

    @Test func `getCategory maps id platforms and parentId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppCategoryResponse(
            data: AppCategory(
                type: .appCategories,
                id: "6014-action",
                attributes: .init(platforms: [.ios, .macOs]),
                relationships: .init(parent: .init(data: .init(type: .appCategories, id: "6014")))
            ),
            links: .init(this: "")
        ))

        let repo = SDKAppCategoryRepository(client: stub)
        let result = try await repo.getCategory(id: "6014-action")

        #expect(result.id == "6014-action")
        #expect(result.platforms.contains("IOS"))
        #expect(result.platforms.contains("MAC_OS"))
        #expect(result.parentId == "6014")
    }

    @Test func `listCategories sets parentId to nil for top level categories`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppCategoriesResponse(
            data: [
                AppCategory(type: .appCategories, id: "6014", attributes: .init(platforms: [.ios])),
            ],
            links: .init(this: "")
        ))

        let repo = SDKAppCategoryRepository(client: stub)
        let result = try await repo.listCategories(platform: nil)

        #expect(result[0].parentId == nil)
    }
}
