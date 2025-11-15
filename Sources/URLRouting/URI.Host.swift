import Parsing
import RFC_3986

// MARK: - RFC 3986 URI Host Extension

extension RFC_3986.URI {
    /// Host component of a URI (RFC 3986 section 3.2.2)
    ///
    /// The host identifies the server or resource location.
    public enum Host {}
}

extension RFC_3986.URI.Host {
    /// Parser for URI host components
    ///
    /// Parses the host component per RFC 3986 section 3.2.2.
    /// Used to require a particular host at a particular endpoint.
    ///
    /// Example:
    /// ```swift
    /// Route(.case(SiteRoute.api)) {
    ///   RFC_3986.URI.Host.Parser("api.example.com")
    ///   ...
    /// }
    /// ```
    public struct Parser: ParserPrinter, Sendable {
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
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws {
            guard let host = input.host else {
                throw RFC_3986.URI.Routing.Error(
                    component: .host,
                    failure: .missing
                )
            }
            do {
                try self.name.parse(host)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .host,
                    failure: .mismatch(expected: self.name, actual: host)
                )
            }
            input.host = nil
        }

        @inlinable
        public func print(_ output: (), into input: inout RFC_3986.URI.Request.Data) {
            input.host = self.name
        }
    }
}

// MARK: - Convenience Type Alias

/// Convenience type alias for `RFC_3986.URI.Host.Parser`
///
/// For cleaner code, you can use `URIHost` instead of the fully qualified name:
/// ```swift
/// URIHost("api.example.com")  // equivalent to RFC_3986.URI.Host.Parser("api.example.com")
/// ```
public typealias URIHost = RFC_3986.URI.Host.Parser
