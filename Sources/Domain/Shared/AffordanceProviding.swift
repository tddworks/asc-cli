/// A resource that advertises its available CLI actions.
///
/// CLI equivalent of REST HATEOAS. Conforming types embed ready-to-run
/// commands in responses so agents can navigate without memorising the
/// command tree.
public protocol AffordanceProviding {
    var affordances: [String: String] { get }

    /// Properties passed to `AffordanceRegistry` so plugins can make decisions
    /// (e.g. only show "stream" when `isBooted` is true).
    var registryProperties: [String: String] { get }
}

extension AffordanceProviding {
    public var registryProperties: [String: String] { [:] }
}
