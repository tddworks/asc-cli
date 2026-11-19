import Foundation
import Mockable

@Mockable
public protocol ProjectConfigStorage: Sendable {
    func save(_ config: ProjectConfig) throws
    func load() throws -> ProjectConfig?
    func delete() throws
}
