import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppInfoLocalizationsUpdateTests {

    @Test func `execute passes localizationId name and subtitle to repository`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo)
            .updateLocalization(id: .value("loc-1"), name: .value("New Name"), subtitle: .value("New Sub"), privacyPolicyUrl: .value(nil))
            .willReturn(AppInfoLocalization(id: "loc-1", appInfoId: "info-1", locale: "en-US", name: "New Name", subtitle: "New Sub"))

        let cmd = try AppInfoLocalizationsUpdate.parse([
            "--localization-id", "loc-1",
            "--name", "New Name",
            "--subtitle", "New Sub",
        ])
        _ = try await cmd.execute(repo: mockRepo)
    }

    @Test func `execute json output includes affordances`() async throws {
        let mockRepo = MockAppInfoRepository()
        given(mockRepo)
            .updateLocalization(id: .any, name: .any, subtitle: .any, privacyPolicyUrl: .any)
            .willReturn(AppInfoLocalization(id: "loc-1", appInfoId: "info-1", locale: "en-US", name: "My App"))

        let cmd = try AppInfoLocalizationsUpdate.parse(["--localization-id", "loc-1", "--name", "My App", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"updateLocalization\""))
        #expect(output.contains("\"listLocalizations\""))
    }
}
