import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct ExperimentTreatmentLocalizationsTests {

    @Test func `listed localizations show locale and delete affordance`() async throws {
        let mockRepo = MockExperimentRepository()
        given(mockRepo).listTreatmentLocalizations(treatmentId: .any, limit: .any).willReturn([
            ExperimentTreatmentLocalization(id: "loc-1", treatmentId: "trt-1", locale: "en-US"),
        ])

        let cmd = try ExperimentTreatmentLocalizationsList.parse(["--treatment-id", "trt-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "delete" : "asc experiment-treatment-localizations delete --localization-id loc-1",
                "listPlacements" : "asc asset-placements list --treatment-localization-id loc-1",
                "listSiblings" : "asc experiment-treatment-localizations list --treatment-id trt-1"
              },
              "id" : "loc-1",
              "locale" : "en-US",
              "treatmentId" : "trt-1"
            }
          ]
        }
        """)
    }

    @Test func `create passes locale and shows the new localization`() async throws {
        let mockRepo = MockExperimentRepository()
        given(mockRepo).createTreatmentLocalization(treatmentId: .any, locale: .any)
            .willReturn(ExperimentTreatmentLocalization(id: "loc-2", treatmentId: "trt-1", locale: "de-DE"))

        let cmd = try ExperimentTreatmentLocalizationsCreate.parse(["--treatment-id", "trt-1", "--locale", "de-DE"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"id\":\"loc-2\""))
        #expect(output.contains("\"locale\":\"de-DE\""))
        verify(mockRepo).createTreatmentLocalization(treatmentId: .value("trt-1"), locale: .value("de-DE")).called(1)
    }

    @Test func `delete calls the repository with the localization id`() async throws {
        let mockRepo = MockExperimentRepository()
        given(mockRepo).deleteTreatmentLocalization(localizationId: .any).willReturn(())

        let cmd = try ExperimentTreatmentLocalizationsDelete.parse(["--localization-id", "loc-1"])
        try await cmd.execute(repo: mockRepo)

        verify(mockRepo).deleteTreatmentLocalization(localizationId: .value("loc-1")).called(1)
    }
}
