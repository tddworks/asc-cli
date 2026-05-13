import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct VersionsUpdateTests {

    @Test func `updated version returns new version string with editable affordances`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).updateVersion(
            id: .any,
            versionString: .any,
            copyright: .any,
            releaseType: .any,
            earliestReleaseDate: .any
        ).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-7", versionString: "2.5.0", platform: .iOS, state: .prepareForSubmission)
        )

        let cmd = try VersionsUpdate.parse(["--version-id", "v-1", "--version", "2.5.0", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "checkReadiness" : "asc versions check-readiness --version-id v-1",
                "getReviewDetail" : "asc version-review-detail get --version-id v-1",
                "listLocalizations" : "asc version-localizations list --version-id v-1",
                "listVersions" : "asc versions list --app-id app-7",
                "submitForReview" : "asc versions submit --version-id v-1",
                "updateVersion" : "asc versions update --version-id v-1"
              },
              "appId" : "app-7",
              "id" : "v-1",
              "platform" : "IOS",
              "state" : "PREPARE_FOR_SUBMISSION",
              "versionString" : "2.5.0"
            }
          ]
        }
        """)
    }

    @Test func `copyright flag is forwarded to repo update`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).updateVersion(
            id: .any, versionString: .any, copyright: .any, releaseType: .any, earliestReleaseDate: .any
        ).willReturn(
            AppStoreVersion(
                id: "v-1", appId: "app-7", versionString: "1.0.0",
                platform: .iOS, state: .prepareForSubmission,
                copyright: "© 2026 onegai"
            )
        )

        let cmd = try VersionsUpdate.parse([
            "--version-id", "v-1",
            "--copyright", "© 2026 onegai",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateVersion(
            id: .value("v-1"),
            versionString: .value(nil),
            copyright: .value("© 2026 onegai"),
            releaseType: .value(nil),
            earliestReleaseDate: .value(nil)
        ).called(1)
    }

    @Test func `release type and earliest release date flags are forwarded to repo update`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).updateVersion(
            id: .any, versionString: .any, copyright: .any, releaseType: .any, earliestReleaseDate: .any
        ).willReturn(
            AppStoreVersion(
                id: "v-1", appId: "app-7", versionString: "1.0.0",
                platform: .iOS, state: .prepareForSubmission,
                releaseType: "SCHEDULED",
                earliestReleaseDate: "2026-06-01T00:00:00Z"
            )
        )

        let cmd = try VersionsUpdate.parse([
            "--version-id", "v-1",
            "--release-type", "SCHEDULED",
            "--earliest-release-date", "2026-06-01T00:00:00Z",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateVersion(
            id: .value("v-1"),
            versionString: .value(nil),
            copyright: .value(nil),
            releaseType: .value("SCHEDULED"),
            earliestReleaseDate: .value("2026-06-01T00:00:00Z")
        ).called(1)
    }

    @Test func `version flag stays optional when omitted`() async throws {
        let mockRepo = MockVersionRepository()
        given(mockRepo).updateVersion(
            id: .any, versionString: .any, copyright: .any, releaseType: .any, earliestReleaseDate: .any
        ).willReturn(
            AppStoreVersion(id: "v-1", appId: "app-7", versionString: "1.0.0", platform: .iOS, state: .prepareForSubmission)
        )

        let cmd = try VersionsUpdate.parse([
            "--version-id", "v-1",
            "--copyright", "© 2026 onegai",
        ])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateVersion(
            id: .value("v-1"),
            versionString: .value(nil),
            copyright: .value("© 2026 onegai"),
            releaseType: .value(nil),
            earliestReleaseDate: .value(nil)
        ).called(1)
    }
}
