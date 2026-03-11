import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppShotsHTMLTests {

    /// Minimal PNG header + padding
    private static let fakePNG: Data = {
        var bytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        bytes += [UInt8](repeating: 0, count: 200)
        return Data(bytes)
    }()

    private func makePlan(
        appName: String = "TestApp",
        screens: [ScreenConfig] = []
    ) -> ScreenPlan {
        ScreenPlan(
            appId: "app-1",
            appName: appName,
            tagline: "Your best app",
            tone: .professional,
            colors: ScreenColors(primary: "#0A1628", accent: "#4A7CFF", text: "#FFFFFF", subtext: "#A8B8D0"),
            screens: screens
        )
    }

    private func makeScreen(
        index: Int = 0,
        heading: String = "Great Feature",
        subheading: String = "Makes life easier",
        layoutMode: LayoutMode = .center
    ) -> ScreenConfig {
        ScreenConfig(
            index: index,
            screenshotFile: "screen\(index).png",
            heading: heading,
            subheading: subheading,
            layoutMode: layoutMode,
            visualDirection: "Dark background",
            imagePrompt: "Modern app showcase"
        )
    }

    private func writePlanAndScreenshots(
        plan: ScreenPlan,
        screenshotCount: Int = 0
    ) throws -> (planPath: String, screenshotPaths: [String]) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-html-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let planURL = dir.appendingPathComponent("plan.json")
        try encoder.encode(plan).write(to: planURL)

        var screenshotPaths: [String] = []
        for i in 0..<screenshotCount {
            let path = dir.appendingPathComponent("screen\(i).png")
            try Self.fakePNG.write(to: path)
            screenshotPaths.append(path.path)
        }

        return (planURL.path, screenshotPaths)
    }

    private func makeTempOutputDir() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-html-out-\(UUID().uuidString)").path
    }

    // MARK: - Basic HTML generation

    @Test func `html generates an HTML file from the plan`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        let output = try await cmd.execute()

        let htmlPath = "\(outputDir)/app-shots.html"
        #expect(FileManager.default.fileExists(atPath: htmlPath))
        #expect(output.contains("app-shots.html"))
    }

    @Test func `html embeds heading and subheading from plan`() async throws {
        let plan = makePlan(screens: [
            makeScreen(index: 0, heading: "Amazing Feature", subheading: "Works like magic")
        ])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("Amazing Feature"))
        #expect(html.contains("Works like magic"))
    }

    @Test func `html applies plan colors to CSS`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("#0A1628"))  // primary background
        #expect(html.contains("#4A7CFF"))  // accent (category label + buttons)
        #expect(html.contains("#FFFFFF"))  // text (heading)
    }

    @Test func `html embeds screenshots as base64 data URIs`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("data:image/png;base64,"))
    }

    @Test func `html renders multiple screens`() async throws {
        let plan = makePlan(screens: [
            makeScreen(index: 0, heading: "First Screen"),
            makeScreen(index: 1, heading: "Second Screen"),
            makeScreen(index: 2, heading: "Third Screen"),
        ])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 3)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("First Screen"))
        #expect(html.contains("Second Screen"))
        #expect(html.contains("Third Screen"))
    }

    @Test func `html supports different layout modes`() async throws {
        let plan = makePlan(screens: [
            makeScreen(index: 0, layoutMode: .center),
            makeScreen(index: 1, layoutMode: .left),
            makeScreen(index: 2, layoutMode: .tilted),
        ])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 3)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("layout-center"))
        #expect(html.contains("layout-left"))
        #expect(html.contains("layout-tilted"))
    }

    @Test func `html creates output directory if it does not exist`() async throws {
        let plan = makePlan(screens: [makeScreen()])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir() + "/nested/dir"
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        #expect(FileManager.default.fileExists(atPath: outputDir))
    }

    @Test func `html auto-discovers screenshots from plan directory`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, _) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let htmlPath = "\(outputDir)/app-shots.html"
        #expect(FileManager.default.fileExists(atPath: htmlPath))
    }

    @Test func `html includes export functionality`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("html-to-image"))
        #expect(html.contains("Export"))
    }

    @Test func `html includes device dimensions for export`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse([
            "--plan", planPath, "--output-dir", outputDir,
            "--device-type", "APP_IPHONE_67", "--mockup", "none"
        ] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("1290"))
        #expect(html.contains("2796"))
    }

    @Test func `html throws when plan file not found`() async throws {
        let cmd = try AppShotsHTML.parse(["--plan", "/nonexistent/plan.json", "--mockup", "none"])
        do {
            _ = try await cmd.execute()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(true)
        }
    }

    @Test func `html app name appears in the page title`() async throws {
        let plan = makePlan(appName: "SuperApp", screens: [makeScreen()])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("<title>SuperApp"))
    }

    // MARK: - Mockup tests

    @Test func `html with custom mockup path embeds frame and uses screen-content class`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()

        let mockupPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("mockup-\(UUID().uuidString).png")
        try Self.fakePNG.write(to: mockupPath)

        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
            try? FileManager.default.removeItem(at: mockupPath)
        }

        let cmd = try AppShotsHTML.parse([
            "--plan", planPath, "--output-dir", outputDir,
            "--mockup", mockupPath.path,
            "--screen-inset-x", "80", "--screen-inset-y", "70"
        ] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("mockup-frame"))
        #expect(html.contains("screen-content"))
        #expect(html.contains("Device frame"))
    }

    @Test func `html with --mockup none disables mockup frame`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("box-shadow"))
        #expect(!html.contains("mockup-frame"))
    }

    @Test func `html default uses bundled mockup with mockup-frame class`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        // No --mockup flag — should use bundled default
        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("mockup-frame"))
        #expect(html.contains("screen-content"))
    }

    @Test func `mockup resolver finds device by name`() throws {
        // This tests that the bundled mockups.json has the expected default entry
        let resolved = try MockupResolver.resolve(argument: nil, insetXOverride: nil, insetYOverride: nil)
        #expect(resolved != nil)
        #expect(resolved?.screenInsetX == 75)
        #expect(resolved?.screenInsetY == 66)
        #expect(resolved?.frameWidth == 1470)
        #expect(resolved?.frameHeight == 3000)
    }

    @Test func `mockup resolver returns nil for --mockup none`() throws {
        let resolved = try MockupResolver.resolve(argument: "none", insetXOverride: nil, insetYOverride: nil)
        #expect(resolved == nil)
    }

    @Test func `mockup resolver applies inset overrides`() throws {
        let resolved = try MockupResolver.resolve(argument: nil, insetXOverride: 100, insetYOverride: 200)
        #expect(resolved != nil)
        #expect(resolved?.screenInsetX == 100)
        #expect(resolved?.screenInsetY == 200)
    }
}
