import Foundation

/// Defines WHERE things go in each screen type — pure layout, no colors.
///
/// A gallery template contains a `ScreenTemplate` for each screen type
/// (hero, feature, social). Same template works with any palette.
public struct GalleryTemplate: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let screens: [ScreenType: ScreenTemplate]

    public init(
        id: String,
        name: String,
        screens: [ScreenType: ScreenTemplate]
    ) {
        self.id = id
        self.name = name
        self.screens = screens
    }
}
