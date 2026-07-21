import RFC_3986

// MARK: - RFC 3986 URI Host Extension
//
// `RFC_3986.URI.Host` is the upstream typed host component (rfc-3986 tip);
// this file nests the routing parser inside it. (The former local
// `public enum Host {}` namespace collided with the upstream type.)

extension RFC_3986.URI.Host {
    /// Parser for URI host components
    ///
    /// Parses the host component per RFC 3986 section 3.2.2.
    /// Used to require a particular host at a particular endpoint.
    ///
    /// Example:
    /// ```swift
    /// Route(.case(\.api)) {
    ///   RFC_3986.URI.Host.Parser("api.example.com")
    ///   ...
    /// }
    /// ```
    public struct Parser: Parser_Primitive.Parser.Bidirectional, Sendable {
        public typealias Input = RFC_3986.URI.Request.Data
        public typealias Output = Void
        public typealias Failure = RFC_3986.URI.Routing.Error
        public typealias Body = Never

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
        public func parse(_ input: inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) {
            guard let host = input.host else {
                throw RFC_3986.URI.Routing.Error(
                    component: .host,
                    failure: .missing
                )
            }
            var remaining = host[...]
            do {
                try self.name.parse(&remaining)
            } catch {
                throw RFC_3986.URI.Routing.Error(
                    component: .host,
                    failure: .mismatch(expected: self.name, actual: host)
                )
            }
            input.host = nil
        }

        /// The emission buffer type — `Parser.Bidirectional` pins `Buffer == Input`.
        public typealias Buffer = RFC_3986.URI.Request.Data

        /// Explicit leaf body: both `Parser.Protocol` and `Serializer.Protocol`
        /// supply a `Body == Never` default getter; the explicit override
        /// disambiguates between the two inherited candidates (the Coder.Witness
        /// precedent).
        @inlinable
        public var body: Never {
            borrowing get { return fatalError("leaf router — serialize(_:into:) is implemented directly") }
        }

        @inlinable
        public func serialize(_ output: Void, into input: inout RFC_3986.URI.Request.Data) {
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
