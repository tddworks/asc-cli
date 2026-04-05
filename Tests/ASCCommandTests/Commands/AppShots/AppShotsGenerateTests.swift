import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppShotsGenerateTests {

    @Test func `generate parses file flag`() throws {
        let cmd = try AppShotsGenerate.parse(["--file", "screen.png"])
        #expect(cmd.file == "screen.png")
    }

    @Test func `generate parses style reference`() throws {
        let cmd = try AppShotsGenerate.parse(["--file", "screen.png", "--style-reference", "ref.png"])
        #expect(cmd.styleReference == "ref.png")
    }

    @Test func `generate parses custom prompt`() throws {
        let cmd = try AppShotsGenerate.parse(["--file", "screen.png", "--prompt", "add glow"])
        #expect(cmd.prompt == "add glow")
    }

    @Test func `generate parses output dir`() throws {
        let cmd = try AppShotsGenerate.parse(["--file", "screen.png", "--output-dir", "out"])
        #expect(cmd.outputDir == "out")
    }

    @Test func `generate defaults`() throws {
        let cmd = try AppShotsGenerate.parse(["--file", "screen.png"])
        #expect(cmd.model == "gemini-3.1-flash-image-preview")
        #expect(cmd.outputDir == ".asc/app-shots/output")
        #expect(cmd.styleReference == nil)
        #expect(cmd.prompt == nil)
        #expect(cmd.deviceType == nil)
    }

    @Test func `generate parses device type`() throws {
        let cmd = try AppShotsGenerate.parse(["--file", "screen.png", "--device-type", "APP_IPHONE_67"])
        #expect(cmd.deviceType == .iphone67)
    }

    @Test func `execute throws when file not found`() async throws {
        let cmd = try AppShotsGenerate.parse(["--file", "/nonexistent.png"])
        do {
            _ = try await cmd.execute(apiKey: "test-key")
            Issue.record("Expected error")
        } catch {
            #expect(String(describing: error).contains("not found"))
        }
    }
}
