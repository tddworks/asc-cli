import Foundation
@testable import Infrastructure

struct StubShellRunner: ShellRunner {
    let stdout: String?
    let error: Error?

    init(stdout: String = "", error: Error? = nil) {
        self.stdout = error == nil ? stdout : nil
        self.error = error
    }

    func run(command: String, arguments: [String], environment: [String: String]?) async throws -> String {
        if let error {
            throw error
        }
        return stdout ?? ""
    }
}
