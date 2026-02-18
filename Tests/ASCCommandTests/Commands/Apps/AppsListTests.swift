import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppsListTests {

    @Test func `execute returns app name and bundle id in output`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-1", name: "My App", bundleId: "com.example.app", sku: "SKU1"),
            ], nextCursor: nil)
        )

        let cmd = try AppsList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("My App"))
        #expect(output.contains("com.example.app"))
        #expect(output.contains("SKU1"))
    }

    @Test func `execute uses dash for missing sku`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-1", name: "No SKU App", bundleId: "com.example", sku: nil),
            ], nextCursor: nil)
        )

        let cmd = try AppsList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("-"))
    }

    @Test func `execute json output contains affordances`() async throws {
        let mockRepo = MockAppRepository()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-42", name: "Test", bundleId: "com.test"),
            ], nextCursor: nil)
        )

        let cmd = try AppsList.parse([])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("affordances"))
        #expect(output.contains("app-42"))
    }
}
