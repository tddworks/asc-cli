import Foundation
import Testing
@testable import ASCKit

@Suite
struct ExperimentTreatmentTests {

    @Test func `treatment carries experimentId and name`() {
        let t = MockRepositoryFactory.makeExperimentTreatment(id: "trt-1", experimentId: "exp-1", name: "Blue icon", appIconName: "AppIcon-Blue")
        #expect(t.experimentId == "exp-1")
        #expect(t.name == "Blue icon")
        #expect(t.appIconName == "AppIcon-Blue")
    }

    @Test func `treatment offers siblings, localizations, update and delete`() {
        let t = MockRepositoryFactory.makeExperimentTreatment(id: "trt-1", experimentId: "exp-1")
        #expect(t.affordances["listSiblings"] == "asc experiment-treatments list --experiment-id exp-1")
        #expect(t.affordances["listLocalizations"] == "asc experiment-treatment-localizations list --treatment-id trt-1")
        #expect(t.affordances["createLocalization"] == "asc experiment-treatment-localizations create --locale <locale> --treatment-id trt-1")
        #expect(t.affordances["update"] == "asc experiment-treatments update --treatment-id trt-1")
        #expect(t.affordances["delete"] == "asc experiment-treatments delete --treatment-id trt-1")
    }

    @Test func `treatment apiLinks resolve to REST paths`() {
        let t = MockRepositoryFactory.makeExperimentTreatment(id: "trt-1", experimentId: "exp-1")
        #expect(t.apiLinks["listSiblings"]?.href == "/api/v1/experiments/exp-1/experiment-treatments")
        #expect(t.apiLinks["listLocalizations"]?.href == "/api/v1/experiment-treatments/trt-1/experiment-treatment-localizations")
        #expect(t.apiLinks["update"]?.href == "/api/v1/experiment-treatments/trt-1")
        #expect(t.apiLinks["delete"]?.method == "DELETE")
    }

    @Test func `treatment omits nil appIconName and promotedDate from JSON`() throws {
        let t = MockRepositoryFactory.makeExperimentTreatment(id: "trt-1", experimentId: "exp-1")
        let json = String(decoding: try JSONEncoder().encode(t), as: UTF8.self)
        #expect(!json.contains("appIconName"))
        #expect(!json.contains("promotedDate"))
    }

    @Test func `treatment table row shows name and icon`() {
        let t = MockRepositoryFactory.makeExperimentTreatment(id: "trt-1", experimentId: "exp-1", name: "Blue icon", appIconName: "AppIcon-Blue")
        #expect(ExperimentTreatment.tableHeaders == ["ID", "Name", "App Icon", "Promoted"])
        #expect(t.tableRow == ["trt-1", "Blue icon", "AppIcon-Blue", "-"])
    }
}
