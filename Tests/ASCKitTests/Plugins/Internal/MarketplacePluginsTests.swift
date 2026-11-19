import Foundation
import Mockable
import Testing
@testable import ASCKit

@Suite
struct MarketplacePluginsTests {
    private let ascPro = InstalledPlugin(
        slug: "ASCPro", name: "ASC Pro", uiScripts: ["ui/pro.js"],
        version: "1.2.0", description: "Pro tools", author: "tddworks",
        repositoryURL: "https://github.com/tddworks/asc-pro", categories: ["pro"]
    )

    private func market(_ plugins: [Plugin]) -> MockPluginSource {
        let source = MockPluginSource()
        given(source).fetchPlugins().willReturn(plugins)
        return source
    }

    private func folder(installed: [InstalledPlugin] = [], bundles: [PluginBundle] = []) -> MockPluginsFolder {
        let folder = MockPluginsFolder()
        given(folder).installed().willReturn(installed)
        given(folder).bundles().willReturn(bundles)
        given(folder).remove(slug: .any).willReturn(())
        given(folder).unpack(.any, named: .any).willReturn(true)
        return folder
    }

    private func repository(
        folder: MockPluginsFolder, market: [Plugin] = [], downloads: MockPluginDownloads = MockPluginDownloads()
    ) -> MarketplacePlugins {
        MarketplacePlugins(sources: [self.market(market)], folder: folder, downloads: downloads)
    }

    // MARK: - installed

