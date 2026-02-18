import Mockable
import Testing
@testable import Domain

@Suite
struct AppRepositoryTests {

    @Test
    func `list apps returns paginated response`() async throws {
        let mock = MockAppRepository()
        let apps = [
            MockRepositoryFactory.makeApp(id: "1", name: "App One"),
            MockRepositoryFactory.makeApp(id: "2", name: "App Two"),
        ]
        let response = PaginatedResponse(data: apps, nextCursor: nil, totalCount: 2)

        given(mock).listApps(limit: .any).willReturn(response)

        let result = try await mock.listApps(limit: 10)
        #expect(result.data.count == 2)
        #expect(result.data[0].name == "App One")
        #expect(result.hasMore == false)
    }

    @Test
    func `get app returns single app`() async throws {
        let mock = MockAppRepository()
        let app = MockRepositoryFactory.makeApp(id: "42", name: "My App")

        given(mock).getApp(id: .value("42")).willReturn(app)

        let result = try await mock.getApp(id: "42")
        #expect(result.id == "42")
        #expect(result.name == "My App")
    }

    @Test
    func `list apps with pagination cursor`() async throws {
        let mock = MockAppRepository()
        let response = PaginatedResponse(
            data: [MockRepositoryFactory.makeApp()],
            nextCursor: "next-page-token",
            totalCount: 50
        )

        given(mock).listApps(limit: .value(1)).willReturn(response)

        let result = try await mock.listApps(limit: 1)
        #expect(result.hasMore == true)
        #expect(result.nextCursor == "next-page-token")
    }

    @Test
    func `list versions returns versions for app`() async throws {
        let mock = MockAppRepository()
        let versions = [
            MockRepositoryFactory.makeVersion(id: "v1", versionString: "2.1.0", platform: .iOS),
            MockRepositoryFactory.makeVersion(id: "v2", versionString: "1.5.0", platform: .macOS),
        ]
        given(mock).listVersions(appId: .any).willReturn(versions)

        let result = try await mock.listVersions(appId: "app-abc")
        #expect(result.count == 2)
        #expect(result[0].platform == .iOS)
        #expect(result[0].displayName == "iOS 2.1.0")
        #expect(result[1].platform == .macOS)
        #expect(result[1].displayName == "macOS 1.5.0")
    }

    @Test
    func `list versions returns empty when app has no versions`() async throws {
        let mock = MockAppRepository()
        given(mock).listVersions(appId: .any).willReturn([])

        let result = try await mock.listVersions(appId: "new-app")
        #expect(result.isEmpty)
    }
}
