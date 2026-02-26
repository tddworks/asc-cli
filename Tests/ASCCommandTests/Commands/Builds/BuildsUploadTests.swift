import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsUploadCommandTests {

    // MARK: - Platform resolution

    @Test func `auto-detects iOS platform from ipa extension`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .value(.iOS), fileURL: .any)
            .willReturn(BuildUpload(id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1", platform: .iOS, state: .complete))

        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.ipa", "--version", "1.0", "--build-number", "1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkStatus" : "asc builds uploads get --upload-id up-1",
                "listBuilds" : "asc builds list --app-id app-1"
              },
              "appId" : "app-1",
              "buildNumber" : "1",
              "id" : "up-1",
              "platform" : "IOS",
              "state" : "COMPLETE",
              "version" : "1.0"
            }
          ]
        }
        """)
    }

    @Test func `auto-detects macOS platform from pkg extension`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .value(.macOS), fileURL: .any)
            .willReturn(BuildUpload(id: "up-2", appId: "app-1", version: "1.0", buildNumber: "1", platform: .macOS, state: .complete))

        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.pkg", "--version", "1.0", "--build-number", "1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkStatus" : "asc builds uploads get --upload-id up-2",
                "listBuilds" : "asc builds list --app-id app-1"
              },
              "appId" : "app-1",
              "buildNumber" : "1",
              "id" : "up-2",
              "platform" : "MAC_OS",
              "state" : "COMPLETE",
              "version" : "1.0"
            }
          ]
        }
        """)
    }

    @Test func `uses explicit platform when provided`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .value(.tvOS), fileURL: .any)
            .willReturn(BuildUpload(id: "up-3", appId: "app-1", version: "1.0", buildNumber: "1", platform: .tvOS, state: .complete))

        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.ipa", "--version", "1.0", "--build-number", "1", "--platform", "tvos", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkStatus" : "asc builds uploads get --upload-id up-3",
                "listBuilds" : "asc builds list --app-id app-1"
              },
              "appId" : "app-1",
              "buildNumber" : "1",
              "id" : "up-3",
              "platform" : "TV_OS",
              "state" : "COMPLETE",
              "version" : "1.0"
            }
          ]
        }
        """)
    }

    @Test func `throws for unknown explicit platform`() async throws {
        let mockRepo = MockBuildUploadRepository()
        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.ipa", "--version", "1.0", "--build-number", "1", "--platform", "watchos"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    // MARK: - Wait flag

    @Test func `wait returns upload when immediately complete`() async throws {
        let mockRepo = MockBuildUploadRepository()
        let completed = BuildUpload(id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1", platform: .iOS, state: .complete)
        given(mockRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .any, fileURL: .any).willReturn(completed)
        given(mockRepo).getBuildUpload(id: .any).willReturn(completed)

        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.ipa", "--version", "1.0", "--build-number", "1", "--wait", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkStatus" : "asc builds uploads get --upload-id up-1",
                "listBuilds" : "asc builds list --app-id app-1"
              },
              "appId" : "app-1",
              "buildNumber" : "1",
              "id" : "up-1",
              "platform" : "IOS",
              "state" : "COMPLETE",
              "version" : "1.0"
            }
          ]
        }
        """)
    }

    @Test func `wait throws when upload fails with no details`() async throws {
        let mockRepo = MockBuildUploadRepository()
        let failed = BuildUpload(id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1", platform: .iOS, state: .failed)
        given(mockRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .any, fileURL: .any).willReturn(failed)
        given(mockRepo).getBuildUpload(id: .any).willReturn(failed)

        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.ipa", "--version", "1.0", "--build-number", "1", "--wait"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `wait throws with error details when upload fails`() async throws {
        let mockRepo = MockBuildUploadRepository()
        let failed = BuildUpload(
            id: "up-1", appId: "app-1", version: "1.0", buildNumber: "1", platform: .iOS, state: .failed,
            errors: [BuildUploadStateDetail(code: "INVALID_BINARY", description: "Binary rejected")]
        )
        given(mockRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .any, fileURL: .any).willReturn(failed)
        given(mockRepo).getBuildUpload(id: .any).willReturn(failed)

        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.ipa", "--version", "1.0", "--build-number", "1", "--wait"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    // MARK: - Table output

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockBuildUploadRepository()
        given(mockRepo).uploadBuild(appId: .any, version: .any, buildNumber: .any, platform: .any, fileURL: .any)
            .willReturn(BuildUpload(id: "up-1", appId: "app-1", version: "2.0", buildNumber: "42", platform: .iOS, state: .complete))

        let cmd = try BuildsUpload.parse(["--app-id", "app-1", "--file", "/tmp/App.ipa", "--version", "2.0", "--build-number", "42", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("up-1"))
        #expect(output.contains("2.0"))
        #expect(output.contains("COMPLETE"))
    }
}
