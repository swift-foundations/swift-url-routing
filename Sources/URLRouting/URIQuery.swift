/// Parses a request's query using RFC 3986 rules with field parsers.
///
/// Example:
/// ```swift
/// URIQuery {
///   Field("q", .string, default: "")
///   Field("page", default: 1) {
///     Digits()
///   }
///   Field("per_page", default: 20) {
///     Digits()
///   }
/// }
/// ```
public struct URIQuery<FieldParsers: Parser>: Parser
where FieldParsers.Input == URIRequestData.Fields {
  @usableFromInline
  let fieldParsers: FieldParsers

  @inlinable
  public init(@ParserBuilder<URIRequestData.Fields> build: () -> FieldParsers) {
    self.fieldParsers = build()
  }

  @inlinable
  public func parse(_ input: inout URIRequestData) rethrows -> FieldParsers.Output {
    try self.fieldParsers.parse(&input.query)
  }
}

extension URIQuery: ParserPrinter where FieldParsers: ParserPrinter {
  @inlinable
  public func print(_ output: FieldParsers.Output, into input: inout URIRequestData) rethrows {
    try self.fieldParsers.print(output, into: &input.query)
  }
}
