import Foundation
import Testing
@testable import Domain

@Suite
struct AffordanceTests {

    // MARK: - CLI rendering

    @Test func `affordance renders CLI command with single param`() {
        let affordance = Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"])
        #expect(affordance.cliCommand == "asc versions list --app-id 123")
    }

    @Test func `affordance renders CLI command with multiple params sorted by key`() {
        let affordance = Affordance(key: "test", command: "builds", action: "list", params: ["platform": "ios", "app-id": "42"])
        #expect(affordance.cliCommand == "asc builds list --app-id 42 --platform ios")
    }

    @Test func `affordance renders CLI command with no params`() {
        let affordance = Affordance(key: "listAll", command: "apps", action: "list", params: [:])
        #expect(affordance.cliCommand == "asc apps list")
    }

    // MARK: - REST rendering

    @Test func `affordance renders REST link for list action`() {
        let affordance = Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/versions")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for get action`() {
        let affordance = Affordance(key: "getVersion", command: "versions", action: "get", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for create action`() {
        let affordance = Affordance(key: "createVersion", command: "versions", action: "create", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/versions")
        #expect(link.method == "POST")
    }

    @Test func `affordance renders REST link for update action`() {
        let affordance = Affordance(key: "updateVersion", command: "versions", action: "update", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1")
        #expect(link.method == "PATCH")
    }

    @Test func `affordance renders REST link for delete action`() {
        let affordance = Affordance(key: "deleteVersion", command: "versions", action: "delete", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1")
        #expect(link.method == "DELETE")
    }

    @Test func `affordance renders REST link for submit action as POST`() {
        let affordance = Affordance(key: "submitForReview", command: "versions", action: "submit", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1/submit")
        #expect(link.method == "POST")
    }

    @Test func `affordance renders REST link for top-level list with no parent`() {
        let affordance = Affordance(key: "listApps", command: "apps", action: "list", params: [:])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps")
        #expect(link.method == "GET")
    }

    // MARK: - APILink encoding

    @Test func `APILink encodes to JSON with href and method`() throws {
        let link = APILink(href: "/api/v1/apps", method: "GET")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(link)
        let decoded = try JSONDecoder().decode(APILink.self, from: data)
        #expect(decoded.href == "/api/v1/apps")
        #expect(decoded.method == "GET")
    }

    // MARK: - AffordanceMode

    @Test func `AffordanceMode has cli and rest cases`() {
        let cli = AffordanceMode.cli
        let rest = AffordanceMode.rest
        #expect(cli != rest)
    }

    // MARK: - Structured affordances derive CLI affordances

    @Test func `structuredAffordances derive affordances dictionary`() {
        struct TestModel: AffordanceProviding {
            var structuredAffordances: [Affordance] {
                [
                    Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"]),
                    Affordance(key: "listBuilds", command: "builds", action: "list", params: ["app-id": "123"]),
                ]
            }
        }
        let model = TestModel()
        #expect(model.affordances["listVersions"] == "asc versions list --app-id 123")
        #expect(model.affordances["listBuilds"] == "asc builds list --app-id 123")
    }

    @Test func `structuredAffordances derive apiLinks dictionary`() {
        struct TestModel: AffordanceProviding {
            var structuredAffordances: [Affordance] {
                [
                    Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"]),
                ]
            }
        }
        let model = TestModel()
        #expect(model.apiLinks["listVersions"]?.href == "/api/v1/apps/123/versions")
        #expect(model.apiLinks["listVersions"]?.method == "GET")
    }

    // MARK: - App model affordances (migrated to structured)

    @Test func `App affordances render as CLI commands`() {
        let app = App(id: "42", name: "MyApp", bundleId: "com.test")
        #expect(app.affordances["listVersions"] == "asc versions list --app-id 42")
        #expect(app.affordances["listAppInfos"] == "asc app-infos list --app-id 42")
        #expect(app.affordances["listReviews"] == "asc reviews list --app-id 42")
    }

    @Test func `App apiLinks render as REST links`() {
        let app = App(id: "42", name: "MyApp", bundleId: "com.test")
        #expect(app.apiLinks["listVersions"]?.href == "/api/v1/apps/42/versions")
        #expect(app.apiLinks["listVersions"]?.method == "GET")
        #expect(app.apiLinks["listAppInfos"]?.href == "/api/v1/apps/42/app-infos")
        #expect(app.apiLinks["listReviews"]?.href == "/api/v1/apps/42/reviews")
    }

    @Test func `AppStoreVersion affordances render as CLI commands`() {
        let version = AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission)
        #expect(version.affordances["listLocalizations"] == "asc version-localizations list --version-id v-1")
        #expect(version.affordances["listVersions"] == "asc versions list --app-id 42")
        #expect(version.affordances["checkReadiness"] == "asc versions check-readiness --version-id v-1")
        #expect(version.affordances["submitForReview"] == "asc versions submit --version-id v-1")
    }

    @Test func `AppStoreVersion apiLinks render as REST links`() {
        let version = AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission)
        #expect(version.apiLinks["listLocalizations"]?.href == "/api/v1/versions/v-1/localizations")
        #expect(version.apiLinks["listVersions"]?.href == "/api/v1/apps/42/versions")
        #expect(version.apiLinks["checkReadiness"]?.href == "/api/v1/versions/v-1/check-readiness")
        #expect(version.apiLinks["submitForReview"]?.href == "/api/v1/versions/v-1/submit")
    }

    @Test func `AppStoreVersion submit affordance only when editable`() {
        let editable = AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission)
        let live = AppStoreVersion(id: "v-2", appId: "42", versionString: "1.0", platform: .iOS, state: .readyForSale)
        #expect(editable.affordances["submitForReview"] != nil)
        #expect(live.affordances["submitForReview"] == nil)
    }

    // MARK: - APIRoot (HATEOAS entry point)

    @Test func `APIRoot lists all top-level resources as REST links`() {
        let root = APIRoot()
        let links = root.apiLinks
        // Core app management
        #expect(links["apps"]?.href == "/api/v1/apps")
        #expect(links["apps"]?.method == "GET")
        // Code signing
        #expect(links["certificates"]?.href == "/api/v1/certificates")
        #expect(links["bundleIds"]?.href == "/api/v1/bundle-ids")
        #expect(links["devices"]?.href == "/api/v1/devices")
        #expect(links["profiles"]?.href == "/api/v1/profiles")
        // Other top-level resources
        #expect(links["simulators"]?.href == "/api/v1/simulators")
        #expect(links["plugins"]?.href == "/api/v1/plugins")
        #expect(links["territories"]?.href == "/api/v1/territories")
    }

    @Test func `APIRoot CLI affordances list all top-level commands`() {
        let root = APIRoot()
        let cmds = root.affordances
        #expect(cmds["apps"] == "asc apps list")
        #expect(cmds["certificates"] == "asc certificates list")
        #expect(cmds["simulators"] == "asc simulators list")
    }

    @Test func `APIRoot is Codable`() throws {
        let root = APIRoot()
        let data = try JSONEncoder().encode(root)
        let decoded = try JSONDecoder().decode(APIRoot.self, from: data)
        #expect(decoded == root)
    }

    // MARK: - Nested resource paths

    @Test func `affordance renders REST link for version localizations`() {
        let affordance = Affordance(key: "listLocalizations", command: "version-localizations", action: "list", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1/localizations")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for screenshot sets`() {
        let affordance = Affordance(key: "listScreenshotSets", command: "screenshot-sets", action: "list", params: ["localization-id": "loc-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/version-localizations/loc-1/screenshot-sets")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for builds under app`() {
        let affordance = Affordance(key: "listBuilds", command: "builds", action: "list", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/builds")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for reviews under app`() {
        let affordance = Affordance(key: "listReviews", command: "reviews", action: "list", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/reviews")
        #expect(link.method == "GET")
    }

    // MARK: - Expanded route table

    @Test func `testflight groups under app`() {
        let a = Affordance(key: "listGroups", command: "testflight", action: "list", params: ["app-id": "1"])
        #expect(a.restLink.href == "/api/v1/apps/1/testflight")
    }

    @Test func `certificates top-level`() {
        let a = Affordance(key: "listCerts", command: "certificates", action: "list", params: [:])
        #expect(a.restLink.href == "/api/v1/certificates")
    }

    @Test func `bundle-ids top-level`() {
        let a = Affordance(key: "listBundleIds", command: "bundle-ids", action: "list", params: [:])
        #expect(a.restLink.href == "/api/v1/bundle-ids")
    }

    @Test func `devices top-level`() {
        let a = Affordance(key: "listDevices", command: "devices", action: "list", params: [:])
        #expect(a.restLink.href == "/api/v1/devices")
    }

    @Test func `profiles top-level`() {
        let a = Affordance(key: "listProfiles", command: "profiles", action: "list", params: [:])
        #expect(a.restLink.href == "/api/v1/profiles")
    }

    @Test func `simulators top-level`() {
        let a = Affordance(key: "listSims", command: "simulators", action: "list", params: [:])
        #expect(a.restLink.href == "/api/v1/simulators")
    }

    @Test func `plugins top-level`() {
        let a = Affordance(key: "listPlugins", command: "plugins", action: "list", params: [:])
        #expect(a.restLink.href == "/api/v1/plugins")
    }

    @Test func `territories top-level`() {
        let a = Affordance(key: "listTerritories", command: "territories", action: "list", params: [:])
        #expect(a.restLink.href == "/api/v1/territories")
    }

    @Test func `iap under app`() {
        let a = Affordance(key: "listIAP", command: "iap", action: "list", params: ["app-id": "1"])
        #expect(a.restLink.href == "/api/v1/apps/1/iap")
    }

    @Test func `subscription-groups under app`() {
        let a = Affordance(key: "listGroups", command: "subscription-groups", action: "list", params: ["app-id": "1"])
        #expect(a.restLink.href == "/api/v1/apps/1/subscription-groups")
    }

    @Test func `subscriptions under group`() {
        let a = Affordance(key: "listSubs", command: "subscriptions", action: "list", params: ["group-id": "g-1"])
        #expect(a.restLink.href == "/api/v1/subscription-groups/g-1/subscriptions")
    }

    @Test func `iap-localizations under iap`() {
        let a = Affordance(key: "listLocs", command: "iap-localizations", action: "list", params: ["iap-id": "iap-1"])
        #expect(a.restLink.href == "/api/v1/iap/iap-1/localizations")
    }

    @Test func `app-infos under app`() {
        let a = Affordance(key: "listInfos", command: "app-infos", action: "list", params: ["app-id": "1"])
        #expect(a.restLink.href == "/api/v1/apps/1/app-infos")
    }

    @Test func `app-info-localizations under app-info`() {
        let a = Affordance(key: "listLocs", command: "app-info-localizations", action: "list", params: ["app-info-id": "ai-1"])
        #expect(a.restLink.href == "/api/v1/app-infos/ai-1/localizations")
    }

    @Test func `perf-metrics under app`() {
        let a = Affordance(key: "listMetrics", command: "perf-metrics", action: "list", params: ["app-id": "1"])
        #expect(a.restLink.href == "/api/v1/apps/1/perf-metrics")
    }

    @Test func `xcode-cloud products`() {
        let a = Affordance(key: "listProducts", command: "xcode-cloud", action: "list", params: ["app-id": "1"])
        #expect(a.restLink.href == "/api/v1/apps/1/xcode-cloud")
    }

    // MARK: - RESTPathResolver composability

    @Test func `custom route registered at runtime resolves correctly`() {
        RESTPathResolver.registerRoute(
            command: "custom-widgets",
            parentParam: "dashboard-id",
            parentSegment: "dashboards",
            segment: "widgets"
        )
        let a = Affordance(key: "listWidgets", command: "custom-widgets", action: "list", params: ["dashboard-id": "d-1"])
        #expect(a.restLink.href == "/api/v1/dashboards/d-1/widgets")

        // Clean up
        RESTPathResolver.removeRoute(command: "custom-widgets")
    }

    @Test func `get action on custom command resolves to segment matching the command name`() {
        // singularize("custom-widgets") → "custom-widget" → param "custom-widget-id"
        let a = Affordance(key: "getWidget", command: "custom-widgets", action: "get", params: ["custom-widget-id": "w-1"])
        #expect(a.restLink.href == "/api/v1/custom-widgets/w-1")
    }

    @Test func `update action uses command segment when cli flag differs from singularized name`() {
        // `app-info-localizations` uses `--localization-id` (not `--app-info-localization-id`).
        // The resolver should still route `update` to `/api/v1/app-info-localizations/:id`.
        let a = Affordance(
            key: "updateLocalization",
            command: "app-info-localizations",
            action: "update",
            params: ["localization-id": "loc-1"]
        )
        #expect(a.restLink.href == "/api/v1/app-info-localizations/loc-1")
        #expect(a.restLink.method == "PATCH")
    }

    @Test func `delete action uses command segment when cli flag differs from singularized name`() {
        let a = Affordance(
            key: "deleteLocalization",
            command: "app-info-localizations",
            action: "delete",
            params: ["localization-id": "loc-1"]
        )
        #expect(a.restLink.href == "/api/v1/app-info-localizations/loc-1")
        #expect(a.restLink.method == "DELETE")
    }
}