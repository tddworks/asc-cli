import Foundation
import Testing
@testable import ASCKit

@Suite("AppWallApp")
struct AppWallAppTests {

    @Test func `app with developer field`() {
        let app = AppWallApp(developer: "itshan")
        #expect(app.developer == "itshan")
        #expect(app.developerId == nil)
        #expect(app.github == nil)
        #expect(app.x == nil)
        #expect(app.apps == nil)
    }

    @Test func `app with all fields`() {
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

    @Test func `app without developer just apps`() {
        let app = AppWallApp(apps: ["https://apps.apple.com/app/id6446381990"])
        #expect(app.developer == nil)
        #expect(app.apps == ["https://apps.apple.com/app/id6446381990"])
        #expect(app.hasAppSource == true)
    }

    @Test func `app without developer just developerId`() {
        let app = AppWallApp(developerId: "1725133580")
        #expect(app.developer == nil)
        #expect(app.developerId == "1725133580")
        #expect(app.hasAppSource == true)
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

    @Test func `nil developer is omitted from JSON`() throws {
        let app = AppWallApp(developerId: "123")
        let data = try JSONEncoder().encode(app)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("\"developer\""))
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

    @Test func `codable round trip without developer`() throws {
        let app = AppWallApp(apps: ["https://apps.apple.com/app/id6446381990"])
        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(AppWallApp.self, from: data)
        #expect(decoded == app)
    }

    @Test func `hasAppSource is false when neither developerId nor apps provided`() {
        let app = AppWallApp(developer: "tddworks", github: "tddworks")
        #expect(app.hasAppSource == false)
    }

    @Test func `hasAppSource is true when developerId is set`() {
        let app = AppWallApp(developer: "itshan", developerId: "1725133580")
        #expect(app.hasAppSource == true)
    }

    @Test func `hasAppSource is true when apps array is provided`() {
        let app = AppWallApp(developer: "jane", apps: ["https://apps.apple.com/us/app/x/id123"])
        #expect(app.hasAppSource == true)
    }

    @Test func `branchLabel uses developer when present`() {
        let app = AppWallApp(developer: "itshan", developerId: "1725133580")
        #expect(app.branchLabel == "itshan")
    }

    @Test func `branchLabel falls back to developerId`() {
        let app = AppWallApp(developerId: "1725133580")
        #expect(app.branchLabel == "1725133580")
    }

    @Test func `branchLabel falls back to first app url id`() {
        let app = AppWallApp(apps: ["https://apps.apple.com/app/id6446381990"])
        #expect(app.branchLabel == "6446381990")
    }

    @Test func `branchLabel extracts id from complex app store url`() {
        let app = AppWallApp(apps: ["https://apps.apple.com/us/app/my-app/id999"])
        #expect(app.branchLabel == "999")
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
