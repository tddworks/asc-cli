import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct BuildsListTests {

    @Test func `valid build includes TestFlight affordances`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "42", expired: false, processingState: .valid),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "addToTestFlight" : "asc builds add-beta-group --build-id b-1 --beta-group-id <beta-group-id>",
                "setEncryptionCompliance" : "asc builds set-encryption-compliance --build-id b-1 --uses-non-exempt-encryption <true|false>",
                "updateBetaNotes" : "asc builds update-beta-notes --build-id b-1 --locale en-US --notes <notes>"
              },
              "expired" : false,
              "id" : "b-1",
              "processingState" : "VALID",
              "version" : "42"
            }
          ]
        }
        """)
    }

    @Test func `build with platform and buildNumber shows all fields in JSON`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1.2.0", expired: false, processingState: .valid, buildNumber: "42", platform: .iOS),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "addToTestFlight" : "asc builds add-beta-group --build-id b-1 --beta-group-id <beta-group-id>",
                "setEncryptionCompliance" : "asc builds set-encryption-compliance --build-id b-1 --uses-non-exempt-encryption <true|false>",
                "updateBetaNotes" : "asc builds update-beta-notes --build-id b-1 --locale en-US --notes <notes>"
              },
              "buildNumber" : "42",
              "expired" : false,
              "id" : "b-1",
              "platform" : "IOS",
              "processingState" : "VALID",
              "version" : "1.2.0"
            }
          ]
        }
        """)
    }

    @Test func `table output includes build number and platform columns`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1.0", expired: false, processingState: .valid, buildNumber: "10", platform: .iOS),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse(["--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("b-1"))
        #expect(output.contains("1.0"))
        #expect(output.contains("10"))
        #expect(output.contains("IOS"))
        #expect(output.contains("VALID"))
    }

    @Test func `platform and version options are passed to repository`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .value(.iOS), version: .value("1.0"), limit: .any).willReturn(
            PaginatedResponse(data: [], nextCursor: nil)
        )

        let cmd = try BuildsList.parse(["--platform", "ios", "--version", "1.0", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }

    @Test func `expired build has no affordances`() async throws {
        let mockRepo = MockBuildRepository()
        given(mockRepo).listBuilds(appId: .any, platform: .any, version: .any, limit: .any).willReturn(
            PaginatedResponse(data: [
                Build(id: "b-1", version: "1", expired: true, processingState: .valid),
            ], nextCursor: nil)
        )

        let cmd = try BuildsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {

              },
              "expired" : true,
              "id" : "b-1",
              "processingState" : "VALID",
              "version" : "1"
            }
          ]
        }
        """)
    }
}
