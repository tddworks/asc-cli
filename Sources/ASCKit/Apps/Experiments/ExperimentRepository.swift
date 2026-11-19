import Mockable

/// Product Page Optimization tests, treatments and treatment localizations.
@Mockable
public protocol ExperimentRepository: Sendable {
    // Experiments (app-scoped)
    func listExperiments(appId: String, state: AppStoreVersionExperimentState?, limit: Int?) async throws -> PaginatedResponse<AppStoreVersionExperiment>
    func getExperiment(experimentId: String) async throws -> AppStoreVersionExperiment
    func createExperiment(appId: String, name: String, platform: AppStorePlatform, trafficProportion: Int) async throws -> AppStoreVersionExperiment
    func updateExperiment(experimentId: String, name: String?, trafficProportion: Int?, isStarted: Bool?) async throws -> AppStoreVersionExperiment
    func deleteExperiment(experimentId: String) async throws

    // Treatments
    func listTreatments(experimentId: String, limit: Int?) async throws -> PaginatedResponse<ExperimentTreatment>
    func createTreatment(experimentId: String, name: String, appIconName: String?) async throws -> ExperimentTreatment
    func updateTreatment(treatmentId: String, name: String?, appIconName: String?) async throws -> ExperimentTreatment
    func deleteTreatment(treatmentId: String) async throws

    // Treatment localizations
    func listTreatmentLocalizations(treatmentId: String, limit: Int?) async throws -> [ExperimentTreatmentLocalization]
    func createTreatmentLocalization(treatmentId: String, locale: String) async throws -> ExperimentTreatmentLocalization
    func deleteTreatmentLocalization(localizationId: String) async throws
}
