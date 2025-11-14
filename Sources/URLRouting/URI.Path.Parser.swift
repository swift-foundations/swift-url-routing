import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Path Extension

extension RFC_3986.URI {
    /// Path component of a URI (RFC 3986 section 3.3)
    ///
    /// The path identifies a resource within the scope of the scheme and authority.
    public enum Path {}
}

extension RFC_3986.URI.Path {
    /// Parser for URI path components
    ///
    /// Parses request path components using RFC 3986 rules.
    /// Incrementally consumes path components from the beginning of a URI path.
    ///
    /// Example:
    /// ```swift
    /// try RFC_3986.URI.Path.Parser {
    ///   "users"
    ///   Digits()
    /// }
    /// .match(uri: "/users/42")
    /// // 42
    /// ```
    public struct Parser<ComponentParsers: Parsing.Parser>: Parsing.Parser
    where ComponentParsers.Input == RFC_3986.URI.Request.Data {
        @usableFromInline
        let componentParsers: ComponentParsers

        @inlinable
        public init(@RFC_3986.URI.Path.Builder build: () -> ComponentParsers) {
            self.componentParsers = build()
        }

        @inlinable
        public init(@RFC_3986.URI.Path.Builder build: () throws -> ComponentParsers) rethrows {
            self.componentParsers = try build()
        }

        @inlinable
        public func parse(_ input: inout RFC_3986.URI.Request.Data) rethrows -> ComponentParsers.Output {
            try self.componentParsers.parse(&input)
        }
    }
}

extension RFC_3986.URI.Path.Parser: ParserPrinter where ComponentParsers: ParserPrinter {
    @inlinable
    public func print(_ output: ComponentParsers.Output, into input: inout RFC_3986.URI.Request.Data) rethrows {
        try self.componentParsers.print(output, into: &input)
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Path.Parser`
///
/// For cleaner code, you can use `URIPath` instead of the fully qualified name:
/// ```swift
/// URIPath {
///   "users"
///   Digits()
/// }
/// ```
public typealias URIPath = RFC_3986.URI.Path.Parser
