import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct AppShotsConfigCommandTests {

    @Test func `config set saves gemini api key and returns masked confirmation`() async throws {
        let mockStorage = MockAppShotsConfigStorage()
        given(mockStorage).save(.any).willReturn()
        given(mockStorage).load().willReturn(nil)

        var cmd = try AppShotsConfig.parse(["--gemini-api-key", "AIzaSyBUwwho8MWw9gsPDAuIp"])
        let output = try await cmd.execute(storage: mockStorage)
        #expect(output.contains("AIzaSyBU"))
        #expect(output.contains("saved to"))
    }

    @Test func `config shows file key when no flags given`() async throws {
        let mockStorage = MockAppShotsConfigStorage()
        given(mockStorage).load().willReturn(ASCKit.AppShotsConfig(geminiApiKey: "AIzaSyBUwwho8MWw9gsPDAuIp"))

        var cmd = try AppShotsConfig.parse([])
        let output = try await cmd.execute(storage: mockStorage)
        #expect(output.contains("source: file"))
        #expect(output.contains("AIzaSyBU"))
    }

    @Test func `config shows no key configured when empty`() async throws {
        let mockStorage = MockAppShotsConfigStorage()
        given(mockStorage).load().willReturn(nil)

        var cmd = try AppShotsConfig.parse([])
        let output = try await cmd.execute(storage: mockStorage)
        #expect(output.contains("No Gemini API key configured"))
    }

    @Test func `config remove deletes stored key`() async throws {
        let mockStorage = MockAppShotsConfigStorage()
        given(mockStorage).delete().willReturn()

        var cmd = try AppShotsConfig.parse(["--remove"])
        let output = try await cmd.execute(storage: mockStorage)
        #expect(output.contains("removed"))
    }
}

@Suite
struct AppShotsGenerateKeyResolutionTests {

    @Test func `resolveApiKey prefers explicit flag`() throws {
        let mockStorage = MockAppShotsConfigStorage()
        let key = try resolveGeminiApiKey("flag-key", configStorage: mockStorage)
        #expect(key == "flag-key")
    }

    @Test func `resolveApiKey falls back to config file`() throws {
        let mockStorage = MockAppShotsConfigStorage()
        given(mockStorage).load().willReturn(ASCKit.AppShotsConfig(geminiApiKey: "stored-key"))
        let key = try resolveGeminiApiKey(nil, configStorage: mockStorage)
        #expect(key == "stored-key")
    }

    @Test func `resolveApiKey throws when no key available`() throws {
        let mockStorage = MockAppShotsConfigStorage()
        given(mockStorage).load().willReturn(nil)
        #expect(throws: (any Error).self) {
            try resolveGeminiApiKey(nil, configStorage: mockStorage)
        }
    }
}
