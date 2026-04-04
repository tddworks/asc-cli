import Foundation
import Testing
@testable import Domain

@Suite("ScreenDesign — Rich Domain")
struct ScreenDesignRichTests {

    @Test func `screen design carries template and screenshot`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate(id: "top-hero")
        let screen = ScreenDesign(
            index: 0,
            template: template,
            screenshotFile: "screen-1.png",
            heading: "Ship Faster",
            subheading: "One command away"
        )
        #expect(screen.template?.id == "top-hero")
        #expect(screen.screenshotFile == "screen-1.png")
        #expect(screen.heading == "Ship Faster")
        #expect(screen.subheading == "One command away")
    }

    @Test func `screen design without template is incomplete`() {
        let screen = ScreenDesign(
            index: 0,
            template: nil,
            screenshotFile: "screen-1.png",
            heading: "",
            subheading: ""
        )
        #expect(!screen.isComplete)
    }

    @Test func `screen design with template and heading is complete`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate()
        let screen = ScreenDesign(
            index: 0,
            template: template,
            screenshotFile: "screen-1.png",
            heading: "Ship Faster",
            subheading: ""
        )
        #expect(screen.isComplete)
    }

    @Test func `previewHTML renders template with real content`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate()
        let screen = ScreenDesign(
            index: 0,
            template: template,
            screenshotFile: "screen-1.png",
            heading: "Ship Faster",
            subheading: ""
        )
        let html = screen.previewHTML
        #expect(html.contains("Ship Faster"))
        #expect(html.contains("screen-1.png"))
        #expect(html.contains("linear-gradient"))
    }

    @Test func `previewHTML without template returns empty`() {
        let screen = ScreenDesign(
            index: 0,
            template: nil,
            screenshotFile: "screen-1.png",
            heading: "Ship Faster",
            subheading: ""
        )
        #expect(screen.previewHTML.isEmpty)
    }

    @Test func `affordances include generate when complete`() {
        let template = MockRepositoryFactory.makeScreenshotTemplate()
        let screen = ScreenDesign(
            index: 0,
            template: template,
            screenshotFile: "screen-1.png",
            heading: "Ship Faster",
            subheading: ""
        )
        #expect(screen.affordances["generate"] != nil)
        #expect(screen.affordances["changeTemplate"] == "asc app-shots templates list")
    }

    @Test func `affordances exclude generate when incomplete`() {
        let screen = ScreenDesign(
            index: 0,
            template: nil,
            screenshotFile: "screen-1.png",
            heading: "",
            subheading: ""
        )
        #expect(screen.affordances["generate"] == nil)
        #expect(screen.affordances["changeTemplate"] == "asc app-shots templates list")
    }
}
