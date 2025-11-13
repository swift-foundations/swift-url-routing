import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Query Extension

extension RFC_3986.URI {
  /// Query component of a URI (RFC 3986 section 3.4)
  ///
  /// The query provides additional parameters for identifying the resource.
  public enum Query {}
}

extension RFC_3986.URI.Query {
  /// Parser for URI query components
  ///
  /// Parses request query using RFC 3986 rules with field parsers.
  ///
  /// Example:
  /// ```swift
  /// RFC_3986.URI.Query.Parser {
  ///   Field("q", .string, default: "")
  ///   Field("page", default: 1) {
  ///     Digits()
  ///   }
  ///   Field("per_page", default: 20) {
  ///     Digits()
  ///   }
  /// }
  /// ```
  public struct Parser<FieldParsers: Parsing.Parser>: Parsing.Parser
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
}

extension RFC_3986.URI.Query.Parser: ParserPrinter where FieldParsers: ParserPrinter {
  @inlinable
  public func print(_ output: FieldParsers.Output, into input: inout URIRequestData) rethrows {
    try self.fieldParsers.print(output, into: &input.query)
  }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Query.Parser`
///
/// For cleaner code, you can use `URIQuery` instead of the fully qualified name:
/// ```swift
/// URIQuery {
///   Field("q", .string)
/// }
/// ```
public typealias URIQuery = RFC_3986.URI.Query.Parser
