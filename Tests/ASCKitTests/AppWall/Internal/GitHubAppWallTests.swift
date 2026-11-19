import Foundation
import Testing
@testable import ASCKit

@Suite
struct GitHubAppWallTests {

    // MARK: - Happy Path

    @Test func `submit returns AppWallSubmission on happy path`() async throws {
        let stub = SequencedStubHTTPClient()
        enqueueHappyPath(stub)

        let repo = makeRepo(stub: stub)
        let app = AppWallApp(developer: "itshan", developerId: "123456789")
        let result = try await repo.submit(app: app)

        #expect(result.prNumber == 1)
        #expect(result.prUrl == "https://github.com/tddworks/asc-cli/pull/1")
        #expect(result.developer == "itshan")
    }

    // MARK: - Duplicate Guard

    @Test func `submit throws alreadySubmitted when developer already in file`() async throws {
        let stub = SequencedStubHTTPClient()
        // Step 1: GET /user
        stub.enqueue(json: #"{"login":"octocat"}"#)
        // Step 2: POST /forks
        stub.enqueue(json: "{}", statusCode: 202)
        // Step 3: POST /merge-upstream (best-effort, ignored)
        stub.enqueue(json: "{}")
        // Step 4: GET /contents — file already contains "itshan"
        let existingJSON = #"[{"developer":"itshan"}]"#
        let encoded = Data(existingJSON.utf8).base64EncodedString()
        stub.enqueue(json: #"{"sha":"deadbeef","content":"\#(encoded)","encoding":"base64"}"#)

        let repo = makeRepo(stub: stub)
        let app = AppWallApp(developer: "itshan")
        do {
            _ = try await repo.submit(app: app)
            Issue.record("Expected alreadySubmitted error")
        } catch AppWallError.alreadySubmitted(let developer) {
            #expect(developer == "itshan")
        }
    }

    // MARK: - API Error Propagation

    @Test func `submit throws githubAPIError when fork returns 500`() async throws {
        let stub = SequencedStubHTTPClient()
        // Step 1: GET /user
        stub.enqueue(json: #"{"login":"octocat"}"#)
        // Step 2: POST /forks → 500
        stub.enqueue(json: #"{"message":"Internal Server Error"}"#, statusCode: 500)

        let repo = makeRepo(stub: stub)
        let app = AppWallApp(developer: "itshan")
        do {
            _ = try await repo.submit(app: app)
            Issue.record("Expected githubAPIError")
        } catch AppWallError.githubAPIError(let statusCode, _) {
            #expect(statusCode == 500)
        }
    }

    @Test func `submit throws githubAPIError when createPR returns 422`() async throws {
        let stub = SequencedStubHTTPClient()
        // Steps 1–7 succeed
        enqueueHappyPath(stub, prStatusCode: 422, prJSON: #"{"message":"Unprocessable Entity"}"#)

        let repo = makeRepo(stub: stub)
        let app = AppWallApp(developer: "itshan")
        do {
            _ = try await repo.submit(app: app)
            Issue.record("Expected githubAPIError")
        } catch AppWallError.githubAPIError(let statusCode, _) {
            #expect(statusCode == 422)
        }
    }

    // MARK: - PR Target URL

    @Test func `submit opens PR against upstream owner not fork owner`() async throws {
        let stub = SequencedStubHTTPClient()
        enqueueHappyPath(stub)

        let repo = makeRepo(stub: stub)
        let app = AppWallApp(developer: "itshan")
        _ = try await repo.submit(app: app)

        // Request 8 (index 7) is the POST /pulls — must target tddworks/asc-cli
        let prRequest = stub.capturedRequests[7]
        #expect(prRequest.url?.absoluteString == "https://api.github.com/repos/tddworks/asc-cli/pulls")
    }

    // MARK: - Retry Logic

    @Test func `getFileWithRetry retries on transient error`() async throws {
        let stub = SequencedStubHTTPClient()
        // Step 1: GET /user
        stub.enqueue(json: #"{"login":"octocat"}"#)
        // Step 2: POST /forks
        stub.enqueue(json: "{}", statusCode: 202)
        // Step 3: POST /merge-upstream
        stub.enqueue(json: "{}")
        // Step 4a: GET /contents → 404 (first attempt fails)
        stub.enqueue(json: #"{"message":"Not Found"}"#, statusCode: 404)
        // Step 4b: GET /contents → 200 (second attempt succeeds)
        let encoded = Data("[]".utf8).base64EncodedString()
        stub.enqueue(json: #"{"sha":"abc123","content":"\#(encoded)","encoding":"base64"}"#)
        // Step 5: GET /git/refs/heads/main
        stub.enqueue(json: #"{"object":{"sha":"abc"}}"#)
        // Step 6: POST /git/refs → 201
        stub.enqueue(json: "{}", statusCode: 201)
        // Step 7: PUT /contents → 200
        stub.enqueue(json: "{}")
        // Step 8: POST /pulls → 201
        stub.enqueue(
            json: #"{"number":1,"html_url":"https://github.com/tddworks/asc-cli/pull/1","title":"feat(app-wall): add itshan"}"#,
            statusCode: 201
        )

        let noopSleep: @Sendable (Duration) async throws -> Void = { _ in }
        let repo = GitHubAppWall(
            token: "test-token",
            httpClient: stub,
            upstreamOwner: "tddworks",
            upstreamRepo: "asc-cli",
            filePath: "homepage/apps.json",
            sleep: noopSleep
        )
        let app = AppWallApp(developer: "itshan")
        let result = try await repo.submit(app: app)

        #expect(result.prNumber == 1)
        // Verify that a retry happened: GET /contents was called twice
        let contentGETs = stub.capturedRequests.filter {
            $0.url?.path.contains("contents") == true && ($0.httpMethod == nil || $0.httpMethod == "GET")
        }
        #expect(contentGETs.count == 2)
    }

    // MARK: - Helpers

    private func makeRepo(stub: SequencedStubHTTPClient) -> GitHubAppWall {
        let noopSleep: @Sendable (Duration) async throws -> Void = { _ in }
        return GitHubAppWall(
            token: "test-token",
            httpClient: stub,
            upstreamOwner: "tddworks",
            upstreamRepo: "asc-cli",
            filePath: "homepage/apps.json",
            sleep: noopSleep
        )
    }

    private func enqueueHappyPath(
        _ stub: SequencedStubHTTPClient,
        prStatusCode: Int = 201,
        prJSON: String = #"{"number":1,"html_url":"https://github.com/tddworks/asc-cli/pull/1","title":"feat(app-wall): add itshan"}"#
    ) {
        // 1. GET /user
        stub.enqueue(json: #"{"login":"octocat"}"#)
        // 2. POST /forks → 202
        stub.enqueue(json: "{}", statusCode: 202)
        // 3. POST /merge-upstream → 200 (best-effort)
        stub.enqueue(json: "{}")
        // 4. GET /contents/homepage/apps.json → base64([]) + sha
        let encoded = Data("[]".utf8).base64EncodedString()
        stub.enqueue(json: #"{"sha":"deadbeef","content":"\#(encoded)","encoding":"base64"}"#)
        // 5. GET /git/refs/heads/main
        stub.enqueue(json: #"{"object":{"sha":"abc"}}"#)
        // 6. POST /git/refs → 201
        stub.enqueue(json: "{}", statusCode: 201)
        // 7. PUT /contents/homepage/apps.json → 200
        stub.enqueue(json: "{}")
        // 8. POST /pulls → prStatusCode
        stub.enqueue(json: prJSON, statusCode: prStatusCode)
    }
}