    @Test func `should list each installed plugin with the details from its manifest`() async throws {
        let plugins = try await repository(folder: folder(installed: [ascPro])).listInstalled()

        #expect(plugins == [Plugin(
            id: "ASCPro", name: "ASC Pro", version: "1.2.0", description: "Pro tools", author: "tddworks",
            repositoryURL: "https://github.com/tddworks/asc-pro", categories: ["pro"],
            isInstalled: true, slug: "ASCPro", uiScripts: ["ui/pro.js"]
        )])
    }

    @Test func `should list an installed plugin without a manifest as version 1.0`() async throws {
        let bare = InstalledPlugin(slug: "Bare", name: "Bare", uiScripts: [], version: nil, description: nil, author: nil, repositoryURL: nil, categories: nil)

        let plugins = try await repository(folder: folder(installed: [bare])).listInstalled()

        #expect(plugins == [Plugin(id: "Bare", name: "Bare", version: "1.0", isInstalled: true, slug: "Bare")])
    }

    // MARK: - marketplace

    @Test func `should mark a marketplace plugin installed when its id is an installed plugin's name as an id`() async throws {
        let plugins = try await repository(
            folder: folder(installed: [ascPro]),
            market: [
                Plugin(id: "asc-pro", name: "ASC Pro", version: "1.3.0", downloadURL: "https://example.com/pro.zip"),
                Plugin(id: "hello", name: "Hello", version: "0.1.0"),
            ]
        ).listAvailable()

        #expect(plugins.map(\.isInstalled) == [true, false])
    }

    @Test func `should find marketplace plugins by name, description or category, ignoring case`() async throws {
        let plugins = try await repository(
            folder: folder(),
            market: [
                Plugin(id: "a", name: "Screenshot Studio", version: "1"),
                Plugin(id: "b", name: "B", version: "1", description: "Bulk SCREENSHOT upload"),
                Plugin(id: "c", name: "C", version: "1", categories: ["Screenshots"]),
                Plugin(id: "d", name: "D", version: "1", description: "Reviews"),
            ]
        ).searchAvailable(query: "screenshot")

        #expect(plugins.map(\.id) == ["a", "b", "c"])
    }

    @Test func `should list installed plugins whose marketplace version differs`() async throws {
        let updates = try await repository(
            folder: folder(installed: [ascPro]),
            market: [Plugin(id: "asc-pro", name: "ASC Pro", version: "1.3.0", repositoryURL: "https://github.com/tddworks/asc-pro", downloadURL: "https://example.com/pro.zip")]
        ).listOutdated()

        #expect(updates == [PluginUpdate(
            name: "ASC Pro", installedVersion: "1.2.0", latestVersion: "1.3.0",
            repositoryURL: "https://github.com/tddworks/asc-pro", downloadURL: "https://example.com/pro.zip"
        )])
    }

    // MARK: - install

    @Test func `should install a marketplace plugin from its download`() async throws {
        let downloads = MockPluginDownloads()
        given(downloads).download(from: .value(URL(string: "https://example.com/hello.zip")!)).willReturn(Data("zip".utf8))
        let folder = folder()

        let plugin = try await repository(
            folder: folder,
            market: [Plugin(id: "hello", name: "Hello", version: "0.1.0", description: "Says hi", downloadURL: "https://example.com/hello.zip")],
            downloads: downloads
        ).install(name: "hello")

        #expect(plugin == Plugin(id: "hello", name: "Hello", version: "0.1.0", description: "Says hi", isInstalled: true, slug: "hello"))
        verify(folder).unpack(.value(Data("zip".utf8)), named: .value("hello")).called(1)
    }

    @Test func `should refuse to install a plugin the marketplace does not list`() async {
        do {
            _ = try await repository(folder: folder()).install(name: "missing")
            Issue.record("expected the plugin not to be found")
        } catch PluginMarketError.pluginNotFound(let name) {
            #expect(name == "missing")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test func `should report a failed install when the download does not unpack`() async {
        let downloads = MockPluginDownloads()
        given(downloads).download(from: .any).willReturn(Data())
        let folder = MockPluginsFolder()
        given(folder).installed().willReturn([])
        given(folder).unpack(.any, named: .any).willReturn(false)

        do {
            _ = try await repository(
                folder: folder,
                market: [Plugin(id: "hello", name: "Hello", version: "0.1.0", downloadURL: "https://example.com/hello.zip")],
                downloads: downloads
            ).install(name: "hello")
            Issue.record("expected the install to fail")
        } catch PluginMarketError.installFailed(let name) {
            #expect(name == "hello")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    // MARK: - uninstall

    @Test func `should uninstall the plugin named by its folder`() async throws {
        let folder = folder(bundles: [PluginBundle(slug: "ASCPro", manifestName: "ASC Pro")])

        try await repository(folder: folder).uninstall(name: "ASCPro")

        verify(folder).remove(slug: .value("ASCPro")).called(1)
    }

    @Test func `should uninstall the plugin whose name, as an id, is the one given`() async throws {
        let folder = folder(bundles: [
            PluginBundle(slug: "Other", manifestName: "Other"),
            PluginBundle(slug: "ASCPro", manifestName: "ASC Pro"),
        ])

        try await repository(folder: folder).uninstall(name: "asc-pro")

        verify(folder).remove(slug: .value("ASCPro")).called(1)
    }

    @Test func `should refuse to uninstall a plugin that is not installed`() async {
        do {
            try await repository(folder: folder(bundles: [PluginBundle(slug: "Other", manifestName: nil)])).uninstall(name: "asc-pro")
            Issue.record("expected the plugin not to be found")
        } catch PluginMarketError.pluginNotFound(let name) {
            #expect(name == "asc-pro")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    // MARK: - update

    @Test func `should update a plugin by reinstalling the marketplace version`() async throws {
        let downloads = MockPluginDownloads()
        given(downloads).download(from: .any).willReturn(Data("zip".utf8))
        let folder = folder(installed: [ascPro], bundles: [PluginBundle(slug: "ASCPro", manifestName: "ASC Pro")])

        let plugin = try await repository(
            folder: folder,
            market: [Plugin(id: "asc-pro", name: "ASC Pro", version: "1.3.0", downloadURL: "https://example.com/pro.zip")],
            downloads: downloads
        ).update(name: "ASC Pro")

        #expect(plugin.version == "1.3.0")
        #expect(plugin.isInstalled == true)
        verify(folder).remove(slug: .value("ASCPro")).called(1)
        verify(folder).unpack(.any, named: .value("asc-pro")).called(1)
    }
}
