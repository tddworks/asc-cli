import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

private func makeExperiment(
    id: String = "exp-1",
    appId: String = "app-1",
    state: AppStoreVersionExperimentState = .prepareForSubmission,
    startDate: String? = nil
) -> AppStoreVersionExperiment {
    AppStoreVersionExperiment(
        id: id, appId: appId, name: "Icon test", platform: .iOS,
        trafficProportion: 30, state: state, isReviewRequired: true, startDate: startDate
    )
}

@Suite
struct ExperimentsListTests {

    @Test func `listed editable experiment shows fields and treatment, update, delete affordances`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).listExperiments(appId: .any, state: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [makeExperiment()], nextCursor: nil))

        let cmd = try ExperimentsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createTreatment" : "asc experiment-treatments create --experiment-id exp-1 --name <name>",
                "delete" : "asc experiments delete --experiment-id exp-1",
                "listSiblings" : "asc experiments list --app-id app-1",
                "listTreatments" : "asc experiment-treatments list --experiment-id exp-1",
                "update" : "asc experiments update --experiment-id exp-1"
              },
              "appId" : "app-1",
              "canStart" : false,
              "id" : "exp-1",
              "isReviewRequired" : true,
              "isRunning" : false,
              "name" : "Icon test",
              "platform" : "IOS",
              "state" : "PREPARE_FOR_SUBMISSION",
              "trafficProportion" : 30
            }
          ]
        }
        """)
    }

    @Test func `listed running experiment shows stop affordance and startDate`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).listExperiments(appId: .any, state: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [makeExperiment(state: .approved, startDate: "2026-09-01T00:00:00Z")], nextCursor: nil))

        let cmd = try ExperimentsList.parse(["--app-id", "app-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc experiments list --app-id app-1",
                "listTreatments" : "asc experiment-treatments list --experiment-id exp-1",
                "stop" : "asc experiments stop --experiment-id exp-1"
              },
              "appId" : "app-1",
              "canStart" : false,
              "id" : "exp-1",
              "isReviewRequired" : true,
              "isRunning" : true,
              "name" : "Icon test",
              "platform" : "IOS",
              "startDate" : "2026-09-01T00:00:00Z",
              "state" : "APPROVED",
              "trafficProportion" : 30
            }
          ]
        }
        """)
    }

    @Test func `state flag is forwarded to the repository as a typed filter`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).listExperiments(appId: .any, state: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [], nextCursor: nil))

        let cmd = try ExperimentsList.parse(["--app-id", "app-1", "--state", "APPROVED", "--limit", "5"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == "{\"data\":[]}")
        verify(mockRepo).listExperiments(appId: .value("app-1"), state: .value(.approved), limit: .value(5)).called(1)
    }

    @Test func `unknown state flag is rejected`() async throws {
        let mockRepo = MockExperiments()
        let cmd = try ExperimentsList.parse(["--app-id", "app-1", "--state", "BOGUS"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `table output lists name, platform, traffic and state`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).listExperiments(appId: .any, state: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [makeExperiment()], nextCursor: nil))

        let cmd = try ExperimentsList.parse(["--app-id", "app-1", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("Icon test"))
        #expect(output.contains("iOS"))
        #expect(output.contains("PREPARE_FOR_SUBMISSION"))
    }
}

@Suite
struct ExperimentsGetTests {

