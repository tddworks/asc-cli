import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

private func makeTreatment(id: String = "trt-1", experimentId: String = "exp-1", appIconName: String? = "AppIcon-Blue") -> ExperimentTreatment {
    ExperimentTreatment(id: id, experimentId: experimentId, name: "Blue icon", appIconName: appIconName)
}

@Suite
struct ExperimentTreatmentsListTests {

    @Test func `listed treatments show icon name and localization affordances`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).listTreatments(experimentId: .any, limit: .any)
            .willReturn(PaginatedResponse(data: [makeTreatment()], nextCursor: nil))

        let cmd = try ExperimentTreatmentsList.parse(["--experiment-id", "exp-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "createLocalization" : "asc experiment-treatment-localizations create --locale <locale> --treatment-id trt-1",
                "delete" : "asc experiment-treatments delete --treatment-id trt-1",
                "listLocalizations" : "asc experiment-treatment-localizations list --treatment-id trt-1",
                "listSiblings" : "asc experiment-treatments list --experiment-id exp-1",
                "update" : "asc experiment-treatments update --treatment-id trt-1"
              },
              "appIconName" : "AppIcon-Blue",
              "experimentId" : "exp-1",
              "id" : "trt-1",
              "name" : "Blue icon"
            }
          ]
        }
        """)
        verify(mockRepo).listTreatments(experimentId: .value("exp-1"), limit: .value(nil)).called(1)
    }
}

@Suite
struct ExperimentTreatmentsCreateTests {

    @Test func `create passes name and icon and shows the new treatment`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).createTreatment(experimentId: .any, name: .any, appIconName: .any).willReturn(makeTreatment())

        let cmd = try ExperimentTreatmentsCreate.parse([
            "--experiment-id", "exp-1", "--name", "Blue icon", "--app-icon-name", "AppIcon-Blue",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\":\"trt-1\""))
        #expect(output.contains("\"appIconName\":\"AppIcon-Blue\""))
        verify(mockRepo).createTreatment(
            experimentId: .value("exp-1"), name: .value("Blue icon"), appIconName: .value("AppIcon-Blue")
        ).called(1)
    }
}

@Suite
struct ExperimentTreatmentsUpdateTests {

    @Test func `update forwards only the provided fields`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).updateTreatment(treatmentId: .any, name: .any, appIconName: .any).willReturn(makeTreatment())

        let cmd = try ExperimentTreatmentsUpdate.parse(["--treatment-id", "trt-1", "--name", "Red icon"])
        _ = try await cmd.execute(repo: mockRepo)

        verify(mockRepo).updateTreatment(treatmentId: .value("trt-1"), name: .value("Red icon"), appIconName: .value(nil)).called(1)
    }

    @Test func `update requires at least one field`() async throws {
        let mockRepo = MockExperiments()
        let cmd = try ExperimentTreatmentsUpdate.parse(["--treatment-id", "trt-1"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }
}

@Suite
struct ExperimentTreatmentsDeleteTests {

    @Test func `delete calls the repository with the treatment id`() async throws {
        let mockRepo = MockExperiments()
        given(mockRepo).deleteTreatment(treatmentId: .any).willReturn(())

        let cmd = try ExperimentTreatmentsDelete.parse(["--treatment-id", "trt-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteTreatment(treatmentId: .value("trt-1")).called(1)
    }
}
