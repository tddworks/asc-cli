import Foundation
import Testing
@testable import Domain

@Suite
struct AppShotsConfigTests {

    @Test func `config stores gemini api key`() {
        let config = AppShotsConfig(geminiApiKey: "test-key-123")
        #expect(config.geminiApiKey == "test-key-123")
    }

    @Test func `config roundtrips through JSON`() throws {
        let config = AppShotsConfig(geminiApiKey: "AIzaSyTest1234567890")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AppShotsConfig.self, from: data)
        #expect(decoded == config)
        #expect(decoded.geminiApiKey == "AIzaSyTest1234567890")
    }

    @Test func `config equality holds`() {
        let a = AppShotsConfig(geminiApiKey: "key-abc")
        let b = AppShotsConfig(geminiApiKey: "key-abc")
        let c = AppShotsConfig(geminiApiKey: "key-xyz")
        #expect(a == b)
        #expect(a != c)
    }
}
