import Foundation
import Testing
@testable import ASCKit

@Suite
struct ArchiveExportTests {

    // MARK: - ExportMethod

    @Test func `export method raw values match xcodebuild`() {
        #expect(ExportMethod.appStoreConnect.rawValue == "app-store-connect")
        #expect(ExportMethod.adHoc.rawValue == "ad-hoc")
        #expect(ExportMethod.development.rawValue == "development")
        #expect(ExportMethod.enterprise.rawValue == "enterprise")
    }

    @Test func `export method cli argument init`() {
        #expect(ExportMethod(cliArgument: "app-store-connect") == .appStoreConnect)
        #expect(ExportMethod(cliArgument: "ad-hoc") == .adHoc)
        #expect(ExportMethod(cliArgument: "development") == .development)
        #expect(ExportMethod(cliArgument: "enterprise") == .enterprise)
        #expect(ExportMethod(cliArgument: "unknown") == nil)
    }

    // MARK: - ArchiveRequest

    @Test func `archive request carries scheme and platform`() {
        let request = MockRepositoryFactory.makeArchiveRequest(scheme: "MyApp", platform: .iOS)
        #expect(request.scheme == "MyApp")
        #expect(request.platform == .iOS)
    }

    @Test func `archive request workspace and project are optional`() {
        let request = MockRepositoryFactory.makeArchiveRequest()
        #expect(request.workspace == nil)
        #expect(request.project == nil)
    }

    // MARK: - ArchiveResult

    @Test func `archive result carries archive path and scheme`() {
        let result = MockRepositoryFactory.makeArchiveResult(
            archivePath: "/tmp/MyApp.xcarchive",
            scheme: "MyApp"
        )
        #expect(result.archivePath == "/tmp/MyApp.xcarchive")
        #expect(result.scheme == "MyApp")
    }

    @Test func `archive result affordances include export`() {
        let result = MockRepositoryFactory.makeArchiveResult(
            archivePath: "/tmp/MyApp.xcarchive",
            scheme: "MyApp"
        )
        #expect(result.affordances["exportArchive"] != nil)
        #expect(result.affordances["exportArchive"]!.contains("MyApp.xcarchive"))
    }

    // MARK: - ExportRequest signing

    @Test func `export request defaults to automatic signing`() {
        let request = ExportRequest(archivePath: "/tmp/a.xcarchive", exportPath: "/tmp/export")
        #expect(request.signingStyle == .automatic)
        #expect(request.teamId == nil)
    }

    @Test func `export request carries manual signing with team id`() {
        let request = ExportRequest(
            archivePath: "/tmp/a.xcarchive",
            exportPath: "/tmp/export",
            signingStyle: .manual,
            teamId: "ABCD1234"
        )
        #expect(request.signingStyle == .manual)
        #expect(request.teamId == "ABCD1234")
    }

    // MARK: - SigningStyle

    @Test func `signing style raw values match xcodebuild`() {
        #expect(SigningStyle.automatic.rawValue == "automatic")
        #expect(SigningStyle.manual.rawValue == "manual")
    }

    // MARK: - ExportResult

    @Test func `export result carries ipa path`() {
        let result = MockRepositoryFactory.makeExportResult(ipaPath: "/tmp/export/MyApp.ipa")
        #expect(result.ipaPath == "/tmp/export/MyApp.ipa")
    }

    @Test func `export result affordances include upload`() {
        let result = MockRepositoryFactory.makeExportResult(ipaPath: "/tmp/export/MyApp.ipa")
        #expect(result.affordances["upload"] != nil)
        #expect(result.affordances["upload"]!.contains("/tmp/export/MyApp.ipa"))
    }

    // MARK: - Codable

    @Test func `archive result encodes and decodes`() throws {
        let result = MockRepositoryFactory.makeArchiveResult()
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(ArchiveResult.self, from: data)
        #expect(decoded == result)
    }

    @Test func `export result encodes and decodes`() throws {
        let result = MockRepositoryFactory.makeExportResult()
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(ExportResult.self, from: data)
        #expect(decoded == result)
    }
}
