/// A domain model that knows how to present itself in tabular form.
///
/// Both CLI (table/markdown) and REST (when rendering non-JSON formats)
/// use these properties. The model owns its presentation metadata —
/// no caller needs to supply headers or row mappers.
public protocol Presentable {
    /// Column headers for table/markdown output.
    static var tableHeaders: [String] { get }
    /// Row values for table/markdown output — same order as `tableHeaders`.
    var tableRow: [String] { get }
}
