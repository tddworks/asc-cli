/// Turns an optional domain enum into the one-element SDK filter array a query parameter takes,
/// or `nil` when there is no value (or the SDK has no matching case).
///
/// The SDK type comes from the parameter being filled. Spelled as a generic function because
/// Swift 6.2 can't infer `.init(rawValue:)` through `value.flatMap { .init(…) }.map { [$0] }`.
func sdkFilter<SDKValue: RawRepresentable, DomainValue: RawRepresentable>(
    _ value: DomainValue?
) -> [SDKValue]? where SDKValue.RawValue == String, DomainValue.RawValue == String {
    value.flatMap { SDKValue(rawValue: $0.rawValue) }.map { [$0] }
}
