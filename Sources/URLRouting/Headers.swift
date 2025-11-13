/// Parses a request's headers using field parsers.
public struct Headers<FieldParsers: Parser>: Parser
where FieldParsers.Input == URIRequestData.Fields {
  @usableFromInline
  let fieldParsers: FieldParsers

  @inlinable
  public init(@ParserBuilder<URIRequestData.Fields> build: () -> FieldParsers) {
    self.fieldParsers = build()
  }

  @inlinable
  public func parse(_ input: inout URIRequestData) rethrows -> FieldParsers.Output {
    try self.fieldParsers.parse(&input.headers)
  }
}

extension Headers: ParserPrinter where FieldParsers: ParserPrinter {
  @inlinable
  public func print(_ output: FieldParsers.Output, into input: inout URIRequestData) rethrows {
    try self.fieldParsers.print(output, into: &input.headers)
  }
}
