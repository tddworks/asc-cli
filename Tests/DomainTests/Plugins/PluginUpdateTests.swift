import Testing
@testable import Domain

@Suite
struct PluginUpdateTests {

    @Test func `update entry is identified by plugin name`() {
        let update = PluginUpdate(
            name: "Hello.plugin",
            installedVersion: "1.0.0",
            latestVersion: "1.2.0"
        )
        #expect(update.id == "Hello.plugin")
    }

    @Test func `update affordance points at the apply command`() {
        let update = PluginUpdate(
            name: "Hello.plugin",
            installedVersion: "1.0.0",
            latestVersion: "1.2.0"
        )
        #expect(update.affordances["update"] == "asc plugins update --name Hello.plugin")
    }

    @Test func `update affordances include viewRepository when URL is present`() {
        let update = PluginUpdate(
            name: "Hello.plugin",
            installedVersion: "1.0.0",
            latestVersion: "1.2.0",
            repositoryURL: "https://github.com/me/Hello"
        )
        #expect(update.affordances["viewRepository"] == "https://github.com/me/Hello")
    }

    @Test func `update affordances omit viewRepository when URL is absent`() {
        let update = PluginUpdate(
            name: "Hello.plugin",
            installedVersion: "1.0.0",
            latestVersion: "1.2.0"
        )
        #expect(update.affordances["viewRepository"] == nil)
    }

    @Test func `installed plugin gains checkUpdate affordance`() {
        let installed = Plugin(id: "Hello.plugin", name: "Hello", version: "1.0", isInstalled: true)
        #expect(installed.affordances["checkUpdate"] == "asc plugins updates")
    }

    @Test func `non-installed marketplace plugin omits checkUpdate affordance`() {
        let market = Plugin(id: "Hello.plugin", name: "Hello", version: "1.0", isInstalled: false)
        #expect(market.affordances["checkUpdate"] == nil)
    }
}
