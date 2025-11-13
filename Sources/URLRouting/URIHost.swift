/// Parses a request's host per RFC 3986 section 3.2.2.
///
/// Used to require a particular host at a particular endpoint.
///
/// Example:
/// ```swift
/// Route(.case(SiteRoute.api)) {
///   URIHost("api.example.com")
///   ...
/// }
/// ```
public struct URIHost: ParserPrinter, Sendable {
  @usableFromInline
  let name: String

  /// A parser of custom hosts.
  public static func custom(_ host: String) -> Self {
    Self(host)
  }

  /// Initializes a host parser with a host name.
  ///
  /// - Parameter name: A host name (DNS name, IPv4, or IPv6)
  @inlinable
  public init(_ name: String) {
    self.name = name
  }

  @inlinable
  public func parse(_ input: inout URIRequestData) throws {
    guard let host = input.host else { throw RoutingError() }
    try self.name.parse(host)
    input.host = nil
  }

  @inlinable
  public func print(_ output: (), into input: inout URIRequestData) {
    input.host = self.name
  }
}
