import Testing
import Foundation
import Mockable
@testable import Domain

@Suite("AppPortfolio")
struct AppStoreMonitorTests {

    // MARK: - Portfolio behaviour

    @Test func `refresh populates apps and selects first`() async throws {
        let mockRepo = MockAppStoreRepository()
        given(mockRepo).fetchApps().willReturn([
            ASCApp(id: "app1", name: "My App", bundleId: "com.example.myapp")
        ])
        given(mockRepo).fetchVersions(appId: .any).willReturn([
            ASCVersion(id: "v1", appId: "app1", versionString: "1.5.0", platform: "IOS", state: "READY_FOR_SALE")
        ])
        let monitor = AppPortfolio(repository: mockRepo)

        await monitor.refresh()

        #expect(monitor.apps.count == 1)
        #expect(monitor.selectedAppId == "app1")
    }

    @Test func `overallStatus is live when READY_FOR_SALE`() async throws {
        let mockRepo = MockAppStoreRepository()
        given(mockRepo).fetchApps().willReturn([
            ASCApp(id: "app1", name: "My App", bundleId: "com.example.myapp")
        ])
        given(mockRepo).fetchVersions(appId: .any).willReturn([
            ASCVersion(id: "v1", appId: "app1", versionString: "1.5.0", platform: "IOS", state: "READY_FOR_SALE")
        ])
        let monitor = AppPortfolio(repository: mockRepo)

        await monitor.refresh()

        #expect(monitor.overallStatus == .live)
    }

    @Test func `overallStatus is editable when only PREPARE_FOR_SUBMISSION`() async throws {
        let mockRepo = MockAppStoreRepository()
        given(mockRepo).fetchApps().willReturn([
            ASCApp(id: "app1", name: "My App", bundleId: "com.example.myapp")
        ])
        given(mockRepo).fetchVersions(appId: .any).willReturn([
            ASCVersion(id: "v2", appId: "app1", versionString: "1.6.0", platform: "IOS", state: "PREPARE_FOR_SUBMISSION")
        ])
        let monitor = AppPortfolio(repository: mockRepo)

        await monitor.refresh()

        #expect(monitor.overallStatus == .editable)
    }

    @Test func `refresh captures error when repository throws`() async throws {
        struct FakeError: Error {
            var localizedDescription: String { "asc not found" }
        }
        let mockRepo = MockAppStoreRepository()
        given(mockRepo).fetchApps().willThrow(FakeError())
        let monitor = AppPortfolio(repository: mockRepo)

        await monitor.refresh()

        #expect(monitor.lastError != nil)
        #expect(monitor.apps.isEmpty)
    }

    // MARK: - ASCVersion domain model

    @Test func `version appStatus maps READY_FOR_SALE to live`() {
        let version = ASCVersion(id: "v", appId: "a", versionString: "1.0", platform: "IOS", state: "READY_FOR_SALE")
        #expect(version.appStatus == .live)
        #expect(version.isLive)
    }

    @Test func `version appStatus maps PREPARE_FOR_SUBMISSION to editable`() {
        let version = ASCVersion(id: "v", appId: "a", versionString: "1.0", platform: "IOS", state: "PREPARE_FOR_SUBMISSION")
        #expect(version.appStatus == .editable)
        #expect(version.isEditable)
    }

    @Test func `version appStatus maps IN_REVIEW to pending`() {
        let version = ASCVersion(id: "v", appId: "a", versionString: "1.0", platform: "IOS", state: "IN_REVIEW")
        #expect(version.appStatus == .pending)
        #expect(version.isPending)
    }

    // MARK: - ASCApp domain model

    @Test func `ASCApp displayName falls back to bundleId when name is empty`() {
        let app = ASCApp(id: "1", name: "", bundleId: "com.example.app")
        #expect(app.displayName == "com.example.app")
    }

    @Test func `ASCVersion platformDisplayName maps IOS correctly`() {
        let version = ASCVersion(id: "v", appId: "a", versionString: "1.0", platform: "IOS", state: "READY_FOR_SALE")
        #expect(version.platformDisplayName == "iOS")
    }
}
