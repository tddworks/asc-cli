import Testing
@testable import Domain

@Suite("AppWallError — error descriptions")
struct AppWallErrorTests {

    @Test func `alreadySubmitted names the developer`() {
        let error = AppWallError.alreadySubmitted(developer: "tddworks")
        #expect(error.errorDescription == "Developer tddworks is already listed in the app wall.")
    }

    @Test func `forkTimeout suggests retry`() {
        let error = AppWallError.forkTimeout
        #expect(error.errorDescription == "Timed out waiting for fork to be ready. Please try again in a moment.")
    }

    @Test func `githubAPIError includes status code and message`() {
        let error = AppWallError.githubAPIError(statusCode: 422, message: "Unprocessable Entity")
        #expect(error.errorDescription == "GitHub API error (422): Unprocessable Entity")
    }

    @Test func `equatable distinguishes cases by associated value`() {
        #expect(AppWallError.alreadySubmitted(developer: "a") == .alreadySubmitted(developer: "a"))
        #expect(AppWallError.alreadySubmitted(developer: "a") != .alreadySubmitted(developer: "b"))
        #expect(AppWallError.forkTimeout == .forkTimeout)
        #expect(AppWallError.githubAPIError(statusCode: 500, message: "x") != .githubAPIError(statusCode: 500, message: "y"))
    }
}
