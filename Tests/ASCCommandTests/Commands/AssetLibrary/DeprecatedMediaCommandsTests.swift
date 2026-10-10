import Testing
@testable import ASCCommand

@Suite
struct DeprecatedMediaCommandsTests {

    @Test func `should tell users of the set-based media commands that Apple deprecated them in favour of the asset library`() {
        #expect([
            ScreenshotSetsCommand.configuration.abstract,
            ScreenshotsCommand.configuration.abstract,
            AppPreviewSetsCommand.configuration.abstract,
            AppPreviewsCommand.configuration.abstract,
        ] == [
            "Manage App Store screenshot sets (deprecated by Apple — use asset-library)",
            "Manage App Store screenshots (deprecated by Apple — use asset-library)",
            "Manage App Store app preview sets (deprecated by Apple — use asset-library)",
            "Manage App Store app preview videos (deprecated by Apple — use asset-library)",
        ])
    }
}
