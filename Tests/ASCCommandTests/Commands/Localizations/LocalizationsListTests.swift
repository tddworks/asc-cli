import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct LocalizationsListTests {

    @Test func `execute returns locale in output`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v-1", locale: "en-US"),
            AppStoreVersionLocalization(id: "loc-2", versionId: "v-1", locale: "zh-Hans"),
        ])

        let cmd = try LocalizationsList.parse(["--version-id", "v-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("en-US"))
        #expect(output.contains("zh-Hans"))
    }

    @Test func `execute json output contains affordances`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listLocalizations(versionId: .any).willReturn([
            AppStoreVersionLocalization(id: "loc-1", versionId: "v-1", locale: "en-US"),
        ])

        let cmd = try LocalizationsList.parse(["--version-id", "v-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("affordances"))
        #expect(output.contains("listScreenshotSets"))
    }

    @Test func `execute passes versionId to repository`() async throws {
        let mockRepo = MockScreenshotRepository()
        given(mockRepo).listLocalizations(versionId: .value("v-42")).willReturn([])

        let cmd = try LocalizationsList.parse(["--version-id", "v-42"])
        _ = try await cmd.execute(repo: mockRepo)
    }
}
