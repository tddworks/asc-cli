import Foundation
import Testing
@testable import Domain

@Suite
struct ImageAssetTests {

    @Test
    func `url maxSize substitutes w h and f placeholders`() {
        let asset = ImageAsset(
            templateUrl: "https://cdn.example.com/abc/{w}x{h}bb.{f}",
            width: 1024,
            height: 1024
        )
        #expect(asset.url(maxSize: 120)?.absoluteString == "https://cdn.example.com/abc/120x120bb.png")
    }

    @Test
    func `url maxSize allows jpg format`() {
        let asset = ImageAsset(
            templateUrl: "https://cdn.example.com/abc/{w}x{h}bb.{f}",
            width: 1024,
            height: 1024
        )
        #expect(asset.url(maxSize: 64, format: "jpg")?.absoluteString == "https://cdn.example.com/abc/64x64bb.jpg")
    }
}