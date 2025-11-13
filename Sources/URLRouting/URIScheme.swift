/// Parses a request's scheme per RFC 3986 section 3.1.
///
/// Used to require a particular scheme at a particular endpoint.
///
/// Example:
/// ```swift
/// Route(.case(SiteRoute.custom)) {
///   URIScheme("custom")  // Only route custom:// requests
///   ...
/// }
/// ```
public struct URIScheme: ParserPrinter, Sendable {
  @usableFromInline
  let name: String

  /// A parser of the `http` scheme.
  public static let http = Self("http")

  /// A parser of the `https` scheme.
  public static let https = Self("https")

  /// Initializes a scheme parser with a scheme name.
  ///
  /// - Parameter name: A scheme name per RFC 3986 (ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ))
  @inlinable
  public init(_ name: String) {
    self.name = name
  }

  @inlinable
  public func parse(_ input: inout URIRequestData) throws {
    guard let scheme = input.scheme else { throw RoutingError() }
    try self.name.parse(scheme)
    input.scheme = nil
  }

  @inlinable
  public func print(_ output: (), into input: inout URIRequestData) {
    input.scheme = self.name
  }
}
