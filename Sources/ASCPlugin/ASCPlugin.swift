import Foundation
import ArgumentParser
import Hummingbird
import HummingbirdWebSocket

/// Concrete router type — shared between main binary and plugins.
public typealias ASCRouter = Router<BasicWebSocketRequestContext>

/// Plugin protocol for the ASC CLI.
///
/// Drop a `.framework` into `~/.asc/plugins/` — auto-discovered at startup.
///
/// Each plugin exports:
/// ```swift
/// @_cdecl("ascPlugin")
/// public func ascPlugin() -> UnsafeMutableRawPointer {
///     Unmanaged.passRetained(MyPlugin()).toOpaque()
/// }
/// ```
@objc public protocol ASCPluginBase {
    var name: String { get }
    var commands: [Any] { get }
    func configureRoutes(_ router: Any)
}

public typealias ASCPlugin = ASCPluginBase
