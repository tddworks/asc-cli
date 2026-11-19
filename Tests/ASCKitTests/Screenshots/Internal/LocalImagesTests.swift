import Foundation
import Testing
@testable import ASCKit

@Suite
struct LocalImagesTests {
    private func images(_ files: [String: Data]) -> LocalImages {
        LocalImages(workingDirectory: "/w", contents: { files[$0] })
    }

    @Test func `should inline an image beside the working directory as a data URL`() {
        let html = images(["/w/shot.png": Data([1, 2, 3])]).inline(into: #"<img src="shot.png">"#)

        #expect(html == #"<img src="data:image/png;base64,AQID">"#)
    }

    @Test func `should look in .asc/app-shots when the image is not beside the working directory`() {
        let html = images(["/w/.asc/app-shots/bg.jpg": Data([1, 2, 3])]).inline(into: #"<img src="bg.jpg">"#)

        #expect(html == #"<img src="data:image/jpeg;base64,AQID">"#)
    }

    @Test func `should inline an image given by absolute path`() {
        let html = images(["/abs/badge.gif": Data([1, 2, 3])]).inline(into: #"<img src="/abs/badge.gif">"#)

        #expect(html == #"<img src="data:image/gif;base64,AQID">"#)
    }

    @Test func `should read the file behind a web server file URL`() {
        let html = images(["/w/shots/a.webp": Data([1, 2, 3])])
            .inline(into: #"<img src="http://localhost:8080/api/files/read?path=shots/a.webp">"#)

        #expect(html == #"<img src="data:image/webp;base64,AQID">"#)
    }

    @Test func `should leave remote images and data URLs as they are`() {
        let html = #"<img src="https://cdn.example.com/a.png"><img src="data:image/png;base64,AA.png">"#

        #expect(images([:]).inline(into: html) == html)
    }

    @Test func `should leave an image it cannot find as it is`() {
        let html = #"<img src="missing.png">"#

        #expect(images([:]).inline(into: html) == html)
    }

    @Test func `should inline every local image on the page`() {
        let html = images(["/w/a.png": Data([1]), "/w/b.png": Data([2])])
            .inline(into: #"<img src="a.png"><img src="b.png">"#)

        #expect(html == #"<img src="data:image/png;base64,AQ=="><img src="data:image/png;base64,Ag==">"#)
    }
}
