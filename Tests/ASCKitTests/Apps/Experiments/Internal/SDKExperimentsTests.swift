@preconcurrency import AppStoreConnect_Swift_SDK
import Foundation
import Testing
@testable import ASCKit

@Suite
struct SDKExperimentsTests {

    private func sdkExperiment(
        id: String = "exp-1",
        state: AppStoreVersionExperimentV2.Attributes.State = .prepareForSubmission,
        startDate: Date? = nil
    ) -> AppStoreVersionExperimentV2 {
        AppStoreVersionExperimentV2(
            type: .appStoreVersionExperiments, id: id,
            attributes: .init(name: "Icon test", platform: .ios, trafficProportion: 30,
                              state: state, isReviewRequired: true, startDate: startDate),
            relationships: .init(latestControlVersion: .init(data: .init(type: .appStoreVersions, id: "ver-9")))
        )
    }

    // MARK: - Experiments

    @Test func `listExperiments injects appId and maps attributes`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentsV2Response(
            data: [sdkExperiment(id: "exp-1"), sdkExperiment(id: "exp-2")],
            links: .init(this: "")
        ))

        let repo = SDKExperiments(client: stub)
        let result = try await repo.listExperiments(appId: "app-99", state: nil, limit: nil)

        #expect(result.data.count == 2)
        #expect(result.data.allSatisfy { $0.appId == "app-99" })
        #expect(result.data[0].name == "Icon test")
        #expect(result.data[0].platform == .iOS)
        #expect(result.data[0].trafficProportion == 30)
        #expect(result.data[0].state == .prepareForSubmission)
        #expect(result.data[0].isReviewRequired == true)
        #expect(result.data[0].latestControlVersionId == "ver-9")
        #expect(stub.lastPath == "/v1/apps/app-99/appStoreVersionExperimentsV2")
    }

    @Test func `listExperiments passes state filter and limit as query`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentsV2Response(data: [], links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        _ = try await repo.listExperiments(appId: "app-1", state: .approved, limit: 5)

        let query = Dictionary(uniqueKeysWithValues: (stub.lastQuery ?? []).map { ($0.0, $0.1 ?? "") })
        #expect(query["filter[state]"] == "APPROVED")
        #expect(query["limit"] == "5")
    }

    @Test func `listExperiments formats startDate as ISO-8601`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentsV2Response(
            data: [sdkExperiment(state: .approved, startDate: Date(timeIntervalSince1970: 1_756_684_800))],
            links: .init(this: "")
        ))

        let repo = SDKExperiments(client: stub)
        let result = try await repo.listExperiments(appId: "app-1", state: nil, limit: nil)

        #expect(result.data[0].startDate == "2025-09-01T00:00:00Z")
        #expect(result.data[0].isRunning == true)
    }

    @Test func `getExperiment resolves appId from the app relationship`() async throws {
        let stub = StubAPIClient()
        var sdk = sdkExperiment(id: "exp-7")
        sdk.relationships?.app = .init(data: .init(type: .apps, id: "app-3"))
        stub.willReturn(AppStoreVersionExperimentV2Response(data: sdk, links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let exp = try await repo.getExperiment(experimentId: "exp-7")

        #expect(exp.id == "exp-7")
        #expect(exp.appId == "app-3")
        #expect(stub.lastPath == "/v2/appStoreVersionExperiments/exp-7")
    }

    @Test func `createExperiment injects appId and posts to v2`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentV2Response(data: sdkExperiment(id: "exp-new"), links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let exp = try await repo.createExperiment(appId: "app-1", name: "Icon test", platform: .iOS, trafficProportion: 30)

        #expect(exp.id == "exp-new")
        #expect(exp.appId == "app-1")
        #expect(stub.lastPath == "/v2/appStoreVersionExperiments")
    }

    @Test func `updateExperiment patches v2 and keeps appId from relationship`() async throws {
        let stub = StubAPIClient()
        var sdk = sdkExperiment(id: "exp-1", state: .approved, startDate: Date(timeIntervalSince1970: 0))
        sdk.relationships?.app = .init(data: .init(type: .apps, id: "app-1"))
        stub.willReturn(AppStoreVersionExperimentV2Response(data: sdk, links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let exp = try await repo.updateExperiment(experimentId: "exp-1", name: nil, trafficProportion: nil, isStarted: true)

        #expect(exp.appId == "app-1")
        #expect(exp.isRunning == true)
        #expect(stub.lastPath == "/v2/appStoreVersionExperiments/exp-1")
    }

    @Test func `getExperiment asks Apple to include the app relationship`() async throws {
        let stub = StubAPIClient()
        var sdk = sdkExperiment(id: "exp-7")
        sdk.relationships?.app = .init(data: .init(type: .apps, id: "app-3"))
        stub.willReturn(AppStoreVersionExperimentV2Response(data: sdk, links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        _ = try await repo.getExperiment(experimentId: "exp-7")

        // Apple omits `relationships.app` from GET unless `include=app` is requested.
        let query = Dictionary(uniqueKeysWithValues: (stub.lastQuery ?? []).map { ($0.0, $0.1 ?? "") })
        #expect(query["include"] == "app")
    }

    @Test func `updateExperiment re-fetches with the app relationship so appId is never empty`() async throws {
        let stub = StubAPIClient()
        var sdk = sdkExperiment(id: "exp-1")
        sdk.relationships?.app = .init(data: .init(type: .apps, id: "app-1"))
        stub.willReturn(AppStoreVersionExperimentV2Response(data: sdk, links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let exp = try await repo.updateExperiment(experimentId: "exp-1", name: "Renamed", trafficProportion: nil, isStarted: nil)

        // PATCH responses carry no relationships; the adapter follows up with GET ?include=app.
        let query = Dictionary(uniqueKeysWithValues: (stub.lastQuery ?? []).map { ($0.0, $0.1 ?? "") })
        #expect(query["include"] == "app")
        #expect(exp.appId == "app-1")
    }

    @Test func `deleteExperiment issues a void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKExperiments(client: stub)
        try await repo.deleteExperiment(experimentId: "exp-1")
        #expect(stub.voidRequestCalled == true)
    }

    // MARK: - Treatments

    private func sdkTreatment(id: String = "trt-1", promotedDate: Date? = nil) -> AppStoreVersionExperimentTreatment {
        AppStoreVersionExperimentTreatment(
            type: .appStoreVersionExperimentTreatments, id: id,
            attributes: .init(name: "Blue icon", appIconName: "AppIcon-Blue", promotedDate: promotedDate)
        )
    }

    @Test func `listTreatments injects experimentId and maps icon name`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentTreatmentsResponse(
            data: [sdkTreatment(id: "trt-1"), sdkTreatment(id: "trt-2")],
            links: .init(this: "")
        ))

        let repo = SDKExperiments(client: stub)
        let result = try await repo.listTreatments(experimentId: "exp-5", limit: nil)

        #expect(result.data.count == 2)
        #expect(result.data.allSatisfy { $0.experimentId == "exp-5" })
        #expect(result.data[0].name == "Blue icon")
        #expect(result.data[0].appIconName == "AppIcon-Blue")
        #expect(result.data[0].promotedDate == nil)
        #expect(stub.lastPath == "/v2/appStoreVersionExperiments/exp-5/appStoreVersionExperimentTreatments")
    }

    @Test func `createTreatment injects experimentId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentTreatmentResponse(data: sdkTreatment(id: "trt-new"), links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let t = try await repo.createTreatment(experimentId: "exp-1", name: "Blue icon", appIconName: "AppIcon-Blue")

        #expect(t.id == "trt-new")
        #expect(t.experimentId == "exp-1")
        #expect(stub.lastPath == "/v1/appStoreVersionExperimentTreatments")
    }

    @Test func `updateTreatment resolves experimentId from the v2 relationship`() async throws {
        let stub = StubAPIClient()
        var sdk = sdkTreatment(id: "trt-1")
        sdk.relationships = .init(appStoreVersionExperimentV2: .init(data: .init(type: .appStoreVersionExperiments, id: "exp-4")))
        stub.willReturn(AppStoreVersionExperimentTreatmentResponse(data: sdk, links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let t = try await repo.updateTreatment(treatmentId: "trt-1", name: "Red icon", appIconName: nil)

        #expect(t.experimentId == "exp-4")
        #expect(stub.lastPath == "/v1/appStoreVersionExperimentTreatments/trt-1")
    }

    @Test func `updateTreatment re-fetches with the experiment relationship so experimentId is never empty`() async throws {
        let stub = StubAPIClient()
        var sdk = sdkTreatment(id: "trt-1")
        sdk.relationships = .init(appStoreVersionExperimentV2: .init(data: .init(type: .appStoreVersionExperiments, id: "exp-4")))
        stub.willReturn(AppStoreVersionExperimentTreatmentResponse(data: sdk, links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let t = try await repo.updateTreatment(treatmentId: "trt-1", name: "Red icon", appIconName: nil)

        let query = Dictionary(uniqueKeysWithValues: (stub.lastQuery ?? []).map { ($0.0, $0.1 ?? "") })
        #expect(query["include"] == "appStoreVersionExperimentV2")
        #expect(t.experimentId == "exp-4")
    }

    @Test func `deleteTreatment issues a void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKExperiments(client: stub)
        try await repo.deleteTreatment(treatmentId: "trt-1")
        #expect(stub.voidRequestCalled == true)
    }

    // MARK: - Treatment localizations

    private func sdkLocalization(id: String = "loc-1", locale: String = "en-US") -> AppStoreVersionExperimentTreatmentLocalization {
        AppStoreVersionExperimentTreatmentLocalization(
            type: .appStoreVersionExperimentTreatmentLocalizations, id: id,
            attributes: .init(locale: locale)
        )
    }

    @Test func `listTreatmentLocalizations injects treatmentId and maps locale`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentTreatmentLocalizationsResponse(
            data: [sdkLocalization(id: "loc-1", locale: "en-US"), sdkLocalization(id: "loc-2", locale: "de-DE")],
            links: .init(this: "")
        ))

        let repo = SDKExperiments(client: stub)
        let locs = try await repo.listTreatmentLocalizations(treatmentId: "trt-3", limit: nil)

        #expect(locs.count == 2)
        #expect(locs.allSatisfy { $0.treatmentId == "trt-3" })
        #expect(locs[1].locale == "de-DE")
        #expect(stub.lastPath == "/v1/appStoreVersionExperimentTreatments/trt-3/appStoreVersionExperimentTreatmentLocalizations")
    }

    @Test func `createTreatmentLocalization injects treatmentId`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(AppStoreVersionExperimentTreatmentLocalizationResponse(data: sdkLocalization(id: "loc-new", locale: "fr-FR"), links: .init(this: "")))

        let repo = SDKExperiments(client: stub)
        let loc = try await repo.createTreatmentLocalization(treatmentId: "trt-1", locale: "fr-FR")

        #expect(loc.id == "loc-new")
        #expect(loc.treatmentId == "trt-1")
        #expect(loc.locale == "fr-FR")
        #expect(stub.lastPath == "/v1/appStoreVersionExperimentTreatmentLocalizations")
    }

    @Test func `deleteTreatmentLocalization issues a void request`() async throws {
        let stub = StubAPIClient()
        let repo = SDKExperiments(client: stub)
        try await repo.deleteTreatmentLocalization(localizationId: "loc-1")
        #expect(stub.voidRequestCalled == true)
    }
}
