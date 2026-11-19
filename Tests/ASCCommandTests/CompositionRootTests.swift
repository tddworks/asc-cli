import Foundation
import Testing

/// The fence around each concept's `Internal/`: only the composition root
/// (`ClientProvider.swift`) may name an implementation; every command and
/// route asks it for the concept's public protocol instead.
/// See docs/features/concept-folders/design.md §3.
@Suite
struct CompositionRootTests {
    @Test func `should build every concept's Internal implementation only in the composition root`() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // ASCCommandTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repo root
        let internalTypes = try Self.internalTypeNames(in: root.appendingPathComponent("Sources/ASCKit"))
        let commands = root.appendingPathComponent("Sources/ASCCommand")

        var leaks: [String] = []
        for file in try Self.swiftFiles(in: commands) where file.lastPathComponent != "ClientProvider.swift" {
            let code = try String(contentsOf: file, encoding: .utf8)
                .split(separator: "\n", omittingEmptySubsequences: false)
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
                .joined(separator: "\n")
            let identifiers = Set(code.split { !($0.isLetter || $0.isNumber || $0 == "_") }.map(String.init))
            for name in internalTypes.intersection(identifiers) {
                leaks.append("\(file.path.replacingOccurrences(of: commands.path + "/", with: "")): \(name)")
            }
        }

        #expect(leaks.sorted() == [])
    }

    private static func internalTypeNames(in kit: URL) throws -> Set<String> {
        var names: Set<String> = []
        let declaration = try NSRegularExpression(
            pattern: "^(?:public |open )?(?:final )?(?:struct|class|enum|actor) ([A-Z][A-Za-z0-9_]*)",
            options: .anchorsMatchLines
        )
        for file in try swiftFiles(in: kit) where file.pathComponents.contains("Internal") {
            let code = try String(contentsOf: file, encoding: .utf8)
            for match in declaration.matches(in: code, range: NSRange(code.startIndex..., in: code)) {
                if let range = Range(match.range(at: 1), in: code) { names.insert(String(code[range])) }
            }
        }
        return names
    }

    private static func swiftFiles(in directory: URL) throws -> [URL] {
        let walker = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
        return (walker?.allObjects as? [URL] ?? []).filter { $0.pathExtension == "swift" }
    }
}
