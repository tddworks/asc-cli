import Testing
@testable import Domain

@Suite
struct NextBuildNumberTests {

    @Test func `next build number is 1 when no builds exist`() {
        let result = NextBuildNumber(appId: "app-1", version: "1.0.0", platform: .iOS, nextBuildNumber: 1)
        #expect(result.nextBuildNumber == 1)
    }

    @Test func `next build number carries app context`() {
        let result = NextBuildNumber(appId: "app-1", version: "2.0", platform: .macOS, nextBuildNumber: 5)
        #expect(result.appId == "app-1")
        #expect(result.version == "2.0")
        #expect(result.platform == .macOS)
        #expect(result.nextBuildNumber == 5)
    }

    @Test func `affordances include upload build command`() {
        let result = NextBuildNumber(appId: "app-1", version: "1.0.0", platform: .iOS, nextBuildNumber: 4)
        #expect(result.affordances["uploadBuild"] == "asc builds upload --app-id app-1 --file <path> --version 1.0.0 --build-number 4 --platform ios")
    }

    @Test func `affordances include archive command`() {
        let result = NextBuildNumber(appId: "app-1", version: "1.0.0", platform: .iOS, nextBuildNumber: 4)
        #expect(result.affordances["archiveAndUpload"] == "asc builds archive --scheme <scheme> --platform ios --upload --app-id app-1 --version 1.0.0 --build-number 4")
    }

    @Test func `computeNextBuildNumber returns 1 for empty builds`() {
        let result = NextBuildNumber.compute(appId: "app-1", version: "1.0", platform: .iOS, builds: [])
        #expect(result.nextBuildNumber == 1)
    }

    @Test func `computeNextBuildNumber returns max plus one`() {
        let builds = [
            MockRepositoryFactory.makeBuild(id: "b-1", buildNumber: "3"),
            MockRepositoryFactory.makeBuild(id: "b-2", buildNumber: "1"),
            MockRepositoryFactory.makeBuild(id: "b-3", buildNumber: "2"),
        ]
        let result = NextBuildNumber.compute(appId: "app-1", version: "1.0", platform: .iOS, builds: builds)
        #expect(result.nextBuildNumber == 4)
    }

    @Test func `computeNextBuildNumber skips non-numeric build numbers`() {
        let builds = [
            MockRepositoryFactory.makeBuild(id: "b-1", buildNumber: "2"),
            MockRepositoryFactory.makeBuild(id: "b-2", buildNumber: "abc"),
            MockRepositoryFactory.makeBuild(id: "b-3", buildNumber: "1"),
        ]
        let result = NextBuildNumber.compute(appId: "app-1", version: "1.0", platform: .iOS, builds: builds)
        #expect(result.nextBuildNumber == 3)
    }

    @Test func `computeNextBuildNumber skips nil build numbers`() {
        let builds = [
            MockRepositoryFactory.makeBuild(id: "b-1", buildNumber: "5"),
            MockRepositoryFactory.makeBuild(id: "b-2", buildNumber: nil),
        ]
        let result = NextBuildNumber.compute(appId: "app-1", version: "1.0", platform: .iOS, builds: builds)
        #expect(result.nextBuildNumber == 6)
    }
}
