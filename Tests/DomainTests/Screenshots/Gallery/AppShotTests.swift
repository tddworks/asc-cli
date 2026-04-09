import Foundation
import Testing
@testable import Domain

@Suite("AppShot")
struct AppShotTests {

    // ── User: "I create an app shot from my screenshot" ──

    @Test func `app shot is created from a screenshot file`() {
        let shot = AppShot(screenshot: "screen-0.png")
        #expect(shot.screenshot == "screen-0.png")
    }

    @Test func `app shot defaults to feature type`() {
        let shot = AppShot(screenshot: "screen-0.png")
        #expect(shot.type == .feature)
    }

    @Test func `app shot can be hero type`() {
        let shot = AppShot(screenshot: "screen-0.png", type: .hero)
        #expect(shot.type == .hero)
    }

    @Test func `app shot can be social type`() {
        let shot = AppShot(screenshot: "screen-0.png", type: .social)
        #expect(shot.type == .social)
    }

    // ── User: "I give it a headline" ──

    @Test func `app shot without headline is not configured`() {
        let shot = AppShot(screenshot: "screen-0.png")
        #expect(!shot.isConfigured)
    }

    @Test func `app shot with headline is configured`() {
        let shot = AppShot(screenshot: "screen-0.png")
        shot.headline = "PREMIUM DEVICE MOCKUPS."
        #expect(shot.isConfigured)
    }

    @Test func `app shot with empty headline is not configured`() {
        let shot = AppShot(screenshot: "screen-0.png")
        shot.headline = ""
        #expect(!shot.isConfigured)
    }

    // ── User: "I add badges to highlight features" ──

    @Test func `app shot starts with no badges`() {
        let shot = AppShot(screenshot: "screen-0.png")
        #expect(shot.badges.isEmpty)
    }

    @Test func `app shot can have feature badges`() {
        let shot = AppShot(screenshot: "screen-0.png")
        shot.badges = ["Mesh", "Gradient"]
        #expect(shot.badges == ["Mesh", "Gradient"])
    }

    // ── User: "Hero gets trust marks like ratings" ──

    @Test func `hero shot can have trust marks`() {
        let shot = AppShot(screenshot: "screen-0.png", type: .hero)
        shot.headline = "Make your map yours"
        shot.trustMarks = ["4.8 ⭐", "10K ratings"]
        #expect(shot.trustMarks == ["4.8 ⭐", "10K ratings"])
    }

    @Test func `app shot starts with no trust marks`() {
        let shot = AppShot(screenshot: "screen-0.png")
        #expect(shot.trustMarks == nil)
    }
}
