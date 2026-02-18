/// A resource that advertises its available CLI actions.
///
/// CLI equivalent of REST HATEOAS. Conforming types embed ready-to-run
/// commands in responses so agents can navigate without memorising the
/// command tree.
public protocol AffordanceProviding {
    var affordances: [String: String] { get }
}
