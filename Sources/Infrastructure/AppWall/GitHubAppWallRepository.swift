import Domain
import Foundation

public struct GitHubAppWallRepository: AppWallRepository {
    private let token: String
    private let httpClient: any HTTPPerforming
    private let upstreamOwner: String
    private let upstreamRepo: String
    private let filePath: String
    private let sleep: @Sendable (Duration) async throws -> Void

    public init(
        token: String,
        httpClient: (any HTTPPerforming)? = nil,
        upstreamOwner: String = "tddworks",
        upstreamRepo: String = "asc-cli",
        filePath: String = "homepage/apps.json",
        sleep: (@Sendable (Duration) async throws -> Void)? = nil
    ) {
        self.token = token
        self.httpClient = httpClient ?? URLSession.shared
        self.upstreamOwner = upstreamOwner
        self.upstreamRepo = upstreamRepo
        self.filePath = filePath
        self.sleep = sleep ?? { try await Task.sleep(for: $0) }
    }

    // MARK: - AppWallRepository

    public func submit(app: AppWallApp) async throws -> AppWallSubmission {
        // 1. Resolve authenticated GitHub username
        let username = try await getAuthenticatedUser()

        // 2. Fork the repo (idempotent)
        try await forkRepo()

        // 3. Sync fork to upstream main
        try await syncFork(owner: username)

        // 4. Fetch current file — retry briefly while fork initialises
        let (currentApps, baseSHA) = try await getFileWithRetry(owner: username)

        // 5. Guard against duplicate entries
        let isDuplicate = currentApps.contains { $0.developer == app.developer }
        guard !isDuplicate else {
            throw AppWallError.alreadySubmitted(developer: app.developer)
        }

        // 6. Encode updated array
        let newContent = try encodeApps(currentApps + [app])

        // 7. Create feature branch
        let branchName = "app-wall/\(app.developer)"
        try await createBranch(owner: username, branchName: branchName)

        // 8. Commit file update to feature branch
        try await updateFile(owner: username, branchName: branchName, content: newContent, sha: baseSHA, app: app)

        // 9. Open pull request
        return try await createPR(fromOwner: username, branchName: branchName, app: app)
    }

    // MARK: - GitHub API helpers

    private func getAuthenticatedUser() async throws -> String {
        struct User: Decodable { let login: String }
        let response: User = try await apiGet(url: githubURL("user"))
        return response.login
    }

    private func forkRepo() async throws {
        let url = githubURL("repos/\(upstreamOwner)/\(upstreamRepo)/forks")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        addHeaders(to: &request)
        let (_, response) = try await httpClient.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        // 202 = fork queued, 200/201 = already exists
        guard (200...202).contains(statusCode) else {
            throw AppWallError.githubAPIError(statusCode: statusCode, message: "Fork failed")
        }
    }