    @Test func `get shows a single approved experiment with start affordance`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).getExperiment(experimentId: .any).willReturn(makeExperiment(state: .approved))

        let cmd = try ExperimentsGet.parse(["--experiment-id", "exp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listSiblings" : "asc experiments list --app-id app-1",
                "listTreatments" : "asc experiment-treatments list --experiment-id exp-1",
                "start" : "asc experiments start --experiment-id exp-1"
              },
              "appId" : "app-1",
              "canStart" : true,
              "id" : "exp-1",
              "isReviewRequired" : true,
              "isRunning" : false,
              "name" : "Icon test",
              "platform" : "IOS",
              "state" : "APPROVED",
              "trafficProportion" : 30
            }
          ]
        }
        """)
        verify(mockRepo).getExperiment(experimentId: .value("exp-1")).called(1)
    }
}

@Suite
struct ExperimentsCreateTests {

    @Test func `create passes name, platform and traffic proportion and shows the new test`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).createExperiment(appId: .any, name: .any, platform: .any, trafficProportion: .any)
            .willReturn(makeExperiment())

        let cmd = try ExperimentsCreate.parse([
            "--app-id", "app-1", "--name", "Icon test", "--platform", "ios", "--traffic-proportion", "30",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\":\"exp-1\""))
        #expect(output.contains("\"state\":\"PREPARE_FOR_SUBMISSION\""))
        verify(mockRepo).createExperiment(
            appId: .value("app-1"), name: .value("Icon test"), platform: .value(.iOS), trafficProportion: .value(30)
        ).called(1)
    }

    @Test func `create rejects traffic proportion outside 1-100`() async throws {
        let mockRepo = MockExperiments()
        let cmd = try ExperimentsCreate.parse(["--app-id", "app-1", "--name", "X", "--traffic-proportion", "0"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
        let tooHigh = try ExperimentsCreate.parse(["--app-id", "app-1", "--name", "X", "--traffic-proportion", "101"])
        await #expect(throws: (any Error).self) {
            try await tooHigh.execute(repo: mockRepo)
        }
    }

    @Test func `create rejects unknown platform`() async throws {
        let mockRepo = MockExperiments()
        let cmd = try ExperimentsCreate.parse(["--app-id", "app-1", "--name", "X", "--platform", "android", "--traffic-proportion", "30"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}

@Suite
struct ExperimentsUpdateTests {

    @Test func `update forwards only the provided fields and never touches started`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).updateExperiment(experimentId: .any, name: .any, trafficProportion: .any, isStarted: .any)
            .willReturn(makeExperiment())

        let cmd = try ExperimentsUpdate.parse(["--experiment-id", "exp-1", "--traffic-proportion", "40"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\":\"exp-1\""))
        verify(mockRepo).updateExperiment(
            experimentId: .value("exp-1"), name: .value(nil), trafficProportion: .value(40), isStarted: .value(nil)
        ).called(1)
    }

    @Test func `update requires at least one field`() async throws {
        let mockRepo = MockExperiments()
        let cmd = try ExperimentsUpdate.parse(["--experiment-id", "exp-1"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}

@Suite
struct ExperimentsStartStopTests {

    @Test func `start sets started to true and shows the running test`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).updateExperiment(experimentId: .any, name: .any, trafficProportion: .any, isStarted: .any)
            .willReturn(makeExperiment(state: .approved, startDate: "2026-09-01T00:00:00Z"))

        let cmd = try ExperimentsStart.parse(["--experiment-id", "exp-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"isRunning\":true"))
        verify(mockRepo).updateExperiment(
            experimentId: .value("exp-1"), name: .value(nil), trafficProportion: .value(nil), isStarted: .value(true)
        ).called(1)
    }

    @Test func `stop sets started to false`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).updateExperiment(experimentId: .any, name: .any, trafficProportion: .any, isStarted: .any)
            .willReturn(makeExperiment(state: .stopped, startDate: "2026-09-01T00:00:00Z"))

        let cmd = try ExperimentsStop.parse(["--experiment-id", "exp-1"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"state\":\"STOPPED\""))
        verify(mockRepo).updateExperiment(
            experimentId: .value("exp-1"), name: .value(nil), trafficProportion: .value(nil), isStarted: .value(false)
        ).called(1)
    }
}

@Suite
struct ExperimentsDeleteTests {

    @Test func `delete calls the repository with the experiment id`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).deleteExperiment(experimentId: .any).willReturn(())

        let cmd = try ExperimentsDelete.parse(["--experiment-id", "exp-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteExperiment(experimentId: .value("exp-1")).called(1)
    }
}
