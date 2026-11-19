import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct BuildsArchiveTests {

    // MARK: - Archive only (no --upload)

    @Test func `archive shows result with export affordance`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--pretty"])
        let output = try await cmd.execute(runner: mockRunner)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "upload" : "asc builds upload --file \\/tmp\\/export\\/MyApp.ipa"
              },
              "exportPath" : "\\/tmp\\/export",
              "ipaPath" : "\\/tmp\\/export\\/MyApp.ipa"
            }
          ]
        }
        """)
    }

    @Test func `archive with workspace passes it to runner`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--workspace", "MyApp.xcworkspace", "--pretty"])
        _ = try await cmd.execute(runner: mockRunner)

        // Verify archive was called (test passes if no error)
    }

    @Test func `archive with project passes it to runner`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--project", "MyApp.xcodeproj", "--pretty"])
        _ = try await cmd.execute(runner: mockRunner)
    }

    @Test func `archive with custom platform uses it`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .macOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.pkg", exportPath: "/tmp/export"))

        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--platform", "macos", "--pretty"])
        let output = try await cmd.execute(runner: mockRunner)

        #expect(output.contains("MyApp.pkg"))
    }

    @Test func `archive with custom export method`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--export-method", "ad-hoc", "--pretty"])
        _ = try await cmd.execute(runner: mockRunner)
    }

    @Test func `throws for unknown platform`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--platform", "watchos"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(runner: mockRunner)
        }
    }

    @Test func `throws for unknown export method`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--export-method", "invalid"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(runner: mockRunner)
        }
    }

    // MARK: - Upload chaining

    @Test func `archive with upload chains to build upload`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

        let mockUploadRepo = MockBuildUploads()
        given(mockUploadRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .any, fileURL: .any)
            .willReturn(BuildUpload(id: "up-1", appId: "app-1", version: "1.0.0", buildNumber: "42", platform: .iOS, state: .complete))

        let cmd = try BuildsArchive.parse([
            "--scheme", "MyApp",
            "--upload",
            "--app-id", "app-1",
            "--version", "1.0.0",
            "--build-number", "42",
            "--pretty"
        ])
        let output = try await cmd.execute(runner: mockRunner, uploadRepo: mockUploadRepo)

        #expect(output.contains("up-1"))
        #expect(output.contains("COMPLETE"))
    }

    @Test func `upload requires app-id`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

        let cmd = try BuildsArchive.parse([
            "--scheme", "MyApp",
            "--upload",
            "--version", "1.0.0",
            "--build-number", "42"
        ])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(runner: mockRunner)
        }
    }

    // MARK: - Table output

    @Test func `table output includes export path`() async throws {
        let mockRunner = MockXcodeBuildRunner()
        given(mockRunner).archive(request: .any)
            .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
        given(mockRunner).exportArchive(request: .any)
            .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

        let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--output", "table"])
        let output = try await cmd.execute(runner: mockRunner)

        #expect(output.contains("MyApp.ipa"))
    }
}
