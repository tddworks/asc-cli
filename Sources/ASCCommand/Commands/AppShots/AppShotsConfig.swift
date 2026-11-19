import ArgumentParser
import ASCKit
import Foundation

struct AppShotsConfig: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Configure app-shots settings (Gemini API key)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Gemini API key to save for app-shots generation")
    var geminiApiKey: String?

    @Flag(name: .long, help: "Remove saved app-shots configuration")
    var remove: Bool = false

    func run() async throws {
        let storage = FileAppShotsConfigStorage()
        print(try await execute(storage: storage))
    }

    func execute(storage: any AppShotsConfigStorage) async throws -> String {
        if remove {
            try storage.delete()
            return "app-shots config removed."
        }

        if let key = geminiApiKey, !key.isEmpty {
            let config = ASCKit.AppShotsConfig(geminiApiKey: key)
            try storage.save(config)
            let masked = String(key.prefix(8)) + "..." + String(key.suffix(4))
            return "Gemini API key saved to ~/.asc/app-shots-config.json (\(masked))"
        }

        // No flags — show current config
        if let config = try storage.load() {
            let masked = String(config.geminiApiKey.prefix(8)) + "..." + String(config.geminiApiKey.suffix(4))
            return "Gemini API key: \(masked) (source: file)"
        } else if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            let masked = String(envKey.prefix(8)) + "..." + String(envKey.suffix(4))
            return "Gemini API key: \(masked) (source: environment)"
        } else {
            return "No Gemini API key configured. Run: asc app-shots config --gemini-api-key KEY"
        }
    }
}
