import Foundation
import Testing
@testable import Domain

@Suite
struct ExperimentTreatmentLocalizationTests {

    @Test func `treatment localization carries treatmentId and locale`() {
        let loc = MockRepositoryFactory.makeExperimentTreatmentLocalization(id: "loc-1", treatmentId: "trt-1", locale: "en-US")
        #expect(loc.treatmentId == "trt-1")
        #expect(loc.locale == "en-US")
    }

    @Test func `treatment localization offers siblings and delete`() {
        let loc = MockRepositoryFactory.makeExperimentTreatmentLocalization(id: "loc-1", treatmentId: "trt-1")
        #expect(loc.affordances["listSiblings"] == "asc experiment-treatment-localizations list --treatment-id trt-1")
        #expect(loc.affordances["delete"] == "asc experiment-treatment-localizations delete --localization-id loc-1")
    }

    @Test func `treatment localization apiLinks resolve to REST paths`() {
        let loc = MockRepositoryFactory.makeExperimentTreatmentLocalization(id: "loc-1", treatmentId: "trt-1")
        #expect(loc.apiLinks["listSiblings"]?.href == "/api/v1/experiment-treatments/trt-1/experiment-treatment-localizations")
        #expect(loc.apiLinks["delete"]?.href == "/api/v1/experiment-treatment-localizations/loc-1")
        #expect(loc.apiLinks["delete"]?.method == "DELETE")
    }

    @Test func `treatment localization table row shows locale`() {
        let loc = MockRepositoryFactory.makeExperimentTreatmentLocalization(id: "loc-1", treatmentId: "trt-1", locale: "de-DE")
        #expect(ExperimentTreatmentLocalization.tableHeaders == ["ID", "Locale"])
        #expect(loc.tableRow == ["loc-1", "de-DE"])
    }

    @Test func `should point to the asset placements on the treatment localization`() {
        let loc = MockRepositoryFactory.makeExperimentTreatmentLocalization(id: "loc-1", treatmentId: "trt-1")
        #expect(loc.affordances["listPlacements"] == "asc asset-placements list --treatment-localization-id loc-1")
        #expect(loc.apiLinks["listPlacements"] == APILink(href: "/api/v1/experiment-treatment-localizations/loc-1/placements", method: "GET"))
    }
}
