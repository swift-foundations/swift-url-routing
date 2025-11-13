import Foundation
import Parsing
import RFC_7230

// MARK: - RFC 7230 Body Extension

extension RFC_7230.Body {
  /// Parser for HTTP message body (RFC 7230 section 3.3)
  ///
  /// Parses a request's body using a byte parser.
  ///
  /// Example:
  /// ```swift
  /// struct Comment: Codable {
  ///   var author: String
  ///   var message: String
  /// }
  ///
  /// RFC_7230.Body.Parser(.json(Comment.self))
  /// ```
  public struct Parser<Bytes: Parsing.Parser>: Parsing.Parser where Bytes.Input == Data {
    @usableFromInline
    let bytesParser: Bytes

    @inlinable
    public init(@ParserBuilder<Data> _ bytesParser: () -> Bytes) {
      self.bytesParser = bytesParser()
    }

    /// Initializes a body parser from a byte conversion.
    ///
    /// Useful for parsing a request body in its entirety, for example as a JSON payload.
    ///
    /// - Parameter bytesConversion: A conversion that transforms bytes into some other type.
    @inlinable
    public init<C>(_ bytesConversion: C)
    where Bytes == Parsers.MapConversion<Parsers.ReplaceError<Rest<Data>>, C> {
      self.bytesParser = Rest().replaceError(with: .init()).map(bytesConversion)
    }

    /// Initializes a body parser that parses the body as data in its entirety.
    @inlinable
    public init() where Bytes == Parsers.ReplaceError<Rest<Bytes.Input>> {
      self.bytesParser = Rest().replaceError(with: .init())
    }

    @inlinable
    public func parse(_ input: inout URIRequestData) throws -> Bytes.Output {
      guard var body = input.body
      else { throw RoutingError() }

      let output = try self.bytesParser.parse(&body)
      input.body = body

      return output
    }
  }
}

extension RFC_7230.Body.Parser: ParserPrinter where Bytes: ParserPrinter {
  @inlinable
  public func print(_ output: Bytes.Output, into input: inout URIRequestData) rethrows {
    input.body = try self.bytesParser.print(output)
  }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_7230.Body.Parser`
///
/// For cleaner code, you can use `Body` instead of the fully qualified name:
/// ```swift
/// Body(.json(Comment.self))
/// ```
public typealias Body = RFC_7230.Body.Parser

// MARK: - Parser Extension Compatibility

extension Parser where Input == URIRequestData {
  public typealias Body = RFC_7230.Body.Parser
}
