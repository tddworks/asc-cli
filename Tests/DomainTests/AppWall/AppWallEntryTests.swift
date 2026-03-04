import Foundation
import Testing
@testable import Domain

@Suite("AppWallApp")
struct AppWallAppTests {

    @Test func `app carries required developer field`() {
        let app = AppWallApp(developer: "itshan")
        #expect(app.developer == "itshan")
        #expect(app.id == "itshan")
        #expect(app.developerId == nil)
        #expect(app.github == nil)
        #expect(app.x == nil)
        #expect(app.apps == nil)
    }

    @Test func `app carries all optional fields`() {
        let app = AppWallApp(
            developer: "itshan",
            developerId: "1725133580",
            github: "hanrw",
            x: "itshanrw",
            apps: ["https://apps.apple.com/us/app/example/id123"]
        )
        #expect(app.developerId == "1725133580")
        #expect(app.github == "hanrw")
        #expect(app.x == "itshanrw")
        #expect(app.apps == ["https://apps.apple.com/us/app/example/id123"])
    }

    @Test func `nil optional fields are omitted from JSON`() throws {
        let app = AppWallApp(developer: "itshan")
        let data = try JSONEncoder().encode(app)
        let json = String(data: data, encoding: .utf8)!

        #expect(!json.contains("\"developerId\""))
        #expect(!json.contains("\"github\""))
        #expect(!json.contains("\"x\""))
        #expect(!json.contains("\"apps\""))
    }

    @Test func `app is codable round trip with all fields`() throws {
        let app = AppWallApp(
            developer: "itshan",
            developerId: "1725133580",
            github: "hanrw",
            x: "itshanrw",
            apps: ["https://apps.apple.com/us/app/example/id123"]
        )
        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(AppWallApp.self, from: data)
        #expect(decoded == app)
    }

    @Test func `submission carries PR details and openPR affordance`() {
        let submission = AppWallSubmission(
            prNumber: 42,
            prUrl: "https://github.com/tddworks/asc-cli/pull/42",
            title: "feat(app-wall): add itshan",
            developer: "itshan"
        )
        #expect(submission.id == "42")
        #expect(submission.prNumber == 42)
        #expect(submission.affordances["openPR"] == "open https://github.com/tddworks/asc-cli/pull/42")
    }
}
