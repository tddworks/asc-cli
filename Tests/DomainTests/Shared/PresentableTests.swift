import Foundation
import Testing
@testable import Domain

@Suite
struct PresentableTests {

    // MARK: - App

    @Test func `app table headers include ID, Name, Bundle ID, SKU`() {
        #expect(App.tableHeaders == ["ID", "Name", "Bundle ID", "SKU"])
    }

    @Test func `app table row uses displayName and nil-coalesces sku`() {
        let app = MockRepositoryFactory.makeApp(id: "123", name: "MyApp", bundleId: "com.test", sku: nil)
        #expect(app.tableRow == ["123", "MyApp", "com.test", "-"])
    }

    @Test func `app table row includes sku when present`() {
        let app = MockRepositoryFactory.makeApp(id: "123", name: "MyApp", bundleId: "com.test", sku: "SKU1")
        #expect(app.tableRow == ["123", "MyApp", "com.test", "SKU1"])
    }

    // MARK: - Build

    @Test func `build table headers include all columns`() {
        #expect(Build.tableHeaders == ["ID", "Version", "Build Number", "Platform", "State", "Expired"])
    }

    @Test func `build table row nil-coalesces optional fields`() {
        let build = MockRepositoryFactory.makeBuild(id: "b1", version: "1.0", expired: false, processingState: .valid, buildNumber: nil, platform: nil)
        #expect(build.tableRow == ["b1", "1.0", "-", "-", "VALID", "No"])
    }

    @Test func `build table row shows Yes for expired`() {
        let build = MockRepositoryFactory.makeBuild(id: "b2", version: "2.0", expired: true, processingState: .processing, buildNumber: "42", platform: .iOS)
        #expect(build.tableRow == ["b2", "2.0", "42", "IOS", "PROCESSING", "Yes"])
    }

    // MARK: - Certificate

    @Test func `certificate table headers include ID, Name, Type, Expired`() {
        #expect(Certificate.tableHeaders == ["ID", "Name", "Type", "Expired"])
    }

    @Test func `certificate table row shows expired status`() {
        let cert = MockRepositoryFactory.makeCertificate(id: "c1", name: "Dev Cert", certificateType: .development, expirationDate: Date.distantPast)
        #expect(cert.tableRow == ["c1", "Dev Cert", "DEVELOPMENT", "Yes"])
    }

    @Test func `certificate table row shows not expired`() {
        let cert = MockRepositoryFactory.makeCertificate(id: "c2", name: "Dist Cert", certificateType: .distribution, expirationDate: Date.distantFuture)
        #expect(cert.tableRow == ["c2", "Dist Cert", "DISTRIBUTION", "No"])
    }

    // MARK: - Device

    @Test func `device table headers include ID, Name, UDID, Class, Status`() {
        #expect(Device.tableHeaders == ["ID", "Name", "UDID", "Class", "Status"])
    }

    @Test func `device table row maps all fields`() {
        let device = MockRepositoryFactory.makeDevice(id: "d1", name: "iPhone", udid: "UDID-1", deviceClass: .iPhone, status: .enabled)
        #expect(device.tableRow == ["d1", "iPhone", "UDID-1", "IPHONE", "ENABLED"])
    }

    // MARK: - Territory

    @Test func `territory table headers include ID, Currency`() {
        #expect(Territory.tableHeaders == ["ID", "Currency"])
    }

    @Test func `territory table row nil-coalesces currency`() {
        let territory = MockRepositoryFactory.makeTerritory(id: "USA", currency: nil)
        #expect(territory.tableRow == ["USA", "—"])
    }

    @Test func `territory table row includes currency when present`() {
        let territory = MockRepositoryFactory.makeTerritory(id: "USA", currency: "USD")
        #expect(territory.tableRow == ["USA", "USD"])
    }

    // MARK: - ScreenshotTemplate

    @Test func `screenshot template table headers`() {
        #expect(ScreenshotTemplate.tableHeaders == ["ID", "Name", "Category", "Devices"])
    }

    @Test func `screenshot template table row`() {
        let tmpl = MockRepositoryFactory.makeScreenshotTemplate(id: "hero", name: "Hero", category: .bold, deviceCount: 2)
        #expect(tmpl.tableRow == ["hero", "Hero", "bold", "2"])
    }

    // MARK: - ScreenTheme

    @Test func `screen theme table headers`() {
        #expect(ScreenTheme.tableHeaders == ["ID", "Name", "Icon", "Description"])
    }

    @Test func `screen theme table row`() {
        let theme = ScreenTheme(
            id: "neon", name: "Neon", icon: "⚡", description: "Vibrant neon glow",
            accent: "#FF00FF", previewGradient: "linear-gradient(#000,#F0F)",
            aiHints: ThemeAIHints(style: "", background: "", floatingElements: [], colorPalette: "", textStyle: "")
        )
        #expect(theme.tableRow == ["neon", "Neon", "⚡", "Vibrant neon glow"])
    }
}
