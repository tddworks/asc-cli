import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct InitCommandTests {

    // MARK: - --app-id mode

    @Test func `app-id resolves app by ID and saves config`() async throws {
        let mockRepo = MockAppRepository()
        let mockStorage = MockProjectConfigStorage()
        given(mockRepo).getApp(id: .any).willReturn(
            App(id: "app-123", name: "My App", bundleId: "com.example.app")
        )
        given(mockStorage).save(.any).willReturn()

        var cmd = try InitCommand.parse(["--app-id", "app-123", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id <id>",
                "listAppInfos" : "asc app-infos list --app-id app-123",
                "listBuilds" : "asc builds list --app-id app-123",
                "listVersions" : "asc versions list --app-id app-123"
              },
              "appId" : "app-123",
              "appName" : "My App",
              "bundleId" : "com.example.app"
            }
          ]
        }
        """)
    }

    // MARK: - --name mode

    @Test func `name finds matching app case-insensitively and saves config`() async throws {
        let mockRepo = MockAppRepository()
        let mockStorage = MockProjectConfigStorage()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-123", name: "My App", bundleId: "com.example.app"),
            ], nextCursor: nil)
        )
        given(mockStorage).save(.any).willReturn()

        var cmd = try InitCommand.parse(["--name", "my app", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo, storage: mockStorage)

        #expect(output.contains("app-123"))
        #expect(output.contains("com.example.app"))
    }

    @Test func `name throws when no matching app found`() async throws {
        let mockRepo = MockAppRepository()
        let mockStorage = MockProjectConfigStorage()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-123", name: "My App", bundleId: "com.example.app"),
            ], nextCursor: nil)
        )

        var cmd = try InitCommand.parse(["--name", "Unknown App"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo, storage: mockStorage)
        }
    }

    // MARK: - Auto-detect mode

    @Test func `auto-detect matches app by bundle ID from xcodeproj`() async throws {
        let mockRepo = MockAppRepository()
        let mockStorage = MockProjectConfigStorage()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-123", name: "My App", bundleId: "com.example.app"),
            ], nextCursor: nil)
        )
        given(mockStorage).save(.any).willReturn()

        var cmd = try InitCommand.parse(["--pretty"])
        let output = try await cmd.execute(
            repo: mockRepo,
            storage: mockStorage,
            bundleIdScanner: { _ in ["com.example.app"] }
        )

        #expect(output.contains("app-123"))
    }

    @Test func `auto-detect throws when scanner finds no bundle IDs`() async throws {
        let mockRepo = MockAppRepository()
        let mockStorage = MockProjectConfigStorage()

        var cmd = try InitCommand.parse([])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(
                repo: mockRepo,
                storage: mockStorage,
                bundleIdScanner: { _ in [] }
            )
        }
    }

    @Test func `auto-detect throws when no ASC app matches bundle ID`() async throws {
        let mockRepo = MockAppRepository()
        let mockStorage = MockProjectConfigStorage()
        given(mockRepo).listApps(limit: .any).willReturn(
            PaginatedResponse(data: [
                App(id: "app-999", name: "Other App", bundleId: "com.other.app"),
            ], nextCursor: nil)
        )

        var cmd = try InitCommand.parse([])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(
                repo: mockRepo,
                storage: mockStorage,
                bundleIdScanner: { _ in ["com.example.app"] }
            )
        }
    }
}
