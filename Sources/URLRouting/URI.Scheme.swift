import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Scheme Extension

extension RFC_3986.URI {
    /// Scheme component of a URI (RFC 3986 section 3.1)
    ///
    /// The scheme identifies the protocol or namespace.
    public enum Scheme {}
}

extension RFC_3986.URI.Scheme {
    /// Parser for URI scheme components
    ///
    /// Parses the scheme component per RFC 3986 section 3.1.
    /// Used to require a particular scheme at a particular endpoint.
    ///
    /// Example:
    /// ```swift
    /// Route(.case(SiteRoute.custom)) {
    ///   RFC_3986.URI.Scheme.Parser("custom")  // Only route custom:// requests
    ///   ...
    /// }
    /// ```
    public struct Parser: ParserPrinter, Sendable {
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
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws {
            guard let scheme = input.scheme else {
                throw RFC_3986.URI.Routing.Error(
                    component: .scheme,
                    failure: .missing
                )
            }
            do {
                try self.name.parse(scheme)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .scheme,
                    failure: .mismatch(expected: self.name, actual: scheme)
                )
            }
            input.scheme = nil
        }

        @inlinable
        public func print(_ output: (), into input: inout RFC_3986.URI.Request.Data) {
            input.scheme = self.name
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Scheme.Parser`
///
/// For cleaner code, you can use `URIScheme` instead of the fully qualified name:
/// ```swift
/// URIScheme("https")  // equivalent to RFC_3986.URI.Scheme.Parser("https")
/// ```
public typealias URIScheme = RFC_3986.URI.Scheme.Parser
