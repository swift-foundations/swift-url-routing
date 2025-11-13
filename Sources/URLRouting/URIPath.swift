/// Parses a request's path components using RFC 3986 rules.
///
/// Incrementally consumes path components from the beginning of a URI path.
///
/// Example:
/// ```swift
/// try URIPath {
///   "users"
///   Digits()
/// }
/// .match(uri: "/users/42")
/// // 42
/// ```
public struct URIPath<ComponentParsers: Parser>: Parser
where ComponentParsers.Input == URIRequestData {
  @usableFromInline
  let componentParsers: ComponentParsers

  @inlinable
  public init(@PathBuilder build: () -> ComponentParsers) {
    self.componentParsers = build()
  }

  @inlinable
  public func parse(_ input: inout URIRequestData) rethrows -> ComponentParsers.Output {
    try self.componentParsers.parse(&input)
  }
}

extension URIPath: ParserPrinter where ComponentParsers: ParserPrinter {
  @inlinable
  public func print(_ output: ComponentParsers.Output, into input: inout URIRequestData) rethrows {
    try self.componentParsers.print(output, into: &input)
  }
}