    private func syncFork(owner: String) async throws {
        let url = githubURL("repos/\(owner)/\(upstreamRepo)/merge-upstream")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: ["branch": "main"])
        addHeaders(to: &request)
        // Best-effort: ignore errors (fork may not exist yet or may already be up to date)
        _ = try? await httpClient.data(for: request)
    }

    private func getFileWithRetry(owner: String) async throws -> ([AppWallApp], String) {
        let maxAttempts = 8
        var lastError: Error = AppWallError.forkTimeout
        for attempt in 1...maxAttempts {
            do {
                return try await getFile(owner: owner)
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try await self.sleep(.seconds(3))
                }
            }
        }
        throw lastError
    }

    private func getFile(owner: String) async throws -> ([AppWallApp], String) {
        struct FileContent: Decodable {
            let sha: String
            let content: String
            let encoding: String
        }
        let url = githubURL("repos/\(owner)/\(upstreamRepo)/contents/\(filePath)")
        let fileContent: FileContent = try await apiGet(url: url)
        guard fileContent.encoding == "base64" else {
            throw AppWallError.githubAPIError(statusCode: 0, message: "Unexpected encoding: \(fileContent.encoding)")
        }
        let cleaned = fileContent.content.components(separatedBy: .newlines).joined()
        guard let data = Data(base64Encoded: cleaned) else {
            throw AppWallError.githubAPIError(statusCode: 0, message: "Failed to decode base64 file content")
        }
        let apps = try JSONDecoder().decode([AppWallApp].self, from: data)
        return (apps, fileContent.sha)
    }

    private func createBranch(owner: String, branchName: String) async throws {
        struct Ref: Decodable {
            struct Object: Decodable { let sha: String }
            let object: Object
        }
        let ref: Ref = try await apiGet(url: githubURL("repos/\(owner)/\(upstreamRepo)/git/refs/heads/main"))
        let mainSHA = ref.object.sha

        let url = githubURL("repos/\(owner)/\(upstreamRepo)/git/refs")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ref": "refs/heads/\(branchName)",
            "sha": mainSHA
        ])
        addHeaders(to: &request)
        let (_, response) = try await httpClient.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        // 201 = created, 422 = already exists (acceptable)
        guard statusCode == 201 || statusCode == 422 else {
            throw AppWallError.githubAPIError(statusCode: statusCode, message: "Failed to create branch \(branchName)")
        }
    }

    private func updateFile(owner: String, branchName: String, content: Data, sha: String, app: AppWallApp) async throws {
        let url = githubURL("repos/\(owner)/\(upstreamRepo)/contents/\(filePath)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "message": "feat(app-wall): add \(app.developer)",
            "content": content.base64EncodedString(),
            "sha": sha,
            "branch": branchName
        ])
        addHeaders(to: &request)
        let (_, response) = try await httpClient.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...201).contains(statusCode) else {
            throw AppWallError.githubAPIError(statusCode: statusCode, message: "Failed to update \(filePath)")
        }
    }

    private func createPR(fromOwner: String, branchName: String, app: AppWallApp) async throws -> AppWallSubmission {
        struct PR: Decodable {
            let number: Int
            let html_url: String
            let title: String
        }
        let url = githubURL("repos/\(upstreamOwner)/\(upstreamRepo)/pulls")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        var bodyLines = [
            "## Add \(app.developer) to the app wall",
            "",
            "- **Developer**: \(app.developer)",
        ]
        if let devId = app.developerId { bodyLines.append("- **Developer ID**: \(devId)") }
        if let gh = app.github        { bodyLines.append("- **GitHub**: @\(gh)") }
        if let x = app.x              { bodyLines.append("- **X**: @\(x)") }
        if let appUrls = app.apps     { bodyLines.append("- **Apps**: \(appUrls.joined(separator: ", "))") }
        bodyLines.append("")
        bodyLines.append("_Submitted via `asc app-wall submit`_")

        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "title": "feat(app-wall): add \(app.developer)",
            "head": "\(fromOwner):\(branchName)",
            "base": "main",
            "body": bodyLines.joined(separator: "\n")
        ])
        addHeaders(to: &request)
        let (data, response) = try await httpClient.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...201).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw AppWallError.githubAPIError(statusCode: statusCode, message: body)
        }
        let pr = try JSONDecoder().decode(PR.self, from: data)
        return AppWallSubmission(
            prNumber: pr.number,
            prUrl: pr.html_url,
            title: pr.title,
            developer: app.developer
        )
    }

    // MARK: - Utilities

    private func apiGet<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        addHeaders(to: &request)
        let (data, response) = try await httpClient.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let message = (try? JSONDecoder().decode(GitHubErrorResponse.self, from: data))?.message ?? "(no message)"
            throw AppWallError.githubAPIError(statusCode: statusCode, message: message)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func addHeaders(to request: inout URLRequest) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("asc-cli", forHTTPHeaderField: "User-Agent")
    }

    private func githubURL(_ path: String) -> URL {
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        guard let url = URL(string: "https://api.github.com/\(encoded)") else {
            preconditionFailure("Invalid GitHub URL path: \(path)")
        }
        return url
    }

    private func encodeApps(_ apps: [AppWallApp]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        return try encoder.encode(apps)
    }
}

private struct GitHubErrorResponse: Decodable {
    let message: String
}
