import Foundation
import Testing
@testable import Domain

@Suite
struct ScreenPlanTests {

    @Test func `screen plan id equals appId`() {
        let plan = ScreenPlan(
            appId: "app-123",
            appName: "TestApp",
            tagline: "Great app",
            tone: .professional,
            colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
            screens: []
        )
        #expect(plan.id == "app-123")
    }

    @Test func `affordances include generate command`() {
        let plan = ScreenPlan(
            appId: "app-123",
            appName: "TestApp",
            tagline: "Great app",
            tone: .professional,
            colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
            screens: []
        )
        #expect(plan.affordances["generate"] != nil)
        #expect(plan.affordances["generate"]!.contains("asc app-shots generate"))
    }

    @Test func `screen tone raw values are lowercase`() {
        #expect(ScreenTone.minimal.rawValue == "minimal")
        #expect(ScreenTone.professional.rawValue == "professional")
        #expect(ScreenTone.playful.rawValue == "playful")
        #expect(ScreenTone.bold.rawValue == "bold")
        #expect(ScreenTone.elegant.rawValue == "elegant")
    }

    @Test func `layout mode raw values are lowercase`() {
        #expect(LayoutMode.center.rawValue == "center")
        #expect(LayoutMode.left.rawValue == "left")
        #expect(LayoutMode.tilted.rawValue == "tilted")
    }

    @Test func `screen config id equals index string`() {
        let config = ScreenConfig(
            index: 2,
            screenshotFile: "screen2.png",
            heading: "Great Feature",
            subheading: "Makes everything better",
            layoutMode: .center,
            visualDirection: "Shows the main screen",
            imagePrompt: "Beautiful UI"
        )
        #expect(config.id == "2")
        #expect(config.index == 2)
    }

    @Test func `screen plan roundtrips through JSON`() throws {
        let plan = ScreenPlan(
            appId: "6736834466",
            appName: "MyApp",
            tagline: "Your companion",
            tone: .elegant,
            colors: ScreenColors(primary: "#1A1A2E", accent: "#E94560", text: "#FFFFFF", subtext: "#CCCCCC"),
            screens: [
                ScreenConfig(
                    index: 0,
                    screenshotFile: "screen1.png",
                    heading: "Work Smarter",
                    subheading: "Organize tasks in seconds",
                    layoutMode: .center,
                    visualDirection: "Main dashboard",
                    imagePrompt: "Beautiful UI"
                )
            ]
        )
        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(ScreenPlan.self, from: data)
        #expect(decoded == plan)
        #expect(decoded.appId == "6736834466")
        #expect(decoded.screens.count == 1)
    }

    @Test func `appDescription is preserved in JSON roundtrip`() throws {
        let plan = ScreenPlan(
            appId: "app-1",
            appName: "MyApp",
            tagline: "Great app",
            appDescription: "A powerful productivity tool for iOS developers.",
            tone: .professional,
            colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
            screens: []
        )
        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(ScreenPlan.self, from: data)
        #expect(decoded.appDescription == "A powerful productivity tool for iOS developers.")
    }

    @Test func `appDescription is omitted from JSON when nil`() throws {
        let plan = ScreenPlan(
            appId: "app-1",
            appName: "MyApp",
            tagline: "Great app",
            appDescription: nil,
            tone: .minimal,
            colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
            screens: []
        )
        let data = try JSONEncoder().encode(plan)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["appDescription"] == nil)
    }

    @Test func `existing plan JSON without appDescription decodes with nil`() throws {
        let json = """
        {"appId":"app-1","appName":"MyApp","tagline":"t","tone":"minimal",
         "colors":{"primary":"#000","accent":"#fff","text":"#fff","subtext":"#ccc"},
         "screens":[]}
        """
        let decoded = try JSONDecoder().decode(ScreenPlan.self, from: Data(json.utf8))
        #expect(decoded.appDescription == nil)
    }
}
