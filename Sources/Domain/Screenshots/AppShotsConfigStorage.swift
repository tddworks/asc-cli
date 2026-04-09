import Foundation
import Mockable

@Mockable
public protocol AppShotsConfigStorage: Sendable {
    func save(_ config: AppShotsConfig) throws
    func load() throws -> AppShotsConfig?
    func delete() throws
}
