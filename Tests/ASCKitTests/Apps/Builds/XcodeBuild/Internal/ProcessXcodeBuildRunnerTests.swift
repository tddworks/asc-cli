import Foundation
import Testing
@testable import ASCKit

@Suite("ProcessXcodeBuildRunner")
struct ProcessXcodeBuildRunnerTests {

    // MARK: - Helpers

    private func makeScript(_ body: String) throws -> String {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-xcode-test-\(UUID().uuidString)")
        try body.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url.path
    }

    private func makeTempDir() -> String {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-xcode-out-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    // MARK: - Archive

    @Test func `archive succeeds and returns archive path`() async throws {
        let outputDir = makeTempDir()
        let archivePath = "\(outputDir)/MyApp.xcarchive"
        // Script simulates xcodebuild archive by creating the expected .xcarchive directory
        let script = try makeScript("""
        #!/bin/sh
        mkdir -p "\(archivePath)"
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ArchiveRequest(scheme: "MyApp", archivePath: archivePath)
        let result = try await runner.archive(request: request)

        #expect(result.archivePath == archivePath)
        #expect(result.scheme == "MyApp")
        #expect(result.platform == .iOS)
    }

    @Test func `archive throws when xcodebuild fails`() async throws {
        let script = try makeScript("""
        #!/bin/sh
        echo "xcodebuild: error: Scheme not found" >&2
        exit 65
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ArchiveRequest(scheme: "BadScheme", archivePath: "/tmp/Bad.xcarchive")
        await #expect(throws: XcodeBuildError.self) {
            _ = try await runner.archive(request: request)
        }
    }

    @Test func `archive passes workspace flag when provided`() async throws {
        let outputDir = makeTempDir()
        let archivePath = "\(outputDir)/MyApp.xcarchive"
        // Script captures args and creates the archive dir
        let argsFile = "\(outputDir)/args.txt"
        let script = try makeScript("""
        #!/bin/sh
        echo "$@" > "\(argsFile)"
        mkdir -p "\(archivePath)"
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ArchiveRequest(
            scheme: "MyApp",
            workspace: "MyApp.xcworkspace",
            archivePath: archivePath
        )
        _ = try await runner.archive(request: request)

        let args = try String(contentsOfFile: argsFile, encoding: .utf8)
        #expect(args.contains("-workspace"))
        #expect(args.contains("MyApp.xcworkspace"))
    }

    @Test func `archive passes project flag when provided`() async throws {
        let outputDir = makeTempDir()
        let archivePath = "\(outputDir)/MyApp.xcarchive"
        let argsFile = "\(outputDir)/args.txt"
        let script = try makeScript("""
        #!/bin/sh
        echo "$@" > "\(argsFile)"
        mkdir -p "\(archivePath)"
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ArchiveRequest(
            scheme: "MyApp",
            project: "MyApp.xcodeproj",
            archivePath: archivePath
        )
        _ = try await runner.archive(request: request)

        let args = try String(contentsOfFile: argsFile, encoding: .utf8)
        #expect(args.contains("-project"))
        #expect(args.contains("MyApp.xcodeproj"))
    }

    // MARK: - Export

    @Test func `export succeeds and finds IPA in export directory`() async throws {
        let outputDir = makeTempDir()
        let exportPath = "\(outputDir)/export"
        let ipaPath = "\(exportPath)/MyApp.ipa"
        // Script simulates xcodebuild -exportArchive by creating the IPA
        let script = try makeScript("""
        #!/bin/sh
        mkdir -p "\(exportPath)"
        touch "\(ipaPath)"
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ExportRequest(
            archivePath: "/tmp/MyApp.xcarchive",
            exportPath: exportPath
        )
        let result = try await runner.exportArchive(request: request)

        #expect(result.ipaPath == ipaPath)
        #expect(result.exportPath == exportPath)
    }

    @Test func `export throws when xcodebuild fails`() async throws {
        let script = try makeScript("""
        #!/bin/sh
        echo "error: no signing identity found" >&2
        exit 70
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ExportRequest(
            archivePath: "/tmp/MyApp.xcarchive",
            exportPath: "/tmp/export"
        )
        await #expect(throws: XcodeBuildError.self) {
            _ = try await runner.exportArchive(request: request)
        }
    }

    @Test func `export throws when no IPA found in export directory`() async throws {
        let outputDir = makeTempDir()
        let exportPath = "\(outputDir)/export"
        // Script creates the export directory but no .ipa file
        let script = try makeScript("""
        #!/bin/sh
        mkdir -p "\(exportPath)"
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ExportRequest(
            archivePath: "/tmp/MyApp.xcarchive",
            exportPath: exportPath
        )
        await #expect(throws: XcodeBuildError.self) {
            _ = try await runner.exportArchive(request: request)
        }
    }

    @Test func `export finds pkg for macOS exports`() async throws {
        let outputDir = makeTempDir()
        let exportPath = "\(outputDir)/export"
        let pkgPath = "\(exportPath)/MyApp.pkg"
        let script = try makeScript("""
        #!/bin/sh
        mkdir -p "\(exportPath)"
        touch "\(pkgPath)"
        """)
        let runner = ProcessXcodeBuildRunner(xcodebuildPath: script)

        let request = ExportRequest(
            archivePath: "/tmp/MyApp.xcarchive",
            exportPath: exportPath
        )
        let result = try await runner.exportArchive(request: request)

        #expect(result.ipaPath == pkgPath)
    }
}
